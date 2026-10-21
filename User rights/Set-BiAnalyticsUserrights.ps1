[cmdletbinding()]
Param (
    [Parameter(mandatory)] [string]$SqlInstance,
    [Parameter(mandatory)] [string]$DatabaseMaconomy,
    [Parameter(mandatory)] [switch]$RevoceConnect
)

#Assignments
$DatabaseAnalytics = "BiAnalytics"
$DatabaseMacstaging = "macstaging"
$login = "SWECO\SW-Role-BiAnalytics-SQL"

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
#"Database" = @($DatabaseAnalytics, $DatabaseMacstaging, $DatabaseMaconomy)
}
New-DbaDbUser @Params -Database $DatabaseAnalytics
New-DbaDbUser @Params -Database $DatabaseMacstaging
New-DbaDbUser @Params -Database $DatabaseMaconomy


#Assign role membership datareader
$Role = "db_datareader"
$Params = @{
    "SqlInstance" = $SqlInstance
    "User" = $login
    #"Database" = @($DatabaseIntegration, $DatabaseMacstaging, $DatabaseMaconomy)
    "Role" = $Role
    "confirm" = $false
}
Add-DbaDbRoleMember @Params -Database $DatabaseAnalytics
Add-DbaDbRoleMember @Params -Database $DatabaseMacstaging
Add-DbaDbRoleMember @Params -Database $DatabaseMaconomy


#Assign role membership datawriter
$Role = "db_datawriter"
$Params = @{
    "SqlInstance" = $SqlInstance
    "User" = $login
    "Database" = @($DatabaseAnalytics)
    "Role" = $Role
    "confirm" = $false
}
Add-DbaDbRoleMember @Params

#Assign role membership DDL_Admin
$Role = "ddl_admin"
$Params = @{
    "SqlInstance" = $SqlInstance
    "User" = $login
    "Database" = @($DatabaseAnalytics)
    "Role" = $Role
    "confirm" = $false
}
Add-DbaDbRoleMember @Params

#assign View definition
$sql = @" 
GRANT VIEW DEFINITION TO [$Login]
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $DatabaseAnalytics -Query $sql
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $DatabaseMacstaging -Query $sql
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $DatabaseMaconomy -Query $sql

if($RevoceConnect) {
$sql = @"
REVOKE CONNECT SQL TO [$Login] 
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $sql
} else {
$sql = @"
GRANT CONNECT SQL TO [$Login] 
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $sql

}