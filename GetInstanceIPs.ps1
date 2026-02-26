$SqlInstanceCmdb = "SESTODS039.sweco.se\SWSQL16P"
$Database = "CMDB"
$Cmd = @"
SELECT
	i.SqlInstance,
	i.CmsServerName
FROM
	[Server] s 
	INNER JOIN Instance i ON s.ServerId = i.ServerId
WHERE
	s.IsServer = 1
	AND i.IsActive = 1
    AND s.InDmz = 0
ORDER BY SqlInstance
"@
$instances = Invoke-DbaQuery -SqlInstance $SqlInstanceCmdb -Query $Cmd -Database $Database | select-object -expandproperty CmsServerName

$tcpip_addresses = foreach ($instance in $instances) {
    Get-DbaNetworkConfiguration -SqlInstance $instance   | 
    Select-Object -ExpandProperty TcpIpAddresses | 
    Where-Object {$psitem.Enabled} | 
    Select-Object @{n = 'CmsServerName'; e = {$instance}}, IpAddress, TcpDynamicPorts, TcpPort 
} 
$tcpip_addresses | Write-DbaDataTable -SqlInstance $SqlInstanceCmdb -Database $Database -Table IpAddresses_Stage -Truncate -AutoCreateTable

$CMD = @"
MERGE Instance_IpAddresses as t
USING (
    SELECT 
	i.InstanceId,
    ipa.CmsServerName,
    IpAddress,
	TcpDynamicPorts,
	TcpPort
  FROM 
    IpAddresses_Stage ipa
	INNER JOIN Instance i ON ipa.CmsServername = i.CmsServerName
) as s (InstanceId, CmsServerName, IpAddress, TcpDynamicPorts, TcpPort)
ON (t.InstanceId = s.InstanceId AND t.IpAddress = s.IpAddress)
WHEN MATCHED THEN 
	UPDATE SET 
		t.TcpDynamicPorts = s.TcpDynamicPorts,
		t.TcpPort = s.TcpPort
WHEN NOT MATCHED BY TARGET THEN 
INSERT(InstanceId, IpAddress, TcpDynamicPorts, TcpPort)
values	(s.InstanceId, s.IpAddress, s.TcpDynamicPorts, s.TcpPort)
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;
"@
Invoke-DbaQuery -SqlInstance $SqlInstanceCmdb -Query $Cmd -Database $Database 

