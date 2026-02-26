
function move-swdatabases {
    param (
        [parameter(ParameterSetName = 'Prepare')]
        [switch]$stepPrepare,

        [parameter(ParameterSetName = 'Continue')]
        [switch]$stepContinue,

        [parameter(ParameterSetName = 'Finalize')]
        [switch]$stepFinalize,

        [parameter(ParameterSetName = 'AG')]
        [switch]$stepAG,

        [parameter(ParameterSetName = 'Prepare')]
        [parameter(ParameterSetName = 'Continue')]
        [string]$SourceSqlInstance,

        [parameter(ParameterSetName = 'Prepare')]
        [parameter(ParameterSetName = 'Continue')]
        [parameter(ParameterSetName = 'Finalize')]
        [string]$PrimaryNode,

        [parameter(ParameterSetName = 'Prepare')]
        [parameter(ParameterSetName = 'Continue')]
        [parameter(ParameterSetName = 'Finalize')]
        [parameter(ParameterSetName = 'AG')]
        [string]$SecondaryNode,

        [parameter(ParameterSetName = 'Prepare')]
        [parameter(ParameterSetName = 'Continue')]
        [parameter(ParameterSetName = 'Finalize')]
        [parameter(ParameterSetName = 'AG')]
        [object[]]$Databases,

        [parameter(ParameterSetName = 'AG')]
        [string]$AvailabilityGroup,

        [parameter(ParameterSetName = 'Prepare')]
        [parameter(ParameterSetName = 'Continue')]
        [parameter(ParameterSetName = 'Finalize')]
        [string]$WorkGroup
    )

    ############################################################################################################
    # Do first restore of the databases
    if ($stepPrepare) {
        $startTime = Get-Date
        $credPrimary = Get-Credential -Message "Enter the sa password for the primary target" -UserName sa
        $credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
        ###

        $BackupInformation = Get-DbaDbBackupHistory -SqlInstance $SourceSqlInstance -Database $Databases

        $endTime = Get-Date
        $elapsedTime = $endTime - $startTime
        Write-Output "Total Elapsed Time: $($elapsedTime.TotalSeconds) seconds" -ForegroundColor Cyan
        ###
        $BackupInformation | Export-CliXml -Path "c:\Temp\CoreprodMove\BackupInformation_$WorkGroup.xml"

        $endTime = Get-Date
        $elapsedTime = $endTime - $startTime
        Write-Output "Total Elapsed Time: $($elapsedTime.TotalSeconds) seconds" -ForegroundColor Cyan
        ###
        # Primary node
        $BackupInformation | Restore-DbaDatabase -SqlInstance $PrimaryNode -NoRecovery -SqlCredential $credPrimary -TrustDbBackupHistory
        $endTime = Get-Date
        $elapsedTime = $endTime - $startTime
        Write-Output "Total Elapsed Time: $($elapsedTime.TotalSeconds) seconds" -ForegroundColor Cyan
        ###
        # Secondary node
        $BackupInformation | Restore-DbaDatabase -SqlInstance $SecondaryNode -NoRecovery -SqlCredential $credSecondary -TrustDbBackupHistory

        $endTime = Get-Date
        $elapsedTime = $endTime - $startTime
        Write-output "Total Elapsed Time: $($elapsedTime.TotalSeconds) seconds" -ForegroundColor Cyan
    }
    if ($stepContinue) {
        ############################################################################################################
        # Then restore just before mw and the last restore within the mw

        #$WorkGroup = "G5"
        $BackupInformation = Get-DbaBackupInformation -Import -Path "c:\Temp\CoreprodMove\BackupInformation_$WorkGroup.xml"
        $LastScanTime = (Get-Item "c:\Temp\CoreprodMove\BackupInformation_$WorkGroup.xml").LastWriteTime



        $BackupInformationNew = get-DbaDbBackupHistory  -SqlInstance $SourceSqlInstance -Database $Databases -since $LastScanTime -IgnoreDiffBackup
        #$BackupInformationNew = get-DbaDbBackupHistory  -SqlInstance coreprod.sql.sweco.se -Database ProjectFolder, HRSweden -since $LastScanTime -IgnoreDiffBackup
        $BackupInformationNew | Export-Clixml -Path "c:\Temp\CoreprodMove\BackupInformation_$WorkGroup.xml"
        # primary node
        $BackupInformationNew | Restore-DbaDatabase -SqlInstance SESTODS072.sweco.se\SWSQL06PC -NoRecovery -Continue -TrustDbBackupHistory
        # secondary node
        $BackupInformationNew | Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -NoRecovery -Continue -TrustDbBackupHistory

    }
}


move-swdatabases -stepPrepare -SourceSqlInstance "coreprod.sql.sweco.se" -PrimaryNode "SESTODS072.sweco.se\SWSQL06PC" -SecondaryNode "SESTODS073.sweco.se\SWSQL06PC" -Databases ProjectFolder, HRSweden -WorkGroup "G5"
move-swdatabases -stepContinue -SourceSqlInstance "coreprod.sq.sweco.se" -PrimaryNode "SESTODS072.sweco.se\SWSQL06PC" -SecondaryNode "SESTODS073.sweco.se\SWSQL06PC" -Databases ProjectFolder, HRSweden -WorkGroup "G5" 

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
