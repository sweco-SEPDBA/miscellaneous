<#
.SYNOPSIS
    Grows a SQL Server transaction log file to a target size using optimal VLF sizing.

.DESCRIPTION
    Grows a SQL Server transaction log file to a specified target size using the
    dbatools Expand-DbaDbLogFile function. It applies SQL Server's VLF creation
    rules to determine the correct growth increment for each step, aiming to
    produce VLFs of the preferred size throughout the growth process.

    VLF creation rules (applied per growth event):
      Growth < 1/8 of current log size  ->  1 VLF  (Expand-DbaDbLogFile is called
                                                     once with the final TargetLogSize;
                                                     it handles all steps internally)
      Growth <= 64 MB                   ->  4 VLFs
      64 MB < Growth <= 1 GB            ->  8 VLFs
      Growth > 1 GB                     -> 16 VLFs

    First-call optimisation:
      On the very first call to Expand-DbaDbLogFile (when the multi-VLF tiers apply),
      TargetLogSize is set to IncrementMB (absolute) so that dbatools handles that
      initial block of growth internally in one call.
      Subsequent calls advance one increment step at a time.

    The script automatically determines the optimal growth increment based on the current log size and SQL Server's VLF rules.

.PARAMETER SqlInstance
    The SQL Server instance to connect to (e.g. "SQL01" or "SQL01\INST1").

.PARAMETER Database
    The database whose transaction log will be grown.

.PARAMETER TargetSizeMB
    Desired final size of the transaction log in MB.


.EXAMPLE
    # Grow the log to 10 GB 
    .\Expand-LogFile.ps1 -SqlInstance "SQL01" -Database "MyDB" -TargetSizeMB 10240 

.EXAMPLE
    # Preview the full growth plan without making any changes
    .\Expand-LogFile.ps1 -SqlInstance "SQL01" -Database "MyDB" -TargetSizeMB 10240 -WhatIf -Verbose
#>

#Requires -Modules dbatools

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$SqlInstance,

    [Parameter(Mandatory)]
    [string]$Database,

    [Parameter(Mandatory)]
    [int]$TargetSizeMB

)

# --- Helper: Determine ideal growth increment ---------------------------------
function Get-GrowthIncrement {
    <#
    .SYNOPSIS
        Returns the optimal growth increment (and expected VLF count) to produce
        VLFs of the preferred size, based on SQL Server's VLF rules.
    #>
    param (
        [int]$CurrentSizeMB,
        [int]$PreferredVLFSizeMB
    )

    # Rule 1 - 1-VLF: growth < 1/8 of current log size
    if ($PreferredVLFSizeMB -lt ($CurrentSizeMB / 8)) {
        return [PSCustomObject]@{
            IncrementMB  = $PreferredVLFSizeMB
            ExpectedVLFs = 1
            Rule         = "1-VLF  (growth < 1/8 of current size)"
        }
    }

    # Calculate the increment that places each VLF at exactly PreferredVLFSizeMB
    $inc4  =  4 * $PreferredVLFSizeMB
    $inc8  =  8 * $PreferredVLFSizeMB
    $inc16 = 16 * $PreferredVLFSizeMB

    if ($inc4 -le 64) {
        return [PSCustomObject]@{
            IncrementMB  = $inc4
            ExpectedVLFs = 4
            Rule         = "4-VLF  (growth <= 64 MB)"
        }
    }
    elseif ($inc8 -le 1024) {
        return [PSCustomObject]@{
            IncrementMB  = $inc8
            ExpectedVLFs = 8
            Rule         = "8-VLF  (64 MB < growth <= 1 GB)"
        }
    }
    else {
        return [PSCustomObject]@{
            IncrementMB  = $inc16
            ExpectedVLFs = 16
            Rule         = "16-VLF (growth > 1 GB)"
        }
    }
}

# --- Helper: Re-evaluate actual VLF count for a (possibly capped) increment ---
function Get-ActualVLFCount {
    param (
        [int]$IncrementMB,
        [int]$CurrentSizeMB
    )

    if ($IncrementMB -lt ($CurrentSizeMB / 8)) { return 1  }
    elseif ($IncrementMB -le 64)               { return 4  }
    elseif ($IncrementMB -le 1024)             { return 8  }
    else                                        { return 16 }
}

