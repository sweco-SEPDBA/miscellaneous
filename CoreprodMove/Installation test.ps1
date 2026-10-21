$ServerName = "SESTODS061"
$InstanceName = "SWSQL01T"
$Version = "2025"
$Collation = "SQL_Latin1_General_CP1_CI_AS"
$Edition = "Standard Developer"
$PathToInstallationMedia = "\\sestofs311\Program\DA\APPLIK\SwecoSQLPatches\MsSqlIsos\$Version\$Edition"
$SaCredentials = Get-Credential -UserName "sa" -Message "Enter SA credentials for $ServerName\$InstanceName"
$UserCredentials = Get-Credential -UserName "SWECO\sepdba_da" -Message "Enter credentials for installing $ServerName\$InstanceName"
$ServiceAccountCredentials = Get-Credential -UserName "SWECO\svc_sql_onprem1$" -Message "Enter credentials for service accounts for SWECO\svc_sql_onprem1$"



        $Params = @{
            "SqlInstance" = "$ServerName\$InstanceName"
            "Version" = $Version
            "SaCredential" = $SaCredentials
            "Credential" = $UserCredentials
            "Authentication" = "Credssp"
           # "Configuration" = $Configuration
            "Path" = $PathToInstallationMedia
            "Feature" = "Engine"
            "AuthenticationMode" = "Mixed"
            "InstancePath" = "E:\Installed"
            "DataPath" = "E:\SQLData\$InstanceName"
            "LogPath" = "F:\SQLLog\$InstanceName"
            "TempPath" = "H:\SQLData\$InstanceName"
            "BackupPath" = "E:\SQLBackup\$InstanceName"
            "UpdateSourcePath" = "\\sestofs311\Program\DA\APPLIK\SwecoSQLPatches\MS SQL Current version\$Version"
            "AdminAccount" = 'SWECO\SW-Role-SQLAdmin'
            "Port" = 1433
            "SqlCollation" = $Collation
            "EngineCredential" = $ServiceAccountCredentials
            "AgentCredential" = $ServiceAccountCredentials
            "PerformVolumeMaintenanceTasks" = $true
            "Restart" = $true
            "Confirm" = $false
        }
        
        Write-Verbose "Running installations with following settings:"
        Write-Verbose @"
            "SqlInstance" = "$ServerName\$InstanceName"
            "Version" = $Version
            "SaCredential" = $SaCredentials
            "Credential" = $UserCredentials
            "Authentication" = "Credssp"
            "Configuration" = $Configuration
            "Feature" = "Engine"
            "AuthenticationMode" = "Mixed"
            "InstancePath" = "E:\Installed"
            "DataPath" = "E:\SQLData\$InstanceName"
            "LogPath" = "F:\SQLLog\$InstanceName"
            "TempPath" = "H:\SQLData\$InstanceName"
            "BackupPath" = "E:\SQLBackup\$InstanceName"
            "AdminAccount" = 'SWECO\SW-Role-SQLAdmin'
            "EngineCredential" = $ServiceAccountCredentials
            "AgentCredential" = $ServiceAccountCredentials
            "PerformVolumeMaintenanceTasks" = $true
            "Restart" = $true
            "Confirm" = $false
"@

        $InstallResult = Install-DbaInstance @Params -Verbose $verbose
        write-output "Install result: $InstallResult"

