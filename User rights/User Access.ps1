#Set parameters
$logins = "SWECO\user_da" 
$Databases = "swecocore"
$SqlInstance =  "coreprod.sql.sweco.se", "coretest.sql.sweco.se"
$Roles =  "swecocore_public_all", "swecocore_economy"



##########################################################################################################
#Create login
write-host "Creating login $logins" -ForegroundColor Magenta
$Params = @{
    "SqlInstance" = $SqlInstance
    "Login" = $logins
}
New-DbaLogin @Params

##########################################################################################################
#Create user
foreach ($Login in $Logins) {
    write-host "Creating user $Login in $Databases" -ForegroundColor Magenta
    $Params = @{
        "SqlInstance" = $SqlInstance
        "Login" = $Login
        "Database" = $Databases
    }
    New-DbaDbUser @Params
}


##########################################################################################################
#Assign role membership
foreach ($Database in $databases) {

    #####################################################################################
    #Add sweco ddladmin role
    write-host "Creating sweco_ddladmin role in $Database" -ForegroundColor Magenta

    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query "CREATE ROLE sweco_ddladmin"

    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query "ALTER ROLE db_ddladmin ADD MEMBER sweco_ddladmin"

    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query "DENY ALTER ANY DATABASE DDL TRIGGER TO sweco_ddladmin"

    #####################################################################################
    # Assign the user rights
    # Add user to role
    foreach ($login in $logins) {

        foreach ($Role in $Roles) {
            write-host "Adding $Login to $Role role in $Database" -ForegroundColor Magenta

            $sql = "ALTER ROLE $Role ADD MEMBER [$Login]"
            Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $sql

            if ($Role -eq "sweco_ddladmin") {
                write-host "Removing $Login from db_owner role" -ForegroundColor Magenta
                $sql = "ALTER ROLE db_owner DROP MEMBER [$Login]"
               # Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $sql
            }
        }

        #View definition and execute permission
        Write-Host "Granting view definition and execute permission to $Login in $Database" -ForegroundColor Magenta
        $sql = @" 
GRANT VIEW DEFINITION TO [$Login]
GRANT EXECUTE TO [$Login]
"@
        Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $sql
    }
}

