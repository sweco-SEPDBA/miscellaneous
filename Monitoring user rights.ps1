<#
.SYNOPSIS
    Configure a monitoring account for Redgate Monitor on a Windows server.

.PARAMETER AccountName
    The monitoring account (SAM account name), e.g. 'DOMAIN\monitoruser' or 'machine\localuser'.

.PARAMETER GrantClusterAccess
    If set, grants Failover Cluster access (requires the FailoverClusters module and cluster node).
#>

param(
    [Parameter(Mandatory = $true)] [string]$AccountName,
    [switch]$GrantClusterAccess
)

# -------- Resolve account SID --------
function Get-AccountSid {
    param([string]$Name)
    try {
        $sid = ([System.Security.Principal.NTAccount]$Name).Translate([System.Security.Principal.SecurityIdentifier]).Value
        return $sid
    } catch {
        Write-Warning "Failed to resolve SID via .NET for '$Name'. Trying WMIC..."
        try {
        $plainUser = ($Name -split '\\')[-1]
        $out = wmic useraccount where "name='$plainUser'" get sid /value
        $sid = ($out -split "`r?`n") | Where-Object { $_ -match '^SID=' } | ForEach-Object { $_ -replace '^SID=', '' }
        if ([string]::IsNullOrWhiteSpace($sid)) { throw "SID empty" }
        return $sid
        } catch {
        throw "Unable to resolve SID for '$Name'. Ensure the account exists."
        }
    }
}

# -------- Local group helpers --------
function Initialize-LocalGroup {
    param([string]$GroupName)
    try {
        Get-LocalGroup -Name $GroupName -ErrorAction Stop | Out-Null
        Write-Host "Local group '$GroupName' already exists."
    } catch {
        Write-Host "Creating local group '$GroupName'..."
        New-LocalGroup -Name $GroupName -ErrorAction Stop | Out-Null
        Write-Host "Created local group '$GroupName'."
    }
}

function Add-LocalGroupMemberIfMissing {
    param([string]$GroupName, [string]$Member)
    $exists = $false
    try {
        $exists = (Get-LocalGroupMember -Group $GroupName  | Where-Object { $_.Name -ieq $Member }).Count -gt 0
    } catch {
        $exists = $false
    }
    if (-not $exists) {
        Write-Host "Adding '$Member' to local group '$GroupName'..."
        Add-LocalGroupMember -Group $GroupName -Member $Member -ErrorAction Stop
    } else {
        Write-Host "'$Member' is already in '$GroupName'."
    }
}

# -------- WMI namespace security (Enable + Remote Access) --------
function Set-WmiNamespaceSecurity {
    param(
        [Parameter(Mandatory=$true)][string]$Namespace,   # 'root', 'root\cimv2', 'root\mscluster'
        [Parameter(Mandatory=$true)][string]$AccountSid
    )

    $PermissionFlags = @{
        Enable       = 0x00000001
        RemoteAccess = 0x00000020
    }
    $neededMask = $PermissionFlags.Enable -bor $PermissionFlags.RemoteAccess

    try {
        $scope = New-Object System.Management.ManagementScope("\\.\$Namespace")
        $scope.Connect()

        $sysSecPath = New-Object System.Management.ManagementPath("__systemsecurity=@")
        $sysSec = New-Object System.Management.ManagementObject($scope, $sysSecPath, $null)
        $outParams = $sysSec.InvokeMethod("GetSD", $null, $null)
        $sd = $outParams.Properties["SD"].Value
        if (-not $sd) { throw "No security descriptor." }

        # Build ACE for SID
        $aceClass = New-Object System.Management.ManagementClass($scope, (New-Object System.Management.ManagementPath("Win32_Ace")), $null)
        $ace = $aceClass.CreateInstance()
        $ace.AccessMask = $neededMask
        $ace.AceFlags   = 0
        $ace.AceType    = 0

        $trusteeClass = New-Object System.Management.ManagementClass($scope, (New-Object System.Management.ManagementPath("Win32_Trustee")), $null)
        $trustee = $trusteeClass.CreateInstance()

        $sidObjClass = New-Object System.Management.ManagementClass($scope, (New-Object System.Management.ManagementPath("Win32_SID")), $null)
        $sidObj = $sidObjClass.CreateInstance()
        $sidBytes = New-Object byte[] ([System.Security.Principal.SecurityIdentifier]::new($AccountSid).BinaryLength)
        [void]([System.Security.Principal.SecurityIdentifier]::new($AccountSid).GetBinaryForm($sidBytes, 0))
        $sidObj.BinaryRepresentation = $sidBytes

        $trustee.SID = $sidObj
        $ace.Trustee = $trustee

        # Check if ACE with required mask already exists
        $hasRequired = $false
        foreach ($d in $sd.DACL) {
        try {
            $sidExisting = New-Object System.Security.Principal.SecurityIdentifier($d.Trustee.SID.BinaryRepresentation, 0)
            if ($sidExisting.Value -eq $AccountSid) {
            if (($d.AccessMask -band $neededMask) -eq $neededMask) { $hasRequired = $true; break }
            }
        } catch { }
        }

        if ($hasRequired) {
        Write-Host "WMI '$Namespace': SID already has Enable + Remote Access."
        return
        }

        # Append ACE and set SD
        $sd.DACL = $sd.DACL + $ace
        $inParams = $sysSec.GetMethodParameters("SetSD")
        $inParams["SD"] = $sd

        $result = $sysSec.InvokeMethod("SetSD", $inParams, $null)
        if ($result.ReturnValue -ne 0) {
        throw "SetSD returned $($result.ReturnValue)"
        }
        Write-Host "Granted WMI permissions on '$Namespace'."
    } catch {
        throw "Failed to set WMI permissions on '$Namespace': $_"
    }
}

