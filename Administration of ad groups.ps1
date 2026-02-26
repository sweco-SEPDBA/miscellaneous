#Administration of ad groups
Add-ADGroupMember -Identity SW-Role-MaconomyTEST_SQL-Read -Members SEWJAO_DA
Add-ADGroupMember -Identity SW-SQL-AgentSVCAcct -Members svc_sql_sestods016
Get-ADGroupMember -Identity SW-SQL-AgentSVCAcct | Format-Table

Get-ADGroupMember -Identity SW-Role-Maconomy_SQLAdmin | Format-Table
Add-ADGroupMember -Identity SW-Role-Maconomy_SQLAdmin -Members svc_integ_001
Get-ADGroupMember -Identity SW-Role-MaconomyTEST_SQL-Read | Format-Table
Get-ADGroupMember -Identity SW-Role-MaconomyTEST_SQL-INTEGRATION | Format-Table
Get-ADGroupMember -Identity SW-Role-MaconomyTEST_SQL-Dev | Format-Table
Add-ADGroupMember -Identity SW-Role-MaconomyTEST_SQL-Dev -Members svc_integ_001
Get-AdGroupMember -Identity SW-Role-MaconomyPROD_SQL-Read | Format-Table
Get-ADGroupMember -Identity SW-Role-MaconomyPROD_SQL-Dev | Format-Table
Add-ADGroupMember -Identity SW-Role-MaconomyPROD_SQL-Dev -Members svc_integ_001
Get-ADGroupMember -Identity SW-Role-PeoplePlanner_SQLAdmin | Format-Table

Get-ADGroupMember -Identity SW-SQL-AgentSVCAcct | Format-Table distinguishedName, name, objectClass


Get-AdUser -Filter "(GivenName -like '*Pär*') -and (SurName -like 'Eriksson')" | Select-Object GivenName, SurName, SamAccountName, UserPrincipalName

svc_integ_001
sweco-integration

Copy-DbaDatabase -Source nlsql13p.sql.sweco.se -Destination nlsql13p.sql.sweco.se -Database 902 -backuprestore -uselastbackup -newname 213 
Copy-DbaDatabase -Source SEMMADS001\SEMMADS001 -Destination SEMMADS002\SESQL39P -Database impact_16 -backuprestore -uselastbackup 
Copy-DbaDatabase -Source SEMMADS001\SEMMADS001 -Destination SEMMADS002\SESQL39P -Database impact_15 -backuprestore -uselastbackup 

Get-DbaDbOrphanUser  -sqlinstance swsql29p.sql.sweco.se -Database impact_16 | Format-Table

repair-dbadborphanuser -SqlInstance sestods052\swsql29p -Database impact_16 -RemoveNotExisting 
copy-dbalogin -source eetllds002 -destination eetllds003\eesql33p -login sweco 
copy-dbalogin -source SEMMADS001\SEMMADS001 -destination SEMMADS002\SESQL39P -login impactservice 



copy-dbalogin -Source SESTODS950\SWERP04PC -Destination SESTODS964\SWERP16T -Login samaconomy


Resolve-DnsName sestods051

$ServerName = 'SESTODS061.sweco.se'
$InstanceName = 'SESQL13T'
$ServiceAccountCredentials = Get-Credential
New-DbaLogin -SqlInstance "$ServerName\$InstanceName" -Login $ServiceAccountCredentials.UserName -Confirm:$false
Add-DbaServerRoleMember -SqlInstance "$ServerName\$InstanceName" -ServerRole sysadmin -Login $ServiceAccountCredentials.UserName -Confirm:$false



$session = New-PSSession -ComputerName $ServerName;
Invoke-Command -Session $session -Args $directory, $user, $permission -ScriptBlock {
    param([string]$directory,[string]$user,[string]$permission)
    $acl = Get-Acl $directory;
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($user, $permission, "ContainerInherit, ObjectInherit", "None", "Allow");
    if ($accessRule -eq $null){
        Throw "Unable to create the Access Rule giving $permission permission to $user on $directory";
    }
    $acl.AddAccessRule($accessRule)
    Set-Acl -aclobject $acl $directory
};
Remove-PSSession $session;

Set-DbaPrivilege -ComputerName SESTODS061.sweco.se -Credential $ServiceAccountCredentials -Type BatchLogon 

#Put the correct servicea account 
$SvcAccount = "ingrgds002$"

$Server = "sweco.se"
$SvcGroup = "SW-SQL-AgentSVCAcct"
$SvcGroup = "SW-SQL-BkpShareException"

$user = Get-ADUser -Filter { name -like $SvcAccount} -Server $Server;
$group = Get-ADGroup -Filter { name -like $SvcGroup } -Server $Server;

Add-ADGroupMember -Identity $group -Members $user -Server $Server; 

Add-ADGroupMember -Identity $SvcGroup -Members $SvcAccount
Get-ADGroupMember -Identity $SvcGroup | Select-Object name 

SW-Role-HMS-PROD-SQL-Dev to SEOLST_BD
$SvcAccount = "SEOLST_BD"

$Server = "sweco.se"
$SvcGroup = "SW-Role-RaetHR-PROD-SQL-Read"
$SvcGroup = "SW-Role-TEM-PROD-SQL-Read"
$SvcGroup = "SW-Role-TIME-PROD-SQL-Read"
$SvcGroup = "SW-Role-HMS-PROD-SQL-Dev"

Add-ADGroupMember -Identity $SvcGroup -Members $SvcAccount
Get-ADGroupMember -Identity $SvcGroup | Select-Object name 



