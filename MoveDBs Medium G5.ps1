############################################################################################################
# First restore before mw
$startTime = Get-Date
$credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
###
$params = @{
    SqlInstance = "coreprod.sql.sweco.se"
    Database = "ProjectFolder", "HRSweden", "swecocoreexpo", "SwecoIntranetStaging", "ProjectMember", "ProjectWorkpace", "SwecoIntranetEPiServer", "BI", "Telenor", "TIME", "vRDDb2015", "Tellus", "RaetHR", "RaetJournals", "MaartroendeDWH", "MaartroendeDWH_Meta", "MaartroendeDWH_STG"
    #Database = "ProjectFolder", "HRSweden", "swecocoreexpo", "SwecoIntranetStaging", "ProjectMember", "ProjectWorkpace", "SwecoIntranetEPiServer", "BI", "Telenor", "TIME", "vRDDb2015", "Tellus", "RaetHR", "RaetJournals", "MaartroendeDWH", "MaartroendeDWH_Meta", "MaartroendeDWH_STG"
}
$BackupInformation = Get-DbaDbBackupHistory @params

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Output "Total Elapsed Time: $($elapsedTime.TotalSeconds) seconds" -ForegroundColor Cyan
###
$BackupInformation | Export-CliXml -Path c:\Temp\CoreprodMove\BackupInformation_1_g5.xml

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Output "Total Elapsed Time: $($elapsedTime.TotalSeconds) seconds" -ForegroundColor Cyan
###
# Primary node
$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery -SqlCredential $credPrimary -TrustDbBackupHistory
YWMdbOQogYrEs6dkelGr
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Output "Total Elapsed Time: $($elapsedTime.TotalSeconds) seconds" -ForegroundColor Cyan
###
# Secondary node
$BackupInformation | Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -NoRecovery -SqlCredential $credSecondary -TrustDbBackupHistory

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Output "Total Elapsed Time: $($elapsedTime.TotalSeconds) seconds" -ForegroundColor Cyan

############################################################################################################
# Then restore just before mw and the last restore within the mw

$BackupInformation = Get-DbaBackupInformation -Import -Path c:\Temp\CoreprodMove\BackupInformation_1_g5.xml
$LastScanTime = (Get-Item c:\Temp\CoreprodMove\BackupInformation_1_g5.xml).LastWriteTime
$params = @{
    SqlInstance = "coreprod.sq.sweco.se"
    Database = "ProjectFolder", "HRSweden", "swecocoreexpo", "SwecoIntranetStaging", "ProjectMember", "ProjectWorkpace", "SwecoIntranetEPiServer", "BI", "Telenor", "TIME", "vRDDb2015", "Tellus", "RaetHR", "RaetJournals", "MaartroendeDWH", "MaartroendeDWH_Meta", "MaartroendeDWH_STG"
}
$BackupInformationNew = get-DbaDbBackupHistory @params -since $LastScanTime -IgnoreDiffBackup
$BackupInformationNew | Export-Clixml -Path c:\Temp\CoreprodMove\BackupInformation_2_g5.xml
# primary node
$BackupInformationNew | Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery -Continue -TrustDbBackupHistory
# secondary node
$BackupInformationNew | Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -NoRecovery -Continue -TrustDbBackupHistory

############################################################################################################
# When restore is done, move the databases recover the databases on primary

$params = @{
    SqlInstance = "SESTODS072.sweco.se\SWSQL06PC"
    Database = "ProjectFolder", "HRSweden", "swecocoreexpo", "SwecoIntranetStaging", "ProjectMember", "ProjectWorkpace", "SwecoIntranetEPiServer", "BI", "Telenor", "TIME", "vRDDb2015", "Tellus", "RaetHR", "RaetJournals", "MaartroendeDWH", "MaartroendeDWH_Meta", "MaartroendeDWH_STG"
    Recover = $true
}
Restore-DbaDatabase @params

############################################################################################################
# Add database to AG

$params = @{
    SqlInstance = "SESTODS072.sweco.se\SWSQL06PC"
    AvailabilityGroup = "SWSQL06PA"
    Database = "ProjectFolder", "HRSweden", "swecocoreexpo", "SwecoIntranetStaging", "ProjectMember", "ProjectWorkpace", "SwecoIntranetEPiServer", "BI", "Telenor", "TIME", "vRDDb2015", "Tellus", "RaetHR", "RaetJournals", "MaartroendeDWH", "MaartroendeDWH_Meta", "MaartroendeDWH_STG"
    Secondary = "SESTODS073.sweco.se\SWSQL06PC"
    SeedingMode = "Manual"
    }
Add-DbaAgDatabase @splat
