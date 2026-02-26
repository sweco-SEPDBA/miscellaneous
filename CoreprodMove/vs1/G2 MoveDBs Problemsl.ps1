############################################################################################################
# Set and read this parameters before each execution of a block.
#$LastScanTime = Get-Date -Date "2025-03-11 07:00:00"
############################################################################################################
############################################################################################################
# First restore before mw TravelExpense
$credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa

# Primary node
$startTime = Get-Date

$FileStructure = @{
    'TraveExpense' = 'E:\SQLData\SWSQL06PC\TravelExpense.mdf'
    'TraveExpense_log' = 'F:\SQLLog\SWSQL06PC\TravelExpense_log.ldf'
    }

Get-ChildItem '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016$SWSQL01PA\TravelExpense' |
Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -MaintenanceSolutionBackup -IgnoreLogBackup -NoRecovery -SqlCredential $credPrimary  -FileMapping $FileStructure

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan


############################################################################################################
# First restore before mw FrameworkAgreement
$credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
$startTime = Get-Date

# Primary node
Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -DatabaseName FrameworkAgreement -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016$SWSQL01PA\FrameworkAgreement' -MaintenanceSolutionBackup -IgnoreLogBackup -NoRecovery -SqlCredential $credPrimary

#-MaintenanceSolutionBackup -IgnoreLogBackup -NoRecovery -SqlCredential $credPrimary 

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

# Primary node
Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -DatabaseName FrameworkAgreement -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016$SWSQL01PA\FrameworkAgreement' -MaintenanceSolutionBackup -IgnoreLogBackup -NoRecovery -SqlCredential $credSecondary

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

############################################################################################################
############################################################################################################
# Then restore just before mw and the last restore within the mw
# Reestore with multiple threads in filescan

# TravelExpense

$startTime = Get-Date

Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery -Continue -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL01PA\TravelExpense" -MaintenanceSolutionBackup -IgnoreDiffBackup
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
write-host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan


#FrameworkAgreement
$startTime = Get-Date

Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery  -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL01PA\FrameworkAgreement"
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
write-host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -NoRecovery  -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL01PA\FrameworkAgreement"
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
write-host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

############################################################################################################
# When restore is done, move the databases recover the databases on primary

Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -Database TravelExpense -Recover
Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -Database FrameworkAgreement -Recover

############################################################################################################
# Rename files for travelexpense
$cmd = @"
USE TravelExpense;
GO
SELECT file_id, name as [logical_file_name],physical_name
from sys.database_files
"@
Invoke-DbaQuery -SqlInstance SESTODS072.sweco.se\SWSQL06PC -Query $cmd

$cmd = @"
USE [master];

ALTER DATABASE [TravelExpense] MODIFY FILE ( NAME = TraveExpense, NEWNAME = TravelExpense); 
ALTER DATABASE [TravelExpense] MODIFY FILE ( NAME = TraveExpense_log, NEWNAME = TravelExpense_log); 
"@
Invoke-DbaQuery -SqlInstance SESTODS072.sweco.se\SWSQL06PC -Query $cmd

############################################################################################################
# Do backupof TravelExpense from new primary

$cmd = @"
EXECUTE [dbo].[DatabaseBackup]
    @Databases = 'TravelExpense',
    @Directory = N'\\sweco.se\sw\IT\Backup\SQL\SqlBackup',
    @BackupType = 'FULL',
    @Verify = 'N',
    @CleanupTime = 65,
    @CheckSum = 'Y',
    @Compress = 'Y',
    @LogToTable = 'Y'
"@
Invoke-DbaQuery sestods072.sweco.se\swsql06pc -Database maintenance -Query $cmd 

$cmd = @"
EXECUTE [dbo].[DatabaseBackup]
    @Databases = 'TravelExpense',
    @Directory = N'\\sweco.se\sw\IT\Backup\SQL\SqlBackup',
    @BackupType = 'LOG',
    @Verify = 'Y',
    @CleanupTime = 65,
    @CheckSum = 'Y',
    @Compress = 'Y',
    @LogToTable = 'Y',
    @ChangeBackupType = 'Y'
"@
Invoke-DbaQuery sestods072.sweco.se\swsql06pc -Database maintenance -Query $cmd

############################################################################################################
# Restore on secondary

$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -Database TravelExpense -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS072$SWSQL06PC\TravelExpense' -MaintenanceSolutionBackup -NoRecovery -SqlCredential $credSecondary


############################################################################################################
# Add database to AG

Add-DbaAgDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -Database TravelExpense -AvailabilityGroup SWSQL06PA -Secondary SESTODS073.sweco.se\SWSQL06PC -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -Database FrameworkAgreement -AvailabilityGroup SWSQL06PA -Secondary SESTODS073.sweco.se\SWSQL06PC -SeedingMode Manual


