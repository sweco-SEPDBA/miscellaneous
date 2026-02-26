############################################################################################################
# Set and read this parameters before each execution of a block.
$Databases = "pw_FI-IN_CED", "pw_fut_CE280", "pw_paris_ligne17_CE280", "pw_sweco_CE280", "pw_vectura_CE280", "pw_vectura_extern_CE280"
# $DatabasesNew = "pw_FI-IN_2023", "pw_fut_2023", "pw_paris_ligne17_2023", "pw_sweco_2023", "pw_vectura_2023", "pw_vectura_extern_2023"

#$LastScanTime = Get-Date -Date "2025-04-01 14:50:00"
############################################################################################################
# First restore before mw
$credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
$startTime = Get-Date

FOREACH ($Database in $Databases) {
    $DatabaseNew = $Database.Replace("CED", "2023").Replace("CE280", "2023")
    Restore-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -DatabaseName $DatabaseNew -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL02PA\$Database" -NoRecovery -SqlCredential $credPrimary -ReplaceDbNameInFile -IgnoreLogBackup -MaintenanceSolutionBackup
    Restore-DbaDatabase -SqlInstance SESTODS017.sweco.se\SWSQL48P -DatabaseName $DatabaseNew -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL02PA\$Database" -NoRecovery -SqlCredential $credSecondary -ReplaceDbNameInFile -IgnoreLogBackup -MaintenanceSolutionBackup
}

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

############################################################################################################
# Then restore just before mw and the last restore within the mw
# Reestore with multiple threads in filescan

$startTime = Get-Date

FOREACH ($Database in $Databases) {
    $DatabaseNew = $Database.Replace("CED", "2023").Replace("CE280", "2023")
    Restore-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -DatabaseName $DatabaseNew -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL02PA\$Database"  -NoRecovery -Continue -MaintenanceSolutionBackup
    Restore-DbaDatabase -SqlInstance SESTODS017.sweco.se\SWSQL48P -DatabaseName $DatabaseNew -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL02PA\$Database"  -NoRecovery -Continue -MaintenanceSolutionBackup
}

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan


############################################################################################################
# When restore is done, move the databases recover the databases on primary

FOREACH ($Database in $Databases) {
    $DatabaseNew = $Database.Replace("CED", "2023").Replace("CE280", "2023")
    Restore-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database $DatabaseNew -Recover
}

############################################################################################################
# Add database to AG

Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_FI-IN_2023 -AvailabilityGroup SWSQL48P01PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_fut_2023 -AvailabilityGroup SWSQL48P02PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_paris_ligne17_2023 -AvailabilityGroup SWSQL48P03PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_sweco_2023 -AvailabilityGroup SWSQL48P04PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_vectura_2023 -AvailabilityGroup SWSQL48P05PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_vectura_extern_2023 -AvailabilityGroup SWSQL48P06PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual

