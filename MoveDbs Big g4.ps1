############################################################################################################
# First restore before mw
$credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
$params = @{
    SqlInstance = "coreprod.sql.sweco.se"
    Database = "BudgetTool", "swecoatwork", "SwecoLog", "SwecoApi", "ocrawork", "ReorgOps", "SwecoIntranetEPIiServerCommunity", "tre"
}
$BackupInformation = Get-DbaDbBackupHistory @params
$BackupInformation | Export-CliXml -Path c:\Temp\CoreprodMove\BackupInformation_1_g4.xml
# Primary node
$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery -SqlCredential $credPrimary -TrustDbBackupHistory
# Secondary node
$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -NoRecovery -SqlCredential $credSecondary -TrustDbBackupHistory

############################################################################################################
# Then restore just before mw and the last restore within the mw

$BackupInformation = Get-DbaBackupInformation -Import -Path c:\Temp\CoreprodMove\BackupInformation_1_g4.xml
$LastScanTime = (Get-Item c:\Temp\CoreprodMove\BackupInformation_1_g4.xml).LastWriteTime

$database = get-DbaDatabase -SqlInstance coreprod.sql.sweco.se -Database BudgetTool, swecoatwork, SwecoLog, SwecoApi, ocrawork, ReorgOps, SwecoIntranetEPIiServerCommunity, tre
$params = @{
    SqlInstance = "coreprod.sq.sweco.se"
    Database = $database
}
$BackupInformationNew = get-DbaDbBackupHistory -SqlInstance coreprod.sql.sweco.se -Database BudgetTool, swecoatwork, SwecoLog, SwecoApi, ocrawork, ReorgOps, SwecoIntranetEPIiServerCommunity, tre -since $LastScanTime -IgnoreDiffBackup
$BackupInformationNew | Export-Clixml -Path c:\Temp\CoreprodMove\BackupInformation_1_g4.xml
# primary node
$BackupInformationNew | Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery -Continue -TrustDbBackupHistory
# secondary node
$BackupInformationNew | Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -NoRecovery -Continue -TrustDbBackupHistory

############################################################################################################
# When restore is done, move the databases recover the databases on primary

$params = @{
    SqlInstance = "SESTODS072.sweco.se\SWSQL06PC"
    Database = "BudgetTool", "swecoatwork", "SwecoLog", "SwecoApi", "ocrawork", "ReorgOps", "SwecoIntranetEPIiServerCommunity", "tre"
    Recover = $true
}
Restore-DbaDatabase @params

############################################################################################################
# Add database to AG

$params = @{
    SqlInstance = "SESTODS072.sweco.se\SWSQL06PC"
    AvailabilityGroup = "SWSQL06PA"
    Database = "BudgetTool", "swecoatwork", "SwecoLog", "SwecoApi", "ocrawork", "ReorgOps", "SwecoIntranetEPIiServerCommunity", "tre"
    Secondary = "SESTODS073.sweco.se\SWSQL06PC"
    SeedingMode = "Manual"
    }
Add-DbaAgDatabase @splat
