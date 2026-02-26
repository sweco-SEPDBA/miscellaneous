
$Listener = 'SWSQL05TL.sweco.se'

get-dbaagreplica -SqlInstance $Listener | Select-Object Name, Role -Unique | Out-GridView -Passthru  | 
ForEach-Object {Get-DbaAgReplica -SqlInstance $_.Name -Replica $_.Name} | Out-GridView -Passthru  | 
ForEach-Object {Get-DbaAvailabilityGroup -AvailabilityGroup $_.AvailabilityGroup -SqlInstance $_.Name} | 
Invoke-DbaAgFailover -Confirm:$false

# Get-DbaAgDatabase -SqlInstance SESTODS017.sweco.se\SWSQL48P | Out-GridView -Passthru | Resume-DbaAgDbDataMovement -Confirm:$false
#Get-DbaLogin -SqlInstance sql2017a | Out-GridView -Passthru | 

Grant-DbaAgPermission -SqlInstance sestods075.sweco.se\swsql48p -Login SWECO\msvc_SESTODS017$ -Type EndPoint
Grant-DbaAgPermission -SqlInstance sestods075.sweco.se\swsql48p -Login SWECO\msvc_SESTODS075$ -Type EndPoint
Grant-DbaAgPermission -SqlInstance sestods017.sweco.se\swsql48p -Login SWECO\msvc_SESTODS017$ -Type EndPoint
Grant-DbaAgPermission -SqlInstance sestods017.sweco.se\swsql48p -Login SWECO\msvc_SESTODS075$ -Type EndPoint
