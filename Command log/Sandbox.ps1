
# Define variables
$serverInstance = "SESTODS061\SESQL23T" # e.g., "SQLSERVER\SQLEXPRESS" or "localhost" for default instance
$errorNumber = 50001 # Must be > 50000
$message = "This is a custom error message generated from a PowerShell script."
$severity = "ERROR" # Options: INFORMATIONAL, WARNING, ERROR

# Construct the T-SQL command
$sqlCommand = "EXEC master..xp_logevent @error_number = $errorNumber, @message = N'$message', @severity = N'$severity'"

# Execute the command using Invoke-Sqlcmd
try {
    Invoke-DbaQuery -SqlInstance $serverInstance -Query $sqlCommand
    #Invoke-DbaQuery  $serverInstance -Query $sqlCommand
    Write-Host "Message successfully logged to the SQL Server error log and Windows Event Log."
}
catch {
    Write-Error "Failed to log message to SQL Server: $_.Exception.Message"
}

Install-SwServerInstance -FQDN SESTODS094.sweco.se 
Copy-DbaLogin -Source SESTODS094\SESQL38T -Destination SESTODS094\SWSQL58P -Login 'SWECO\svc_sqlmonitor', 'SWECO\svc_sestows054'

$CRED = Get-Credential -UserName "sa" -Message "Enter password for sa account:"
Restore-DbaDatabase -SqlInstance SESTODS096\SWSQL57P -Path '\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\PE' -SqlCredential $CRED

Test-DbaLastBackup -SqlInstance NOOSLDS002.sweco.se\NOSQL22P -Database hbs -Destination SESTODS065.sweco.se\SESQL20T 

$CMDBInstance = 'SESTODS039\SWSQL16P'
$success = 'Success', 'Skipped-AG-Secondary', 'Skipped-LS-Secondary'
$restoreResult = Test-DbaLastBackup -SqlInstance NOOSLDS002.sweco.se\NOSQL22P -Database hbs -Destination SESTODS065.sweco.se\SESQL20T 


if ($restoreResult.RestoreResult -notin $success) {
            $sqlCommand = "EXEC master..xp_logevent @error_number = 50002, @message = N'Restore test failed for database: $($TestDB.dbName) on:$($TestDB.SqlInstance) - Result: $($_.RestoreResult)', @severity = N'ERROR'"
            $sqlCommand
            Invoke-DbaQuery -SqlInstance $CMDBInstance -Query $sqlCommand
}
    # Log failed restore results
# $restoreResult | Where-Object { $_.RestoreResult -in $success } | 
#             # Raise an error event in SQL Server Error Log for failed restores
#             $sqlCommand = "EXEC master..xp_logevent @error_number = 50002, @message = N'Restore test failed for database: $($TestDB.dbName) on:$($TestDB.SqlInstance) - Result: $($_.RestoreResult)', @severity = N'ERROR'"
#             Invoke-DbaQuery -SqlInstance $CMDBInstance -Query $sqlCommand


Get-ADGroupMember -identity "SW-Role-MasterdataANDIntegrations" | 
select-object name, samaccountname | 
format-table

Get-ADGroupMember -identity "SW-SQL-BkpShareException" | 
select-object name, samaccountname | 
format-table

Get-ADGroupMember -identity "SW-SSO-Azure-RedgateMonitor_Users" | 
select-object name, samaccountname | 
format-table

Get-ADGroup -Identity "SW-SSO-Azure-RedgateMonitor_Users" 

Add-ADGroupMember -Identity 'SW-SQL-BkpShareException' -Members 'PLKRKAS033$'

Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SW-ROLE-SQLAdmin'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SEPDBA'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SENEKU'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'DKIVER'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'DKSTET'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SE1B3Y'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'DKIAIM'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SEOETT'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'BEVERB'


Get-DbaDbBackupHistory -SqlInstance SESTODS041.sweco.se\SWSQL20P -Database syslog_db  | Where-Object { $_.Type -eq 'Full'} | Format-List

