$Login = "Staging_Integration"
$SqlInstance = "coreprod.sql.sweco.se", "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
$Database = "staging"
$Role = "db_datareader", "db_datawriter"

New-DbaLogin -SqlInstance $SqlInstance -Login $Login 

New-DbaDbUser -SqlInstance $SqlInstance -Database $Database -Login $Login

Add-DbaDbRoleMember -SqlInstance $SqlInstance -Role $Role  -User $Login -Database $Database -Confirm:$false

Get-DbaDbUser -SqlInstance $SqlInstance -Database $Database -User $Login 
Get-DbaDbRoleMember -SqlInstance $SqlInstance -Database $Database -Role $Role 

