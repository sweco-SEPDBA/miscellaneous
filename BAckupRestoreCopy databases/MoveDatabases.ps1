# Check instance level settings if anything needs to be moved
# Agent jobs
# Linked servers
# Replication
# Log shipping
# Proxy account
# Logins is also instance level but it's for sure, you need to copy them
# Verify that all databases is in full recovery mode
# Can any database be shrinked?
# Is there any databases on the source that doesn't need to be copied?
# Restore with no recovery the day before
# Right before mw do a diff backup or a restore with no recovery continue
# Right before mw copy all logins
# In mw close all connections
# In mw do a tail backup
# Restore with no recovery continue
# Push compatibility level



#First Scan:
$cred = Get-Credential -Credential sa
$BackupInformation = Get-DbaDbBackupHistory -SqlInstance sestods009.sweco.se\swsql25t -ExcludeDatabase master, model, maintenance, msdb, tempdb -Last
$BackupInformation | Export-CliXml -Path c:\Temp\BackupInformation_coretest1.xml
$BackupInformation | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -SqlCredential $cred -TrustDbBackupHistory

$FileStructure = @{
    'TravelExpense' = 'E:\SQLData\SWSQL30T\travelexpense_prodtest.mdf'
    'TravelExpense_log' = 'F:\SQLLog\SWSQL30T\travelexpense_prodtest_log.ldf'
}
$BackupInformation | Where-Object {$_.Database -eq 'travelexpense_prodtest'} | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -SqlCredential $cred -TrustDbBackupHistory -FileMapping $FileStructure

$FileStructure = @{
    'TravelExpense' = 'E:\SQLData\SWSQL30T\travelexpense_sutrain.mdf'
    'TravelExpense_log' = 'F:\SQLLog\SWSQL30T\travelexpense_sutrain_log.ldf'
}
$BackupInformation | Where-Object {$_.Database -eq 'travelexpense_sutrain'} | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -SqlCredential $cred -TrustDbBackupHistory -FileMapping $FileStructure

$FileStructure = @{
    'TravelExpense' = 'E:\SQLData\SWSQL30T\travelexpense_training.mdf'
    'TravelExpense_log' = 'F:\SQLLog\SWSQL30T\travelexpense_training_log.ldf'
}
$BackupInformation | Where-Object {$_.Database -eq 'travelexpense_training'} | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -SqlCredential $cred -TrustDbBackupHistory -FileMapping $FileStructure

$BackupInformation | Where-Object {$_.Database -eq 'tre'} | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -SqlCredential $cred -TrustDbBackupHistory -FileMapping $FileStructure
$BackupInformation | Where-Object {$_.Database -eq 'tre_sandbox'} | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -SqlCredential $cred -TrustDbBackupHistory -FileMapping $FileStructure
$BackupInformation | Where-Object {$_.Database -eq 'webbeko'} | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -SqlCredential $cred -TrustDbBackupHistory -FileMapping $FileStructure
$BackupInformation | Where-Object {$_.Database -eq 'webbeko_copy'} | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -SqlCredential $cred -TrustDbBackupHistory -FileMapping $FileStructure
$BackupInformation | Where-Object {$_.Database -eq 'VendorInvoices'} | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -SqlCredential $cred -TrustDbBackupHistory -FileMapping $FileStructure

#Some time later:
$BackupInformation = Get-DbaBackupInformation -Import -Path c:\Temp\BackupInformation_coretest1.xml
$LastScanTime = (Get-Item c:\Temp\BackupInformation.xml).LastWriteTime
$BackupInformationNew = get-DbaDbBackupHistory -SqlInstance sestods009.sweco.se\swsql25t -ExcludeDatabase master, model, maintenance, msdb, tempdb -since $LastScanTime -IgnoreDiffBackup
$BackupInformationNew | Export-Clixml -Path c:\Temp\BackupInformation_coretest1.xml
$BackupInformationNew | Restore-DbaDatabase -SqlInstance sestods087.sweco.se\swsql30t -NoRecovery -Continue -TrustDbBackupHistory

# copy logins

Copy-DbaLogin -Source sestods009.sweco.se\swsql25t -Destination sestods087.sweco.se\swsql30t 

# Copy jobs

Copy-DbaAgentJob -Source sestods009.sweco.se\swsql25t -Destination sestods087.sweco.se\swsql30t -Job 'ObjectChanges-BiAnalytics'

#Recover the databases
$params = @{
    SqlInstance = "sestods087.sweco.se\swsql30t"
    Database = "BI", "BIanalytics", "BudgetTool", "BusinessPartnerAssessment", "CashM", "cfa", "contact", "GlobalSoftwareUsage", "ocrawork", "HRCore", "HRSweden", "InternalAudit_Copy", "IR_Copy", "MaconomyIntegration", "messagehandler", "metroeko", "repli_Test"
    Recover = $true
}
Restore-DbaDatabase @params

$params = @{
    SqlInstance = "sestods087.sweco.se\swsql30t"
    Database = "TravelExpense", "ocra14", "SwecoLog", "tre_sandbox", "ProjectMember", "ramavtal", "tre", "RuleEngineDB", "signature", "sots", "MDMService", "SustainabilitySun", "swecoaccess_Copy", "BidApprovalService", "VendorInvoices", "ReorgOps", "swecoatwork_Copy", "O365Service", "ProjectWiseService"
    Recover = $true
}
Restore-DbaDatabase @params

$params = @{
    SqlInstance = "sestods087.sweco.se\swsql30t"
    Database = "swecocoreexpo", "SwecoIntranetEpiServer", "SwecoIntranetEpiServer_Copy", "SwecoIntranetEpiServerCommunity", "SwecoIntranetEpiServerCommunity_Copy", "SwecoIntranetEpiServerStaging", "SwecoIntranetEpiServerStaging_Copy", "SwecoLog", "SwecoJob", "swecotranslation", "Telenor"
    Recover = $true
}
Restore-DbaDatabase @params

$params = @{
    SqlInstance = "sestods087.sweco.se\swsql30t"
    Database = "SwecoIntranetStaging_Copy", "travelexpense_prodtest", "travelexpense_sutrain", "travelexpense_training", "InternalAudit", "IR", "webbeko_Copy", "Cardpresso", "swecoaccess_25thJanuary", "ProjectWorkspace", "RaetHR", "TIME", "RaetToCore", "MaartrondeDWH", "MaartrondeDWH_Meta", "MaartrondeDWH_STG"
    Recover = $true
}
Restore-DbaDatabase @params

$params = @{
    SqlInstance = "sestods087.sweco.se\swsql30t"
    Database = "TEM", "TelephonyNL", "SwecoApplications", "SwecoGpt", "MigrationAdmin", "RaetJournals", "ProjectLinkService", "ProjectModel", "SwecoIntranetEpiServer", "SwecoIntranetStaging", "SwecoApi", "RiskAssessment", "Swecoarkiv", "swecoatwork", "projectfolder", "webbeko", "FrameworkAgreement", "Staging", "swecoaccess", "swecocore"
    Recover = $true
}
Restore-DbaDatabase @params