# --- Main ---------------------------------------------------------------------

Write-Verbose "Connecting to '$SqlInstance', checking current log size for database '$Database'..."

try {
    $logFile = Get-DbaDbFile -SqlInstance $SqlInstance -Database $Database |
               Where-Object { $_.TypeDescription -eq 'LOG' } |
               Select-Object -First 1

    if (-not $logFile) {
        Write-Error "No transaction log file found for database '$Database' on '$SqlInstance'."
        exit 1
    }
}
catch {
    Write-Error "Failed to connect or retrieve log file information: $_"
    exit 1
}

if (-not $logFile.GrowthType -eq 'kb') {
    Write-Error "Transaction log file has growth type persent '$Database' on '$SqlInstance'." 
    exit 1
} else {
    write-host "Transaction log file growth type is in KB, proceeding with calculations." -ForegroundColor Green
}

[int]$PreferredVLFSizeMB = [math]::Ceiling($logFile.Growth / 1024)
$initialSizeMB = [math]::Ceiling($logFile.Size.Megabyte)
$currentSizeMB = $initialSizeMB

Write-Verbose ("Current log size  : {0} MB" -f $currentSizeMB)
Write-Verbose ("Target  log size  : {0} MB" -f $TargetSizeMB)
Write-Verbose ("Preferred VLF size: {0} MB" -f $PreferredVLFSizeMB)

if ($currentSizeMB -ge $TargetSizeMB) {
    Write-Host "Log file is already at or above the target size ($currentSizeMB MB >= $TargetSizeMB MB). No action taken." -ForegroundColor Yellow
    exit 0
}

$stepNumber     = 0
$totalVLFsAdded = 0
$isFirstCall    = $true

while ($currentSizeMB -lt $TargetSizeMB) {

    $stepNumber++
    $remainingMB = $TargetSizeMB - $currentSizeMB
    $growthPlan  = Get-GrowthIncrement -CurrentSizeMB $currentSizeMB -PreferredVLFSizeMB $PreferredVLFSizeMB
    $incrementMB = $growthPlan.IncrementMB

    # -- 1-VLF rule active -----------------------------------------------------
    # Call Expand-DbaDbLogFile once with the final TargetLogSize and let it
    # handle all remaining steps internally. No need for our loop to iterate.
    if ($growthPlan.ExpectedVLFs -eq 1) {

        $vlfEstimate = [math]::Ceiling($remainingMB / $incrementMB)

        Write-Verbose (
            "Step {0,3}: 1-VLF rule - single call to final target.  {1,6} MB -> {2,6} MB  (+{3} MB/step)  |  {4}  |  ~{5} VLF(s)" -f
            $stepNumber, $currentSizeMB, $TargetSizeMB, $incrementMB, $growthPlan.Rule, $vlfEstimate
        )

        if ($PSCmdlet.ShouldProcess(
                "Database '$Database' on '$SqlInstance'",
                "Grow log from $currentSizeMB MB to $TargetSizeMB MB in steps of $incrementMB MB (~$vlfEstimate VLF(s), $($growthPlan.Rule))")) {
            try {
                Expand-DbaDbLogFile `
                    -SqlInstance   $SqlInstance `
                    -Database      $Database `
                    -TargetLogSize $TargetSizeMB `
                    -IncrementSize $incrementMB `
                    -ErrorAction   Stop
            }
            catch {
                Write-Error "Growth failed at step $stepNumber (1-VLF rule, target $TargetSizeMB MB): $_"
                exit 1
            }
        }

        $totalVLFsAdded += $vlfEstimate
        $currentSizeMB   = $TargetSizeMB
        $isFirstCall     = $false
        break   # dbatools handled the rest; we are done
    }

    # -- First call optimisation -----------------------------------------------
    # Set TargetLogSize = IncrementMB (absolute, e.g. 16 x 1024 = 16384 MB).
    # The VLFs in this block will be slightly smaller than preferred because the
    # log starts below that absolute target, but every subsequent call will
    # produce VLFs of exactly PreferredVLFSizeMB.
    # Guard: if the log is already at or past IncrementMB, advance by one
    # increment from the current position instead.
    if ($isFirstCall) {

        $firstCallTarget = $growthPlan.IncrementMB
        if ($firstCallTarget -le $currentSizeMB) {
            $firstCallTarget = $currentSizeMB + $incrementMB
        }
        if ($firstCallTarget -gt $TargetSizeMB) {
            $firstCallTarget = $TargetSizeMB
        }

        $newTargetMB  = $firstCallTarget
        $isFirstCall  = $false

        # Estimate VLFs: count how many full IncrementMB steps dbatools will take
        $growthEvents = [math]::Ceiling(($newTargetMB - $currentSizeMB) / $incrementMB)
        $actualVLFs   = $growthEvents * $growthPlan.ExpectedVLFs

        Write-Verbose (
            "Step {0,3}: First call - {1,6} MB -> {2,6} MB  (+{3} MB/step, {4} steps internally)  |  {5}  |  ~{6} VLF(s)" -f
            $stepNumber, $currentSizeMB, $newTargetMB, $incrementMB, $growthEvents, $growthPlan.Rule, $actualVLFs
        )
    }
    else {
        # -- Subsequent calls: one increment step at a time --------------------
        if ($incrementMB -gt $remainingMB) { $incrementMB = $remainingMB }

        $newTargetMB = $currentSizeMB + $incrementMB
        $actualVLFs  = Get-ActualVLFCount -IncrementMB $incrementMB -CurrentSizeMB $currentSizeMB

        Write-Verbose (
            "Step {0,3}: {1,6} MB -> {2,6} MB  (+{3,6} MB)  |  {4}  |  ~{5} VLF(s)" -f
            $stepNumber, $currentSizeMB, $newTargetMB, $incrementMB, $growthPlan.Rule, $actualVLFs
        )
    }

    if ($PSCmdlet.ShouldProcess(
            "Database '$Database' on '$SqlInstance'",
            "Grow log from $currentSizeMB MB to $newTargetMB MB (+$incrementMB MB/step, ~$actualVLFs VLF(s), $($growthPlan.Rule))")) {
        try {
            Expand-DbaDbLogFile `
                -SqlInstance   $SqlInstance `
                -Database      $Database `
                -TargetLogSize $newTargetMB `
                -IncrementSize $incrementMB `
                -ErrorAction   Stop
        }
        catch {
            Write-Error "Growth failed at step $stepNumber (target $newTargetMB MB): $_"
            exit 1
        }
    }

    $totalVLFsAdded += $actualVLFs
    $currentSizeMB   = $newTargetMB
}

# --- Summary ------------------------------------------------------------------

if ($WhatIfPreference) {
    Write-Host ("`n[WhatIf] Growth plan for '{0}' on '{1}':" -f $Database, $SqlInstance) -ForegroundColor Cyan
    Write-Host ("  From    : {0} MB" -f $initialSizeMB)                                  -ForegroundColor Cyan
    Write-Host ("  To      : {0} MB" -f $TargetSizeMB)                                   -ForegroundColor Cyan
    Write-Host ("  Steps   : {0}"    -f $stepNumber)                                      -ForegroundColor Cyan
    Write-Host ("  ~VLFs   : {0}"    -f $totalVLFsAdded)                                  -ForegroundColor Cyan
}
else {
    Write-Host ("`nTransaction log growth complete for database '{0}'." -f $Database) -ForegroundColor Green
    Write-Host ("  Initial size : {0} MB"  -f $initialSizeMB)                        -ForegroundColor Green
    Write-Host ("  Final size   : {0} MB"  -f $currentSizeMB)                        -ForegroundColor Green
    Write-Host ("  Steps        : {0}"     -f $stepNumber)                            -ForegroundColor Green
    Write-Host ("  VLFs added   : ~{0}"    -f $totalVLFsAdded)                        -ForegroundColor Green
}
