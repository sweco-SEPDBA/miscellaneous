[cmdletbinding()]
Param (
    [Parameter(mandatory)] [string]$SqlInstance,
    [Parameter(mandatory)] [string]$DatabaseMaconomy
)

#Assignments
$DatabaseIntegration = "integration"
$DatabaseMacstaging = "macstaging"
$login = "SWECO\SW-Role-Maconomy_SQL-Integration"

#Create login
$Params = @{
"SqlInstance" = $SqlInstance
"Login" = $login
}
New-DbaLogin @Params

#Create user
$Params = @{
"SqlInstance" = $SqlInstance
"Login" = $login
"Database" = @($DatabaseIntegration, $DatabaseMacstaging, $DatabaseMaconomy)
}
New-DbaDbUser @Params


#Assign role membership datareader
$Role = "db_datareader"
$Params = @{
    "SqlInstance" = $SqlInstance
    "User" = $login
    "Database" = @($DatabaseIntegration, $DatabaseMacstaging, $DatabaseMaconomy)
    "Role" = $Role
    "confirm" = $false
}
Add-DbaDbRoleMember @Params


#Assign role membership datawriter
$Role = "db_datawriter"
$Params = @{
    "SqlInstance" = $SqlInstance
    "User" = $login
    "Database" = @($DatabaseIntegration, $DatabaseMacstaging)
    "Role" = $Role
    "confirm" = $false
}
Add-DbaDbRoleMember @Params

#Assign role membership DDL_Admin
$Role = "ddl_admin"
$Params = @{
    "SqlInstance" = $SqlInstance
    "User" = $login
    "Database" = @($DatabaseIntegration, $DatabaseMacstaging)
    "Role" = $Role
    "confirm" = $false
}
Add-DbaDbRoleMember @Params

#assign View definition
$sql = @" 
GRANT VIEW DEFINITION TO [$Login]
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $DatabaseIntegration -Query $sql
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $DatabaseMacstaging -Query $sql
