
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