Install-SwMaintenance -Server SESTOPS014 -Instance SAFECOMEXPRESS
Install-SwMaintenance -Server NLAMSPS014 -Instance SAFECOMEXPRESS
Get-AdGroupMember -Identity "SW-SQL-BkpShareSafecom" | Select-Object Name, SamAccountName | Format-Table
Get-AdGroupMember -Identity "SW-Azure-Role-AppDevBi" | Select-Object Name, SamAccountName | Format-Table
Get-AdGroupMember -Identity "SW-Role-BiAnalytics-SQL" | Select-Object Name, SamAccountName | Format-Table
Get-AdGroupMember -Identity "SW-Role-MasterdataANDIntegrations" | Select-Object Name, SamAccountName | Format-Table
Get-AdGroupMember -Identity "SW-SQL-AgentSVCAcct" | Select-Object Name, SamAccountName | Format-Table
Add-ADGroupMember -Identity 'SW-SQL-AgentSVCAcct' -Members 'msvc_SESTODS084$'
Add-ADGroupMember -Identity 'SW-SQL-BkpShareSafecom' -Members 'SESTOPS014$'
Add-ADGroupMember -Identity 'SW-SQL-BkpShareSafecom' -Members 'NLAMSPS014$'

Get-DbaUptime -SqlInstance SESTODS043.sweco.se\SWSCOM02P

#Settings
$SqlInstance = "SESTODS052.sweco.se\SWSQL29P"
$Database = "SystemHealth"
$StagingTableWindowsUdate = "WindowsUpdate-SystemHealth-Import-stage"
$StagingTableIntunes = "IntuneData-SystemHealth-Import-stage"


#$PathWindowsUpdates = "\\SESTOAS012\c$\Script\AzureReporting\WUFBReporting"
$PathWindowsUpdates = "c:\Script\AzureReporting\WUFBReporting"
#$PathIntunes = "\\SESTOAS012\c$\Script\AzureReporting\IntuneReporting"
$PathIntunes = "c:\Script\AzureReporting\IntuneReporting"

#Find oldest files
$FileDate = (Get-Date -Format g)
Get-ChildItem -Path $PathWindowsUpdates | 
ForEach-Object {
    if ($_.LastWriteTime -lt $FileDate -and -not $_.PSIsContainer) {
        $FileDate = $_.LastWriteTime
        $CsvFileWindows = $_.FullName
		$WindowsFileCreationTime = $_.CreationTime | get-date -format "yyyy-MM-dd hh:mm:ss"
}	
}


$FQDN = 'SESTODS065.sweco.se'



Set-DbatoolsInsecureConnection -SessionOnly
Connect-DbaInstance -SqlInstance $SqlInstance -Database master 
Connect-DbaInstance -SqlInstance $SqlInstance -Database master -SqlCredential $cred

