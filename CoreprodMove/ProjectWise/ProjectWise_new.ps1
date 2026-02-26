############################################################################################################
# Set and read this parameters before each execution of a block.
$Databases = "pw_FI-IN_CED", "pw_fut_CE280", "pw_paris_ligne17_CE280", "pw_sweco_CE280", "pw_vectura_CE280", "pw_vectura_extern_CE280"
$LastScanTime = Get-Date -Date "2025-04-05 09:45:00"
############################################################################################################
# First restore before mw
$credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
$startTime = Get-Date

# Primary node
Get-ChildItem '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016$SWSQL02PA' |
Where-Object {$psitem.Name -in ($Databases)} |
Restore-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -MaintenanceSolutionBackup -IgnoreLogBackup -NoRecovery -SqlCredential $credPrimary 

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

# Secondary node
Get-ChildItem '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016$SWSQL02PA' |
Where-Object {$psitem.Name -in ($Databases)} |
Restore-DbaDatabase -SqlInstance SESTODS017.sweco.se\SWSQL48P -MaintenanceSolutionBackup -IgnoreLogBackup -NoRecovery -SqlCredential $credSecondary 

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
        $files = Get-ChildItem "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL02PA\$database" -Recurse -File | Where-Object {$_.LastWriteTime -ge $LastScanTime} | Get-DbaBackupInformation -MaintenanceSolution -SqlInstance sestods072.sweco.se\swsql06pc -IgnoreDiffBackup
        return $files
    }
} 

$BackupInformation = $job | Wait-Job  | Receive-Job

get-job -State Completed | remove-job

$BackupInformation | Export-Clixml -Path "C:\Temp\ProjectWiseMove\BackupInformation_G3_$($startTime.ToString("yyyyMMdd_HHmmss")).xml"

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
write-host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -NoRecovery -Continue
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
write-host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan
$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS017.sweco.se\SWSQL48P -NoRecovery -Continue
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
write-host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

############################################################################################################
# When restore is done, move the databases recover the databases on primary

Restore-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database $Databases -Recover

############################################################################################################
# Add database to AG

Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_FI-IN_CED -AvailabilityGroup SWSQL48P11PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_fut_CE280 -AvailabilityGroup SWSQL48P12PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_paris_ligne17_CE280 -AvailabilityGroup SWSQL48P13PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_sweco_CE280 -AvailabilityGroup SWSQL48P14PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_vectura_CE280 -AvailabilityGroup SWSQL48P15PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_vectura_extern_CE280 -AvailabilityGroup SWSQL48P16PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual

