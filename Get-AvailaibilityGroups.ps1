$SqlInstanceCmdb = "SESTODS039.sweco.se\SWSQL16P"
$Database = "CMDB"
$AgInstances = "sestods036\swsql01pc", "sestods036\swsql02pc", "sestods950\swerp04pc", "sestods970\swerp12tc", "SESTODS901\SWERP01PC"

Get-DbaAvailabilityGroup -SqlInstance $AgInstances |
select-object AvailabilityGroup, PrimaryReplica |
Write-DbaDataTable -SqlInstance $SqlInstanceCmdb -Database $Database -Table AvailabilityGroup_Stage -Truncate -AutoCreateTable

$CMD = @"
MERGE AvailabilityGroup as t
USING (
	SELECT 
		AvailabilityGroup,
		PrimaryReplica
	FROM 
		AvailabilityGroup_Stage
	) as s (AvailabilityGroup, PrimaryReplica)
ON (t.AvailabilityGroup = s.AvailabilityGroup)
WHEN MATCHED THEN 
	UPDATE SET 
		t.PrimaryReplica = s.PrimaryReplica
WHEN NOT MATCHED BY TARGET THEN 
INSERT(AvailabilityGroup, PrimaryReplica)
values	(s.AvailabilityGroup, s.PrimaryReplica)
;
"@
Invoke-DbaQuery -SqlInstance $SqlInstanceCmdb -Query $Cmd -Database $Database 


Get-DbaAgListener -SqlInstance $AgInstances |
select-object AvailabilityGroup, Name, PortNumber, ClusterIPConfiguration |
Write-DbaDataTable -SqlInstance $SqlInstanceCmdb -Database $Database -Table AvailabilityGroupListener_stage -Truncate -AutoCreateTable


$CMD = @"
MERGE AvailabilityGroupListener as t
USING (
	SELECT 
		ag.AvailabilityGroupId,
		agl.[Name] AS [Listener],
		agl.PortNumber,
		REPLACE(REPLACE(agl.ClusterIPConfiguration,''')', ''), '(''IP Address: ', '') AS IPAddress
	FROM 
		AvailabilityGroupListener_Stage agl
		INNER JOIN AvailabilityGroup ag ON agl.AvailabilityGroup = ag.AvailabilityGroup
	) as s (AvailabilityGroupId, [Listener], PortNumber, IPAddress)
ON (t.[Listener] = s.[Listener])
WHEN MATCHED THEN 
	UPDATE SET 
		t.AvailabilityGroupId = s.AvailabilityGroupId, t.IpAddress = s.IpAddress, t.PortNumber = s.PortNumber
WHEN NOT MATCHED BY TARGET THEN 
INSERT(AvailabilityGroupId, [Listener], IpAddress, PortNumber)
values	(s.AvailabilityGroupId, s.[Listener], s.IpAddress, s.PortNumber)
;
"@
Invoke-DbaQuery -SqlInstance $SqlInstanceCmdb -Query $Cmd -Database $Database 

Get-DbaAvailabilityGroup -SqlInstance $AgInstances | select-object -ExpandProperty AvailabilityReplicas |  select-object Parent , Name |
Write-DbaDataTable -SqlInstance $SqlInstanceCmdb -Database $Database -Table AvailabilityGroupReplicas_stage -Truncate -AutoCreateTable

$CMD = @"
UPDATE Instance
	SET AvailabilityGroupId = ag.AvailabilityGroupId
from 
	AvailabilityGroupReplicas_stage avs
	INNER JOIN Instance i ON avs.Name = REPLACE(i.SqlInstance, '.sweco.se', '')
	INNER JOIN AvailabilityGroup ag ON TRIM('[]' from avs.Parent) = ag.AvailabilityGroup
"@
Invoke-DbaQuery -SqlInstance $SqlInstanceCmdb -Query $Cmd -Database $Database 

