
#Create application user
$Logins = "SWECO\svc_budgettool"
$SqlInstance = "coretest1.sql.sweco.se", "coretest2.sql.sweco.se", "coredev.sql.sweco.se"
New-DbaLogin -SqlInstance $SqlInstance -Login $Logins 

#Settings
$Logins = "SWECO\SW-Role-Analytics-TEST-SQL-Read", "SWECO\SW-Role-Analytics-TEST-SQL-Read-Finance", "SWECO\SW-Role-Analytics-TEST-SQL-Read-HR", `
"SWECO\SW-Role-Analytics-TEST-SQL-Write", "SWECO\SW-Role-Analytics-TEST-SQL-Write-Finance", "SWECO\SW-Role-Analytics-TEST-SQL-Write-HR", "SWECO\SW-Role-Analytics-TEST-SQL-Dev"
$SqlInstance = "coretest1.sql.sweco.se", "coretest2.sql.sweco.se", "coredev.sql.sweco.se"
$Database = "BudgetTool"

#Create group logins
New-DbaLogin -SqlInstance $SqlInstance -Login $Logins 

#Creat users in db
foreach ($Login in $Logins) {
    Write-Host "Creating user $Login in $Database "
    New-DbaDbUser -SqlInstance $SqlInstance -Database $Database -Login $Login
}

#Add members to dev group
$members = "sembod", "sellsl", "SEENKR"
$group = "SW-Role-Analytics-TEST-SQL-Dev"
Add-ADGroupMember -Identity $group -Members $members
#Verify
Get-ADGroupMember -Identity $group | Format-Table name


$Role = "db_owner"
$Login = "SWECO\$group"

Add-DbaDbRoleMember -SqlInstance $SqlInstance -Role $Role  -User $Login -Database $Database -Confirm:$false

Get-DbaDbUser -SqlInstance $SqlInstance -Database $Database -User $Login 
Get-DbaDbRoleMember -SqlInstance $SqlInstance -Database $Database -Role $Role 