$SqlInstance = 'SESTODS093\SWSQL56P'
$cred = Get-Credential -UserName "SESTODS093\SqlAdmin" -Message "Enter credentials for connecting to $FQDN"
$FQDN = $SqlInstance.Split('\')[0]
Set-SwRedgateUserRights -FQDN $FQDN -SqlInstance $SqlInstance -MonitoringAccount 'SESTODS093\SqlMonitor' -RestartWinRM -GrantClusterAccess -Credential $cred
Add-SwMonitorInstance -FQDN $FQDN
Add-SwMonitorInstance -FQDN NLAMSAS075.sweco.se
Add-SwMonitorInstance -FQDN SESTOAS888.sweco.se

MTp6clhudDdZV3hVYlZMNmVSTTRuZUxxSlkvZmhodU9JcXg0dVZIci9WQ1JjPQ==
Add-SwMonitorInstance -FQDN NLAMSAS243 -MonitoringAccount 'NLAMSAS243\SQLMonitor'
s

    $BackCheckParams = @{
        SqlInstance = "SESTODS052.sweco.se\SWSQL29P"
        Destination = "SESTODS076.sweco.se\SESQL43T"
        Database    = "CenturiData"
        NoCheck     = $true
    }

    # Log before running backup test
    Test-DbaLastBackup @BackCheckParams

    Get-DbaUptime -SqlInstance SESTODS076.sweco.se\SESQL43T

    Test-DbaSpn -ComputerName SESTODS090.sweco.se

    invoke-command -ComputerName "DEFRAAS033", "FIHELAS128", "NLAMSAS160", "NLAMSAS194", "SESTOAS661", "SESTOAS662", "SESTOAS675", "SESTOAS676" -ScriptBlock {Restart-Service -Name "SQLSentryServer" -Force -ErrorAction Stop}

   Get-DbaDbBackupHistory -SqlInstance plkrkas033\optima

Set-DbatoolsInsecureConnection -SessionOnly

Update-SwPsModules -UpdateDbaTools

Get-Certificate -Template "SwecoWebServerV4" -DnsName $sDnsName -SubjectName "CN=SEDCXDS010.sweco.se" -CertStoreLocation "Cert:\LocalMachine\My" 

Restore-DbaDatabase -SqlInstance SETODS964\SWERP16T -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\macoprod' -DatabaseName 'conv3' -IgnoreLogBackup -MaintenanceSolutionBackup -ReplaceDbNameInFile

Install-SwBlitz -Server SESTODS070 -Instance SWSQL42P

Copy-DbaAgentJob -SOURCE SESTODS058\CMS02 -Destination SEDCXDS007.sweco.se\CMS01 -Job 'RestoreTest-Mini-UK'
Copy-DbaAgentJob -SOURCE SESTODS058\CMS02 -Destination SEDCXDS007.sweco.se\CMS01 -Job 'RestoreTest-Mini'
Copy-DbaAgentJob -SOURCE SESTODS058\CMS02 -Destination SEDCXDS007.sweco.se\CMS01 -Job 'RestoreTest-Large'
Copy-DbaAgentJob -SOURCE SESTODS058\CMS02 -Destination SEDCXDS007.sweco.se\CMS01 -Job 'RestoreTest-Medium' 

copy-dbaagentproxy -Source SESTODS058\CMS02 -Destination SEDCXDS007.sweco.se\CMS01 -Proxy 'svc_sql_dailychecks'
Copy-DbaDatabase -Source SESTODS039\SWSQL18P -Destination SESTODS039\SWSQL18P -Database KopplingsSchema_v3 -NewName KopplingsSchema_v4 -BackupRestore -UseLastBackup 

$BackCheckParams = @{
    SqlInstance = "DEFRAAS073.sweco.se\ACCLARO"
    Destination = "NLDCXDS002.sweco.se\NLSQL14T"
    Database    = "master"
    NoCheck     = $true
}
$restoreResult = Test-DbaLastBackup @BackCheckParams -verbose

GET-DbaDbBackupHistory -SqlInstance SESTODS041.sweco.se\SWSQL20P -Database "syslog_db" -Since (Get-Date).AddDays(-7)  | Where-Object { $_.Type -eq 'Full'} | Format-List
GET-DbaDbBackupHistory -SqlInstance DEFRADS003.sweco.se\DESQL11P -Since (Get-Date).AddDays(-7)  | Where-Object { $_.Type -eq 'Full'} | Format-List *
GET-DbaDbBackupHistory -SqlInstance coreprod.sql.sweco.se -Database "swecocoreimport" -Since (Get-Date).AddDays(-7)  | Where-Object { $_.Type -eq 'Full'} | Format-List
GET-DbaDbBackupHistory -SqlInstance SESTODS095.sweco.se\SESQL12P -Database "30040621_billerud_k_-_uppraettelse_rinningsunderlag_cirkledning_kokare_1_PnId"-LastFull | Format-List

Restore-DbaDatabase -SqlInstance SESTODS052.sweco.se\SWSQL29P -Path '\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\SESTODS052$SWSQL29P\PMDB_Import' -DatabaseName PMDB_Import_260525  -MaintenanceSolutionBackup -ReplaceDbNameInFile
Restore-DbaDatabase -SqlInstance SESTODS052.sweco.se\SWSQL29P -Path '\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\SESTODS052$SWSQL29P\PMDB_Prod' -DatabaseName PMDB_Prod_260525  -MaintenanceSolutionBackup -ReplaceDbNameInFile
Restore-DbaDatabase -SqlInstance SESTODS052.sweco.se\SWSQL29P -Path '\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\SESTODS052$SWSQL29P\PMDB_Utbild' -DatabaseName PMDB_Utbild_260525  -MaintenanceSolutionBackup -ReplaceDbNameInFile
Restore-DbaDatabase -SqlInstance SESTODS052.sweco.se\SWSQL29P -Path '\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\SESTODS052$SWSQL29P\PMDB831' -DatabaseName PMDB831_260525  -MaintenanceSolutionBackup -ReplaceDbNameInFile


Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\conversion' -MaintenanceSolutionBackup -NoRecovery 
Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\integration' -MaintenanceSolutionBackup -NoRecovery 
Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\MonitoringDatabase' -MaintenanceSolutionBackup -NoRecovery 
Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\PeoplePlanner' -MaintenanceSolutionBackup -NoRecovery 
Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\macoprod' -MaintenanceSolutionBackup -NoRecovery 

Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\conversion' -MaintenanceSolutionBackup -Continue -NoRecovery 
Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\integration' -MaintenanceSolutionBackup -Continue -NoRecovery 
Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\MonitoringDatabase' -MaintenanceSolutionBackup -Continue -NoRecovery 
Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\PeoplePlanner' -MaintenanceSolutionBackup -Continue -NoRecovery 
Restore-DbaDatabase -SqlInstance SEDCXDS011\SWERP04PC -Path '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup\SESTOCL020$SWERP02PA\macoprod' -MaintenanceSolutionBackup -Continue -NoRecovery 
Restore-DbaDatabase -SqlInstance SESTODS965\SWERP18T -Path '\\sweco.se\sw\IT\Backup\SQLERP\TemporaryBackups\Conv2-Refresh\SESTOCL020$SWERP02PA\macoprod\FULL_COPY_ONLY\SESTOCL020$SWERP02PA_macoprod_FULL_COPY_ONLY_20260622_090247.bak' -MaintenanceSolutionBackup -DatabaseName conv2 
Restore-DbaDatabase -SqlInstance SESTODS965\SWERP18T -Path '\\sweco.se\sw\IT\Backup\SQLERP\TemporaryBackups\Conv2-Refresh\SESTOCL020$SWERP02PA\PeoplePlanner\FULL_COPY_ONLY\SESTOCL020$SWERP02PA_PeoplePlanner_FULL_COPY_ONLY_20260622_110305.bak' -MaintenanceSolutionBackup -DatabaseName pplanconv2 
repair-dbadborphanuser -SqlInstance SESTODS965\SWERP18T -Database conv2, pplanconv2



Install-SwServerInstance -FQDN SEDCXDS011.sweco.se -Instance SWERP04PC
Install-SwServerInstance -FQDN NLDCXDS005.sweco.se 
Install-SwServerInstance -FQDN SEDCXDS012.sweco.se 
Install-SwServerInstance -FQDN SEDCXDS013.sweco.se 
Install-SwServerInstance -FQDN NLAMSAS023.sweco.se -Instance SWECO01
Install-SwServerInstance -FQDN FIHELDS005.sweco.se 

$signfiles = get-childitem -path ".\CoreProdMove\vs3\*.ps1" -recurse 
foreach ($signfile in $signfiles) {
    Write-Host "Signing file: $($signfile.Name)"
    .\SignFiles_CAIT.ps1 $signfile
}

get-dbaspn -AccountName SWECO\svc_sql_SWERP02PA | Format-List
test-dbaspn -ComputerName SESTODS950

Copy-DbaDatabase -Source SESTODS952\SWERP06PC -Destination SEDCXDS011\SWERP04PC -Database macstaging -BackupRestore -UseLastBackup

Copy-DbaLogin -Source SESTODS952\SWERP06PC -Destination SEDCXDS011\SWERP04PC 
GET-DBALogin -SqlInstance SESTODS952.sweco.se\SWERP06PC | Format-table 

copy-dbadatabase -source coreprod.sql.sweco.se -destination coretest2.sql.sweco.se -database Swecocoreimport -BackupRestore -UseLastBackup

$UserCredentials = Get-Credential -UserName "SWECO\sepdba_da" -Message "Enter credentials for installing $ServerName\$InstanceName"
Install-SwMaintenancePackage -Server SESTODS971 -Instance SWERP12TC -BackupPath '\\sweco.se\sw\IT\Backup\SQLERP\SqlBackup' -InstallJobs -UserCredential $UserCredentials -SqlServiceAccount 'SWECO\msvc_SWERP12TA$' 

Get-DbaDbBackupHistory -SqlInstance SESTODS971.sweco.se\SWERP12TC -Database 'ittest' -Since (Get-Date).AddDays(-1)  
Get-DbaDbBackupHistory -SqlInstance SESTODS970.sweco.se\SWERP12TC -Database 'ittest' -Since (Get-Date).AddDays(-1)  


Get-DbaDbBackupHistory -SqlInstance SESTODS950.sweco.se\SWERP04PC -Database 'macoprod' -Since (Get-Date).AddDays(-13) | where-object { $_.Type -eq 'Log' -and $_.Start -lt (Get-Date).AddDays(-11) }  

copy-dbalogin -SOURCE SESTODS041\SWSQL20P -Destination SESTODS089\SESQL50P -ExcludeSystemLogins
Copy-DbaDatabase -SOURCE SESTODS041\SWSQL20P -Destination SESTODS089\SESQL50P -AllDatabases -ExcludeDatabase maintenance -BackupRestore -UseLastBackup -SetSourceOffline

    $Params = @{
        Server = "FIHELDS011"
        Instance = "FISQL13P"
    }
    Install-SwMaintenance @Params

repair-dbadborphanuser -SqlInstance NLAMSAS023.sweco.se\SWECO01 -Database CI_Location

get-dbaspn -ComputerName SESTODS072
test-dbaspn -ComputerName SESTODS072
get-dbaspn -AccountName SWECO\msvc_SESTOCL023$

Copy-DbaDatabase -SOURCE nlamsds018\besql01p -Destination NLAMSDS023\NLSQL13T -Database 'PMOPRO' -NewName 'PMOPRO_PreProd' -BackupRestore -UseLastBackup -WithReplace

copy-dbalogin -source FIHELDS014.sweco.se -Destination FIHELDS005.sweco.se -LOGIN SWECO\FIVVEI_BD

Install-SwServerInstance -FQDN NOOSLDS006.sweco.se
Install-SwServerInstance -FQDN FIHELDS006.sweco.se

copy-dbadatabase -Source SEDCXDS910\SWERP20T -Destination SESTODS965\SWERP18T -Database integration_conv2 -BackupRestore -UseLastBackup
get-dbadborphanuser -SqlInstance SESTODS965\SWERP18T -Database integration_conv2

Get-DbaInstanceProperty -SqlInstance SESTODS965\SWERP18T | OUT-GridView

Get-DbaInstanceProperty -SqlInstance SESTODS965\SWERP18T -InstanceProperty VersionMajor, VersionMinor, BuildNumber, VersionString, Edition, Collation, PhysicalMemory, Processors, OSVersion  | Select-Object @{n = 'CmsServerName'; e = { $instance}}, Name, Value

get-dbaspconfigure -sqlinstance SESTODS965\SWERP18T | out-gridview









Add-Type -Assembly System.Web # [System.Web.HttpUtility]::UrlEncode() needs this
$URL   = "https://docs.google.com/spreadsheets/d/16Ymdz80xlCzb6CwRFVokwo0onkofVYFoSkc7mYe6pgw/gviz/tq?tq=&tqx=out:csv" 
$CmdbInstance = "cmdb_dbw.sql.sweco.net"
$Database = "CMDB"
$Table = "SqlServerBuilds_stage"


Invoke-WebRequest $URL -UseBasicParsing| export-csv c:\temp\sqlserverbuilds.csv
import-csv c:\temp\sqlserverbuilds.csv -delimiter ',' | Write-DbaDataTable -SqlInstance $CmdbInstance -Database $Database -Table $Table  -AutoCreateTable -Truncate


Get-DbaUptime -SqlInstance dkcphds003\dksql02p

Test-DbaLastBackup -SqlInstance NLAMSDS020.sweco.se\NLSQL11P -Destination NLDCXDS002.sweco.se\NLSQL14T -Database BE_P3D20_7946_0001_M_Piping 
Test-DbaLastBackup -SqlInstance SESTODS951.sweco.se\SWERP04PC -Destination SESTODS099\SWSQL33T -Database macoprod 

install-swserverinstance -FQDN NLDCXDS007.sweco.se


$RunDate = get-date -format "yyyyMMdd"
Test-SwRestoreDatabase -CMDBInstance cmdb_dbw.sql.sweco.net -DestInstance GBLDSDS004.sweco.se\GBSQL14T -LogDir C:\Scripts\RestoreTests\Logs\Mini-UK -DBMaxSizeMB 5120 -CountryCode GB -MaxAgeInDays 1 -MinLogLevel "INFO" -LogName "Test-SwRestoreDatabase-$RunDate" -Verbose

