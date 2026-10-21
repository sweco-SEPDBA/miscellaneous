SELECT 
	a.FQDN AS Alias,
	s.FQDN,
	s.IPv4,
	i.InstanceName,
	ii.IpAddress,
	ii.TcpPort
FROM 
	aliases_stage a
	INNER JOIN [Server] s ON a.[Data] = s.IPv4
	INNER JOIN Instance i ON s.ServerId = i.ServerId
	LEFT JOIN Instance_IpAddresses ii ON i.InstanceId = ii.InstanceId
WHERE
	a.FQDN <> s.FQDN
	AND i.IsActive = 1
