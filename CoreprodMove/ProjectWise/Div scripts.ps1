
$credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
Restore-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL025`$SWSQL48P09PA\pw_orch_2023_ics\FULL"  -SqlCredential $credPrimary  -MaintenanceSolutionBackup
Restore-DbaDatabase -SqlInstance SESTODS017.sweco.se\SWSQL48P -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL025`$SWSQL48P09PA\pw_orch_2023_ics\FULL" -NoRecovery -SqlCredential $credSecondary -MaintenanceSolutionBackup

Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_orch_2023_ics -AvailabilityGroup SWSQL48P09PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual

Restore-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -DatabaseName pw_sweco_2023_new -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL02PA\pw_sweco_CE280" -NoRecovery -SqlCredential $credPrimary -ReplaceDbNameInFile -IgnoreLogBackup -MaintenanceSolutionBackup
Restore-DbaDatabase -SqlInstance SESTODS017.sweco.se\SWSQL48P -DatabaseName pw_sweco_2023_new -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016`$SWSQL02PA\pw_sweco_CE280" -NoRecovery -SqlCredential $credSecondary -ReplaceDbNameInFile -IgnoreLogBackup -MaintenanceSolutionBackup
Restore-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_sweco_2023_new -Recover
Add-DbaAgDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P -Database pw_sweco_2023_new -AvailabilityGroup SWSQL48P07PA -Secondary SESTODS017.sweco.se\SWSQL48P -SeedingMode Manual
