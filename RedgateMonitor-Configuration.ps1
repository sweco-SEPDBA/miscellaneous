
<# 
.SYNOPSIS
  Grants the minimal rights required for Redgate SQL Monitor on a Windows Server.

.PARAMETER MonitoringAccount
  The account used by Redgate Monitor to connect (DOMAIN\User or .\User).

.PARAMETER RestartWinRM
  Restart the WinRM service after adding to WinRMRemoteWMIUsers__ (recommended).

.PARAMETER GrantClusterAccess
  If present, grant cluster (Failover Clusters) access to the account.

.NOTES
  Run as Administrator. Safe to re-run. Does NOT overwrite existing SDDL;
  it appends the required ACEs if missing.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string]$MonitoringAccount,
    [switch]$RestartWinRM,
    [switch]$GrantClusterAccess
)

function Test-IsAdministrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    Write-Error "Please run this script in an elevated PowerShell session (Run as Administrator)."
    exit 1
}

function Get-SidString {
    param([string]$Account)
    try {
        return ([System.Security.Principal.NTAccount]$Account).
            Translate([System.Security.Principal.SecurityIdentifier]).Value
    } catch {
        throw "Unable to resolve SID for account '$Account'. Ensure it exists. $_"
    }
}

$SID = Get-SidString -Account $MonitoringAccount
Write-Host "Monitoring account: $MonitoringAccount"
Write-Host "Resolved SID        : $SID" -ForegroundColor Cyan

function Ensure-LocalGroup {
    param([string]$GroupName)
    try {
        $group = Get-LocalGroup -Name $GroupName -ErrorAction SilentlyContinue
    } catch { $group = $null }
    if (-not $group) {
        Write-Host "Creating local group: $GroupName"
        try { New-LocalGroup -Name $GroupName | Out-Null }
        catch {
            # Fallback for older OS
            & cmd.exe /c "net localgroup `"$GroupName`" /add" | Out-Null
        }
    } else {
        Write-Host "Local group exists: $GroupName"
    }
}

function Ensure-LocalGroupMember {
    param([string]$GroupName,[string]$Account)
    try {
        $members = (Get-LocalGroupMember -Group $GroupName -ErrorAction SilentlyContinue) | Select-Object -ExpandProperty Name
    } catch { $members = @() }
    if ($members -and ($members -contains $Account)) {
        Write-Host "Account already in group '$GroupName': $Account"
        return
    }
    Write-Host "Adding '$Account' to group '$GroupName'"
    try {
        Add-LocalGroupMember -Group $GroupName -Member $Account -ErrorAction Stop
    } catch {
        # Fallback for older OS / domain nuances
        & cmd.exe /c "net localgroup `"$GroupName`" `"$Account`" /add" | Out-Null
    }
}

# 1) Groups: WinRMRemoteWMIUsers__, Performance Monitor Users
Ensure-LocalGroup -GroupName 'WinRMRemoteWMIUsers__'
Ensure-LocalGroupMember -GroupName 'WinRMRemoteWMIUsers__' -Account $MonitoringAccount

Ensure-LocalGroup -GroupName 'Performance Monitor Users'
Ensure-LocalGroupMember -GroupName 'Performance Monitor Users' -Account $MonitoringAccount

if ($RestartWinRM) {
    Write-Host "Restarting WinRM (WS-Management) service..." -ForegroundColor Yellow
    try {
        Restart-Service -Name WinRM -Force -ErrorAction Stop
        Write-Host "WinRM restarted."
    } catch {
        Write-Warning "Could not restart WinRM: $_"
    }
}

# 2) WMI Namespace permissions (Enable + Remote Enable)
#    Access masks (WMI): Enable = 0x1, Remote Enable = 0x20
$WmiRights = 0x1 + 0x20

function Grant-WmiNamespaceRights {
    param(
        [Parameter(Mandatory=$true)][string]$Namespace,
        [Parameter(Mandatory=$true)][string]$Sid,
        [int]$AccessMask = $WmiRights
    )
    Write-Host "Granting WMI rights on namespace '$Namespace' to SID $Sid"
    try {
        $secClass = Get-WmiObject -Namespace $Namespace -List __SystemSecurity -ErrorAction Stop
    } catch {
        Write-Warning "Namespace '$Namespace' not found or inaccessible: $_"
        return
    }

    $get = Invoke-WmiMethod -InputObject $secClass -Name GetSecurityDescriptor
    $sd  = $get.Descriptor

    # Build trustee
    $trustee = ([WMIClass]"Win32_Trustee").CreateInstance()
    $sidObj = New-Object System.Security.Principal.SecurityIdentifier($Sid)
    $sidBytes = New-Object byte[] ($sidObj.BinaryLength)
    $sidObj.GetBinaryForm($sidBytes,0)
    $trustee.SID = $sidBytes

    # Check if ACE already present
    $existing = $false
    if ($sd.DACL) {
        foreach ($ace in $sd.DACL) {
            try {
                if ($ace.Trustee.SID -and ($ace.Trustee.SID -join ',') -eq ($trustee.SID -join ',')) {
                    # If an ACE exists for this SID with at least these rights, leave it
                    if (($ace.AccessMask -band $AccessMask) -eq $AccessMask) { $existing = $true; break }
                }
            } catch {}
        }
    } else {
        $sd.DACL = @()
    }

    if ($existing) {
        Write-Host "WMI ACE already grants required rights on '$Namespace' — skipping."
        return
    }

    $aceNew = ([WMIClass]"Win32_ACE").CreateInstance()
    $aceNew.AccessMask = $AccessMask
    $aceNew.AceFlags   = 0
    $aceNew.AceType    = 0 # ACCESS_ALLOWED
    $aceNew.Trustee    = $trustee

    $sd.DACL += $aceNew
    $set = Invoke-WmiMethod -InputObject $secClass -Name SetSecurityDescriptor -ArgumentList $sd
    if ($set.ReturnValue -eq 0) {
        Write-Host "Granted WMI rights on '$Namespace'."
    } else {
        Write-Warning "Failed to set WMI security on '$Namespace' (ReturnValue=$($set.ReturnValue))."
    }
}

# Apply to required namespaces
@('root','root\cimv2') | ForEach-Object { Grant-WmiNamespaceRights -Namespace $_ -Sid $SID }
# MSCluster if exists
try {
    Get-WmiObject -Namespace 'root\MSCluster' -List __SystemSecurity -ErrorAction Stop | Out-Null
    Grant-WmiNamespaceRights -Namespace 'root\MSCluster' -Sid $SID
} catch {
    Write-Host "WMI namespace 'root\MSCluster' not present — skipping MSCluster rights."
}

# 3) SCM (Service Control Manager) rights
# Add ACE: (A;;CCLCRPRC;;;<SID>)
function Get-ScSddl {
    param([string]$ObjectName) # 'scmanager' or service name
    $out = & sc.exe sdshow $ObjectName 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "sc sdshow $ObjectName failed: $out"
    }
    # sc outputs on one or multiple lines; join and trim
    ($out -join '') -replace '\s+$',''
}

function Set-ScSddl {
    param([string]$ObjectName,[string]$Sddl)
    $out = & sc.exe sdset $ObjectName $Sddl 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "sc sdset $ObjectName failed: $out"
    }
    Write-Host "Updated SDDL for $ObjectName"
}

function Ensure-Ace-InSddl {
    param(
        [string]$Sddl,
        [string]$AceToAdd # e.g. (A;;CCLCRPRC;;;<sid>)
    )
    # Insert ACE into D:... section before S: (if present) or at end of D:
    if ($Sddl -notmatch 'D:') {
        # No DACL — create one
        return 'D:' + $AceToAdd + $Sddl
    }

    $idxD = $Sddl.IndexOf('D:')
    $idxS = $Sddl.IndexOf('S:')
    if ($idxS -gt $idxD -and $idxS -ne -1) {
        $dacl = $Sddl.Substring($idxD+2, $idxS - ($idxD+2))
        if ($dacl -like "*$AceToAdd*") { return $Sddl } # already present
        return ($Sddl.Substring(0,$idxS)) + $AceToAdd + ($Sddl.Substring($idxS))
    } else {
        # No S:, append at end
        $dacl = $Sddl.Substring($idxD+2)
        if ($dacl -like "*$AceToAdd*") { return $Sddl }
        return ($Sddl + $AceToAdd)
    }
}

function Grant-ScmRights {
    param([string]$Sid)
    $ace = "(A;;CCLCRPRC;;;$Sid)"
    Write-Host "Ensuring SCM (scmanager) has ACE: $ace"
    $sddl = Get-ScSddl -ObjectName 'scmanager'
    $new  = Ensure-Ace-InSddl -Sddl $sddl -AceToAdd $ace
    if ($new -ne $sddl) {
        Set-ScSddl -ObjectName 'scmanager' -Sddl $new
    } else {
        Write-Host "SCM already contains required ACE — no change."
    }
}
Grant-ScmRights -Sid $SID

# 4) Service rights for SQL Server engine services (List Children)
# Add ACE: (A;;LC;;;<SID>)
function Get-SqlEngineServices {
    # Typical engine service names: MSSQLSERVER (default) and MSSQL$<instance>
    Get-Service | Where-Object { $_.Name -match '^MSSQL(SERVER|\$)' } | Select-Object -ExpandProperty Name
}

function Grant-ServiceLC {
    param([string]$ServiceName,[string]$Sid)
    $ace = "(A;;LC;;;$Sid)"
    Write-Host "Ensuring service '$ServiceName' has ACE: $ace"
    try {
        $sddl = Get-ScSddl -ObjectName $ServiceName
    } catch {
        Write-Warning "Could not read SDDL for service '$ServiceName': $_"
        return
    }
    $new = Ensure-Ace-InSddl -Sddl $sddl -AceToAdd $ace
    if ($new -ne $sddl) {
        try {
            Set-ScSddl -ObjectName $ServiceName -Sddl $new
        } catch {
            Write-Warning "Failed updating service '$ServiceName' SDDL: $_"
        }
    } else {
        Write-Host "Service '$ServiceName' already contains required ACE — no change."
    }
}

$services = Get-SqlEngineServices
if (-not $services) {
    Write-Warning "No SQL Server engine services found (MSSQLSERVER or MSSQL$*). If instances exist with different names, add them manually."
} else {
    foreach ($svc in $services) {
        Grant-ServiceLC -ServiceName $svc -Sid $SID
    }
}

# 5) Cluster access (optional)
if ($GrantClusterAccess) {
    $clusterSvc = Get-Service -Name 'ClusSvc' -ErrorAction SilentlyContinue
    $moduleAvail = Get-Module -ListAvailable -Name FailoverClusters
    if ($clusterSvc -and $moduleAvail) {
        try {
            Import-Module FailoverClusters -ErrorAction Stop
            Write-Host "Granting cluster access (-Full) to $MonitoringAccount"
            Grant-ClusterAccess -User $MonitoringAccount -Full
            Write-Host "Cluster access granted."
        } catch {
            Write-Warning "Failed to grant cluster access: $_"
        }
    } else {
        Write-Warning "Cluster service or FailoverClusters module not found — skipping cluster access."
    }
}

Write-Host "`nAll done. You can now use the account '$MonitoringAccount' in Redgate SQL Monitor." -ForegroundColor Green
