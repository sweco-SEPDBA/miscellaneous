Install-SwServerInstance -FQDN SEDCXDS910.sweco.se
Install-SwServerInstance -FQDN SEDCXDS901.sweco.se -Instance SWERP07PC
Install-SwServerInstance -FQDN SEDCXDS902.sweco.se -Instance SWERP07PC
Install-SwServerInstance -FQDN SEDCXDS903.sweco.se -Instance SWERP07PC

get-dbalogin -SqlInstance SESTODS961.sweco.se\SWERP13T | out-gridview -PassThru | new-dbalogin -SqlInstance SEDCXDS910.sweco.se\SWERP20T
get-dbalogin -SqlInstance SESTODS950.sweco.se\SWERP04PC | out-gridview -PassThru | new-dbalogin -SqlInstance SEDCXDS901.sweco.se\SWERP07PC
get-dbalogin -SqlInstance SESTODS950.sweco.se\SWERP04PC | out-gridview -PassThru | new-dbalogin -SqlInstance SEDCXDS902.sweco.se\SWERP07PC
get-dbalogin -SqlInstance SESTODS952.sweco.se\SWERP06PC | out-gridview -PassThru | new-dbalogin -SqlInstance SEDCXDS903.sweco.se\SWERP07PC

# Test mail installation

$Server = "SEDCXDS901.sweco.se"
$Instance = "SWERP07PC"

Write-Verbose "Install mail settings"
Write-Output "Install mail settings" 
$DBParams = @{Server="$Server"; Instance="$Instance"}
#Invoke-Sqlcmd2 -InputFile "..\Setup_Scripts\Mail Setup.sql" -SqlInstance $SqlInstance -SqlParameters $DBParams -QueryTimeout 60 *>&1 
Invoke-DbaQuery -File "C:\Users\sepdba_da\Documents\Repos\Database-SwecoDbaTools\Internal\Setup_Scripts\Mail Setup.sql" -SqlInstance $SqlInstance -SqlParameters $DBParams -QueryTimeout 60 *>&1 
Write-Verbose "Install alert settings"
Write-Output "Install alert settings" 
IF ($IsTest) {
    $DBParams = @{Operator="Database Team Extended"}
} ELSE {
    $DBParams = @{Operator="Database Team"}
}
Invoke-DbaQuery -File "C:\Users\sepdba_da\Documents\Repos\Database-SwecoDbaTools\Internal\Setup_Scripts\AlertsCreateSp.sql" -SqlInstance $SqlInstance -QueryTimeout 60 -Database tempdb *>&1 
Invoke-DbaQuery -File "C:\Users\sepdba_da\Documents\Repos\Database-SwecoDbaTools\Internal\Setup_Scripts\Alerts.sql" -SqlInstance $SqlInstance -SqlParameters $DBParams -QueryTimeout 60 -Database tempdb *>&1 
$DBParams.Add( 'Instance', "$Instance")
Write-Verbose "Install wmi alert settings"
Write-Output "Install wmi alert settings" 
Invoke-DbaQuery -File "C:\Users\sepdba_da\Documents\Repos\Database-SwecoDbaTools\Internal\Setup_Scripts\AddWmiAlerts.sql" -SqlInstance $SqlInstance -SqlParameters $DBParams -QueryTimeout 60 -Database msdb *>&1 

