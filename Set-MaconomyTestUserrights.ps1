[cmdletbinding()]
Param (
    [Parameter(mandatory)] [string]$SqlInstance,
    [Parameter(mandatory)] [string]$Database
)

#Assignments
$logins = "SWECO\SW-Role-MaconomyTEST_SQL-Dev","SWECO\SW-Role-Maconomy_SQL-Integration", "SWECO\SW-Role-MaconomyTEST_SQL-Read"

#Create login
$Params = @{
"SqlInstance" = $SqlInstance
"Login" = $logins
}
New-DbaLogin @Params

#Create user
foreach ($login in $logins) {
    $Params = @{
    "SqlInstance" = $SqlInstance
    "Login" = $login
    "Database" = $Database
    }
    New-DbaDbUser @Params
}

#Assign role membership datareader
$Role = "db_datareader"
$Params = @{
"SqlInstance" = $SqlInstance
"User" = $logins
"Database" = $Database
"Role" = $Role
"confirm" = $false
}
Add-DbaDbRoleMember @Params


#Assign role membership data writer
$login = "SWECO\SW-Role-MaconomyTEST_SQL-Dev"
$Role = "db_datawriter"

$Params = @{
"SqlInstance" = $SqlInstance
"User" = $login
"Database" = $Database
"Role" = $Role
"confirm" = $false
}
Add-DbaDbRoleMember @Params


#assign View definition
$sql = @" 
GRANT VIEW DEFINITION TO [$Login]
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $sql

#Remove orphan users
Repair-DbaDbOrphanUser -SqlInstance $SqlInstance -Database $Database -RemoveNotExisting 
