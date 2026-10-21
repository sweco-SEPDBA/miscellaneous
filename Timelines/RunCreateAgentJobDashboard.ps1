
$Sql = @"
select SqlInstance
from
	vwInstances
where
	IsServer = 1
    AND IsActive = 1
    AND Edition IN ('Developer', 'Standard', 'Enterprise')
"@

$Instances = Invoke-DbaQuery -SqlInstance SESTODS039\SWSQL16P -Database CMDB -Query $Sql 
$ServerInstances = $Instances | select-object -ExpandProperty SqlInstance
    $Parameters = @{
        StartDateTime = '2026-04-20 19:00:00'
        EndDateTime = '2026-04-21 09:00:00'
        MinRuntime = '1'
        jobName = '%'
        ServerInstances = 'SESTODS070\SWSQL42P'
      }
.\CreateAgentJobTimeLineDashboard.ps1 @Parameters -Verbose
