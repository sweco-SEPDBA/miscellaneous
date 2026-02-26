############################################################################################################
# Set and read this parameters before each execution of a block.
$Databases = "Staging"
$LastScanTime = Get-Date -Date "2025-03-15 08:00:00"
############################################################################################################
# First restore before mw
$credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
$startTime = Get-Date

# Primary node
Get-ChildItem '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016$SWSQL01PA' |
Where-Object {$psitem.Name -in ($Databases)} |
Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -MaintenanceSolutionBackup -IgnoreLogBackup -NoRecovery -SqlCredential $credPrimary 

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

############################################################################################################
# Then restore just before mw and the last restore within the mw
# Reestore with multiple threads in filescan

$startTime = Get-Date
$job = $Databases | ForEach-Object {
    Start-ThreadJob  -ArgumentList @($_ , $LastScanTime) -ScriptBlock {
        param ($database, $LastScanTime)
        $files = Get-ChildItem "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL01PA\$database" -Recurse -File | Where-Object {$_.LastWriteTime -ge $LastScanTime} | Get-DbaBackupInformation -MaintenanceSolution -SqlInstance sestods072.sweco.se\swsql06pc -IgnoreDiffBackup
        return $files
    }
} 

$BackupInformation = $job | Wait-Job  | Receive-Job

get-job -State Completed | remove-job

$BackupInformation | Export-Clixml -Path "C:\Temp\CoreprodMove\BackupInformation_G1_$($startTime.ToString("yyyyMMdd_HHmmss")).xml"

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
write-host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery -Continue
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
write-host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan
$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -NoRecovery -Continue
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
write-host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

############################################################################################################
# When restore is done, move the databases recover the databases on primary

Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -Database $Databases -Recover

############################################################################################################
# Add database to AG

Add-DbaAgDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -Database $Databases -AvailabilityGroup SWSQL06PA -Secondary SESTODS073.sweco.se\SWSQL06PC -SeedingMode Manual