# -------- SCMANAGER and Service SD helpers --------
function Set-ScmPermissions {
    param([string]$Sid)
    $sd = "D:(A;;CC;;;AU)(A;;CCLCRPRC;;;IU)(A;;CCLCRPRC;;;SU)(A;;CCLCRPWPRC;;;SY)(A;;KA;;;BA)(A;;CCLCRPRC;;;$Sid)S:(AU;FA;KA;;;WD)(AU;OIIOFA;GA;;;WD)"
    Write-Host "Setting SCMANAGER permissions (will overwrite existing SD)..."
    $proc = Start-Process -FilePath sc.exe -ArgumentList @('sdset','scmanager',"$sd") -NoNewWindow -PassThru -Wait
    if ($proc.ExitCode -ne 0) { throw "Failed to set scmanager permissions (exit $($proc.ExitCode))." }
}

function Set-ServiceListChildrenPermissions {
    param([string]$ServiceName, [string]$Sid)
    $sd = "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)(A;;LC;;;$Sid)S:(AU;FA;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)"
    Write-Host "Setting LC permission on service '$ServiceName' (will overwrite existing SD)..."
    $proc = Start-Process -FilePath sc.exe -ArgumentList @('sdset',"$ServiceName","$sd") -NoNewWindow -PassThru -Wait
    if ($proc.ExitCode -ne 0) { Write-Warning "Failed to set permissions on service '$ServiceName' (exit $($proc.ExitCode))." }
}

# -------- Main --------
try {
    $sid = Get-AccountSid -Name $AccountName
    Write-Host "Resolved SID for '$AccountName': $sid"

    # WinRMRemoteWMIUsers__ group
    $winrmGroup = 'WinRMRemoteWMIUsers__'  # two underscores
    Initialize-LocalGroup -GroupName $winrmGroup
    Add-LocalGroupMemberIfMissing -GroupName $winrmGroup -Member $AccountName

    # Performance Monitor Users group
    Initialize-LocalGroup -GroupName 'Performance Monitor Users'  # normally exists, but safe
    Add-LocalGroupMemberIfMissing -GroupName 'Performance Monitor Users' -Member $AccountName

    # Restart WinRM
    # Write-Host "Restarting WinRM service..."
    # try {
    #     Set-Service -Name WinRM -StartupType Automatic -ErrorAction SilentlyContinue
    #     Restart-Service -Name WinRM -Force -ErrorAction Stop
    #     Write-Host "WinRM restarted."
    # } catch {
    #     Write-Warning "Could not restart WinRM automatically. You may need to restart the 'Windows Remote Management (WS-Management)' service manually."
    # }

    # WMI permissions
    foreach ($ns in @('root','root\cimv2','root\mscluster')) {
        try { Set-WmiNamespaceSecurity -Namespace $ns -AccountSid $sid }
        catch {
        if ($ns -eq 'root\mscluster') {
            Write-Host "WMI namespace '$ns' not found; skipping."
        } else {
            throw $_
        }
        }
    }

    # # SCM permissions
    # Set-ScmPermissions -Sid $sid

    # # SQL Server services: MSSQLSERVER and MSSQL$*
    # $sqlServices = Get-Service | Where-Object { $_.Name -eq 'MSSQLSERVER' -or $_.Name -like 'MSSQL$*' }
    # if ($sqlServices.Count -eq 0) {
    #     Write-Host "No SQL Server services found (MSSQLSERVER or MSSQL$*)."
    # } else {
    #     foreach ($svc in $sqlServices) {
    #     Set-ServiceListChildrenPermissions -ServiceName $svc.Name -Sid $sid
    #     }
    # }

    # # Optional: Failover Cluster access
    # if ($GrantClusterAccess) {
    #     try {
    #     Write-Host "Granting Failover Cluster access..."
    #     Import-Module FailoverClusters -ErrorAction Stop
    #     Grant-ClusterAccess -User $AccountName -Full -ErrorAction Stop
    #     Write-Host "Cluster access granted."
    #     } catch {
    #     Write-Warning "Failed to grant cluster access. Ensure the FailoverClusters module is installed and this is a cluster node."
    #     }
    # }

    Write-Host "Configuration complete."
    Write-Host "Note: Changes to WMI/service permissions may require a short delay or service restart to take effect."
    } catch {
    Write-Error $_
    exit 1
}

# #Run this script on remote server
# $server = 'SESTODS061'               # target
# $account = 'SESTODS061\RedgateMonitorUser'    # monitoring account
# #$cred = Get-Credential            # admin creds for server1 (domain admin or local admin)

# # Invoke-Command -ComputerName $server -FilePath .\Configure-RedgateMonitor.ps1 -ArgumentList @('-AccountName', $account, '-GrantClusterAccess')   #-Credential $cred `
# Invoke-Command -ComputerName $server -FilePath '.\Monitoring user rights.ps1' -ArgumentList @($account)   #-Credential $cred `
