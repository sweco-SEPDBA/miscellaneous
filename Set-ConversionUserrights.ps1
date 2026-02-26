[cmdletbinding()]
Param (
    [Parameter(mandatory)] [string]$SqlInstance,
    [Parameter()] [string]$DatabaseConversion = "conversion",
    [Parameter(mandatory)] [string]$DatabaseMaconomy
)

#Assignments
$login = "SWECO\SW-Role-Conversion_SQL_Dev"

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
"Database" = @($DatabaseConversion, $DatabaseMaconomy)
}
New-DbaDbUser @Params


#Assign role membership datareader
$Role = "db_datareader","db_ddladmin"
$Params = @{
    "SqlInstance" = $SqlInstance
    "User" = $login
    "Database" = $DatabaseMaconomy
    "Role" = $Role
    "confirm" = $false
}
Add-DbaDbRoleMember @Params


#Assign role membership data writer
$Role = "db_owner"
$Params = @{
    "SqlInstance" = $SqlInstance
    "User" = $login
    "Database" = $DatabaseConversion
    "Role" = $Role
    "confirm" = $false
}
Add-DbaDbRoleMember @Params

#assign View definition
$sql = @" 
GRANT VIEW DEFINITION TO [$Login]
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $DatabaseConversion -Query $sql

#Remove orphan users
Repair-DbaDbOrphanUser -SqlInstance $SqlInstance -Database $DatabaseConversion -RemoveNotExisting

#Assign write user right on mno tables that is extensions
$mnoTables = Get-DbaDbTable -SqlInstance $SqlInstance -Database $DatabaseMaconomy | Where-Object {$_.Name -match '^mno'}
foreach ($table in $mnoTables) {
    $sql = @" 
    GRANT INSERT ON OBJECT::$($Table.Schema).$($Table.Name) TO [$Login]
    GRANT UPDATE ON OBJECT::$($Table.Schema).$($Table.Name) TO [$Login]
    GRANT DELETE ON OBJECT::$($Table.Schema).$($Table.Name) TO [$Login]
"@
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $DatabaseMaconomy -Query $sql
}
