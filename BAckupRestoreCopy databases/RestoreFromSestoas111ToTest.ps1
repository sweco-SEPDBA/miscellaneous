  
##########################
#Do first restore, no recovery
##########################
$params = @{
    SqlInstance = "SWSQL12T.sql.sweco.se"
    Path = "\\SESTOAS111\SQLBackup\SESTOAS111\CM_Sw1"
    MaintenanceSolutionBackup = $true
    DatabaseName = "CM_Sw1"
	NoRecovery = $true
}
Restore-DbaDatabase @params

##########################
#Do additional restore no recovery
##########################
$params = @{
    SqlInstance = "SWSQL12T.sql.sweco.se"
    Path = "\\SESTOAS111\SQLBackup\SESTOAS111\CM_Sw1"
    MaintenanceSolutionBackup = $true
    DatabaseName = "CM_Sw1"
	NoRecovery = $true
	Continue = $true
}
Restore-DbaDatabase @params
  
##########################
#Do restore with recovery. Primary
##########################
$params = @{
    SqlInstance = "SWSQL12T.sql.sweco.se"
    DatabaseName = "CM_Sw1"
	Recover = $true
}
Restore-DbaDatabase @params

