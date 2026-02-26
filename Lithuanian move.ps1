Restore-DbaDatabase -SqlInstance LTKUNDS003.sweco.se\LTSQL14P -path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\LTKUNDS002$LTSQL10P\KeyLAB' -NoRecovery -MaintenanceSolutionBackup
Restore-DbaDatabase -SqlInstance LTKUNDS003.sweco.se\LTSQL14P -path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\LTKUNDS002$LTSQL10P\Sw18' -NoRecovery -MaintenanceSolutionBackup

get-dbalogin -SqlInstance LTKUNDS002.sweco.se\LTSQL10P | Out-GridView -PassThru | New-DbaLogin -SqlInstance LTKUNDS003.sweco.se\LTSQL14P

Restore-DbaDatabase -SqlInstance LTKUNDS003.sweco.se\LTSQL14P -Database KeyLAB -Recover
Restore-DbaDatabase -SqlInstance LTKUNDS003.sweco.se\LTSQL14P -Database Sw18 -Recover

Add-SwNetworkCertificate -FQDN LTKUNDS003.sweco.se -Instance LTSQL14P -UseInstanceAsAlias -Aliases LTSQL10P.sql.sweco.se -RestartInstance
