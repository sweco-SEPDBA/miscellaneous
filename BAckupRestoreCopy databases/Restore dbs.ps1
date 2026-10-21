
Copy-DbaDatabase -Source coretest2.sql.sweco.se -Destination SESTODS085.sweco.se\SWSQL28T -UseLastBackup -BackupRestore -NoRecovery -AllDatabases

Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\AdventureWorks2017' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\bi' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\bianalytics' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\BudgetTool' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\Cardpresso' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\contact' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\frameworkagreement' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\globalsoftwareusage' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\hrcore' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\hrsweden' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\internalaudit' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ir' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\MaconomyIntegration' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ocra14' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ocrawork' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\projectfolder' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ramavtal' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ReorgOps' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\signature' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\sots' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\staging' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecoaccess' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecoarkiv' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecoatwork' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecocore' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecocoreexpo' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecolog' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecotranslation' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\telenor' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\tre' -NoRecovery -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\webbeko' -NoRecovery -Continue

Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\AdventureWorks2017' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\bi' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\bianalytics' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\BudgetTool' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\Cardpresso' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\contact' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\frameworkagreement' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\globalsoftwareusage' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\hrcore' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\hrsweden' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\internalaudit' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ir' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\MaconomyIntegration' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ocra14' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ocrawork' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\projectfolder' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ramavtal' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\ReorgOps' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\signature' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\sots' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\staging' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecoaccess' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecoarkiv' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecoatwork' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecocore' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecocoreexpo' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecolog' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\swecotranslation' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\telenor' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\tre' -Continue
Restore-DbaDatabase -SqlInstance SESTODS085.sweco.se\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS050$SWSQL02D\webbeko' -Continue

Copy-DbaLogin -Source SESTODS050.sweco.se\SWSQL02D -Destination SESTODS085.sweco.se\SWSQL28T 

Copy-DbaDatabase -Source SESTODS111.sweco.se\SESCCM02P -Destination SESTODS086.sweco.se\SWSQL51P -UseLastBackup -BackupRestore -Database UTS_MDT -SetSourceReadOnly

Restore-DbaDatabase -SqlInstance fisql18p.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLFI\FIHELDS013$FISQL16P\PISAdb' 
Restore-DbaDatabase -SqlInstance fisql18p.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLFI\FIHELDS013$FISQL16P\PISAdbDebug' 
Restore-DbaDatabase -SqlInstance fisql18p.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLFI\FIHELDS013$FISQL16P\PISAdbOrginal' 
Restore-DbaDatabase -SqlInstance fisql18p.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLFI\FIHELDS013$FISQL16P\PISAdbTypical' 

Get-DbaLogin -SqlInstance SESTODS017.sweco.se\SWSQL48P | Out-GridView -Passthru | Grant-DbaAgPermission -Type EndPoint

$Listener = 'SWSQL48P01PL.sweco.se'
get-dbaagreplica -SqlInstance $Listener | Select-Object Name, Role -Unique | Out-GridView -Passthru  | 
ForEach-Object {Get-DbaAgReplica -SqlInstance $_.Name -Replica $_.Name} | Out-GridView -Passthru  | 
ForEach-Object {Get-DbaAvailabilityGroup -AvailabilityGroup $_.AvailabilityGroup -SqlInstance $_.Name} | 
Invoke-DbaAgFailover -Confirm:$false

$cred = Get-Credential -Credential sa
Get-ChildItem '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS009$SWSQL13D' -Exclude ("master", "model", "maintenance", "msdb", "tempdb") | 
Restore-DbaDatabase -SqlInstance sestods084.sweco.se\swsql29t -MaintenanceSolutionBackup -NoRecovery -SqlCredential $cred

$cred = Get-Credential -Credential sa
Get-ChildItem '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS009$SWSQL13D' -Exclude ("master", "model", "maintenance", "msdb", "tempdb") | 
Restore-DbaDatabase -SqlInstance sestods084.sweco.se\swsql29t -MaintenanceSolutionBackup -SqlCredential $cred -Continue

Install-SwServerInstance -FQDN SESTODS088.sweco.se

$cred = Get-Credential -Credential sa
COPY-DbaDatabase -Source SESTODS036.sweco.se\SWSQL02PC -Destination SESTODS017.sweco.se\SWSQL48P -UseLastBackup -BackupRestore -Database pw_arc_CE280 -NewName pw_arc_2023 -DestinationSqlCredential $cred

COPY-DbaDatabase -Source SESTODS036.sweco.se\SWSQL02PC -Destination SESTODS017.sweco.se\SWSQL48P -UseLastBackup -BackupRestore -Database pw_FI-IN_CED -NewName pw_FI-IN_2023

$params = @{
    SqlInstance = "SESTODS085.sweco.se\swsql28t"
    DatabaseName = "bi"
    Recover = $true
}
Restore-DbaDatabase @params


Resolve-DnsName -Name SwecoAppsProd.sql.sweco.se



$cred = Get-Credential -Credential sa
COPY-DbaDatabase -Source NLAMSDS018.sweco.se\BESQL01P -Destination NLAMSDS023.sweco.se\NLSQL13T -UseLastBackup -BackupRestore -Database PMOPRO -NewName PMOPRO_PreProd -DestinationSqlCredential $cred
COPY-DbaDatabase -Source NLAMSDS018.sweco.se\BESQL01P -Destination NLAMSDS023.sweco.se\NLSQL13T -UseLastBackup -BackupRestore -Database PMOPRO -NewName PMOPRO_Dev -DestinationSqlCredential $cred

