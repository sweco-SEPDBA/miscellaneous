
Get-DbaAvailabilityGroup -SqlInstance SESTODS075.sweco.se\SWSQL48P | 
Get-DbaAgDatabase  | Out-GridView -PassThru  | 
Remove-DbaAgDatabase -Confirm:$false



Get-DbaDatabase -SqlInstance SESTODS075.sweco.se\SWSQL48P | Out-GridView -PassThru | Remove-DbaDatabase -Confirm:$false
Get-DbaDatabase -SqlInstance SESTODS017.sweco.se\SWSQL48P | Out-GridView -PassThru | Remove-DbaDatabase -Confirm:$false

copy-dbadatabase -Source SWSQL02PL.sql.sweco.se -Destination SESTODS075.sweco.se\SWSQL48P -Database pw_vectura_CE280 -BackupRestore -UseLastBackup

Get-DbaLogin -SqlInstance SESTODS017.sweco.se\SWSQL48P | Out-GridView -Passthru | Grant-DbaAgPermission -Type EndPoint

get-dbaspn -AccountName SWECO\msvc_SESTODS037$
