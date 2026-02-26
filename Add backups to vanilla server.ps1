
#########################################
# Settings

#Put the correct servicea account or user account also group managed service accounts works. Add a $ at the end No domain just the account.
$SvcAccount = "SESTOAS888$"

#Specify the group to att the mameber to. Don't use domain, just the group name.
$SvcGroup = "SW-SQL-BkpShareException"

SELLADS001.sweco.se\SESQL12P
$Computer = "GBMAHAS002"
$instance = "PLANASSESSOR6"
$SqlInstance = "$Computer\$instance"
#########################################
# The code to do the settings
#Adds the account to the user group
Add-ADGroupMember -Identity $SvcGroup -Members $SvcAccount

#Get group members
Get-ADGroupMember -Identity $SvcGroup | Select-Object name

Get-DbaService -ComputerName $Computer

$History = Get-DbaDbBackupHistory -SqlInstance $SqlInstance -IncludeCopyOnly -ExcludeDatabase model
$History | get-member

$filterDate = [datetime]::Today.AddDays(-30)
$History | Where-Object {$_.Start -ge $filterDate.Date} | Select-Object -Property Database, ComputerName, UserName, RecoveryModel, IsCopyOnly, Path, BackupSetId, Start | Format-Table

#Installs with a settings dialog that will be populated with default pathes.

$Params = @{
    Server = $Computer
    Instance = $instance
}
Install-SwMaintenance @Params

Get-DbaDatabase -SqlInstance $SqlInstance | Select-Object SqlInstance, Name, Status, RecoveryModel, LastFullBackup, LastDiffBackup, LastLogBackup, CreateDate | format-table
