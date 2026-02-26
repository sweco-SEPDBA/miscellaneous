
$Listener = 'SWSQL48P01PL.sweco.se'
get-dbaagreplica -SqlInstance $Listener | Select-Object Name, Role -Unique | Out-GridView -Passthru  |
ForEach-Object {Get-DbaAgReplica -SqlInstance $_.Name -Replica $_.Name} | Out-GridView -Passthru  |
ForEach-Object {Get-DbaAvailabilityGroup -AvailabilityGroup $_.AvailabilityGroup -SqlInstance $_.Name} |
Invoke-DbaAgFailover -Confirm:$false

$Listener = 'SWSQL50P01PL.sweco.se'
get-dbaagreplica -SqlInstance $Listener | Select-Object Name, Role -Unique | Out-GridView -Passthru  |
ForEach-Object {Get-DbaAgReplica -SqlInstance $_.Name -Replica $_.Name} | Out-GridView -Passthru  |
ForEach-Object {Get-DbaAvailabilityGroup -AvailabilityGroup $_.AvailabilityGroup -SqlInstance $_.Name} |
Invoke-DbaAgFailover -Confirm:$false
