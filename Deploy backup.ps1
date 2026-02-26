start-sleep ((get-date "20:00:13") - (get-date)).TotalSeconds

write-host "$(get-date) - Starting backup deployment script"


$Sql = @"
    EXECUTE [dbo].[DatabaseBackup]
    @Databases = 'FebDok_NelfoReg,FebDok_UserReg',
    @Directory = N'\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups',
    @BackupType = 'FULL',
    @Verify = 'N',
    @CleanupTime = 65,
    @CheckSum = 'Y',
    @LogToTable = 'Y',
    @CopyOnly = 'Y'
"@
Invoke-DbaQuery -SqlInstance SESTODS071.sweco.se\SWSQL45P -Database maintenance -Query $Sql
Invoke-DbaQuery -SqlInstance SESTODS071.sweco.se\SWSQL46P -Database maintenance -Query $Sql
Invoke-DbaQuery -SqlInstance SESTODS071.sweco.se\SWSQL47P -Database maintenance -Query $Sql



