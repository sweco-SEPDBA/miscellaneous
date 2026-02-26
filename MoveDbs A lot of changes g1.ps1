############################################################################################################
# First restore before mw
$credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
$startTime = Get-Date
$params = @{
    SqlInstance = "coreprod.sql.sweco.se"
    Database = "staging"
}
$BackupInformation = Get-DbaDbBackupHistory @params
$BackupInformation | Export-CliXml -Path c:\Temp\CoreprodMove\BackupInformation_1_g1.xml
# Primary node
$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery -SqlCredential $credPrimary -TrustDbBackupHistory
# Secondary node
$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -NoRecovery -SqlCredential $credSecondary -TrustDbBackupHistory

############################################################################################################
# Then restore just before mw and the last restore within the mw

$BackupInformation = Get-DbaBackupInformation -Import -Path c:\Temp\CoreprodMove\BackupInformation_1_g1.xml
$LastScanTime = (Get-Item c:\Temp\CoreprodMove\BackupInformation_1_g1.xml).LastWriteTime
$params = @{
    SqlInstance = "coreprod.sq.sweco.se"
    Database = "staging"
}
$BackupInformationNew = get-DbaDbBackupHistory @params -since $LastScanTime -IgnoreDiffBackup
$BackupInformationNew | Export-Clixml -Path c:\Temp\CoreprodMove\BackupInformation_2_g1.xml
# primary node
$BackupInformationNew | Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery -Continue -TrustDbBackupHistory
# secondary node
$BackupInformationNew | Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -NoRecovery -Continue -TrustDbBackupHistory

############################################################################################################
# When restore is done, move the databases recover the databases on primary

$params = @{
    SqlInstance = "SESTODS072.sweco.se\SWSQL06PC"
    Database = "staging"
    Recover = $true
}
Restore-DbaDatabase @params

############################################################################################################
# Add database to AG

$params = @{
    SqlInstance = "SESTODS072.sweco.se\SWSQL06PC"
    AvailabilityGroup = 'SWSQL06PA'
    Database = 'staging'
    Secondary = "SESTODS073.sweco.se\SWSQL06PC"
    SeedingMode = 'Manual'
    }
Add-DbaAgDatabase @splat
