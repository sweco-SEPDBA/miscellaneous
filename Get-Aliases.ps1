
$cmd = @"
SELECT Name+'.sql.sweco.se' Alias
FROM aliases_staging

EXCEPT

(
SELECT 
	a.Name+'.sql.sweco.se' Alias
FROM 
	[Server] s
	INNER JOIN Instance i ON s.ServerId = i.ServerId
	INNER JOIN Instance_IpAddresses ipa ON i.InstanceId = ipa.instanceid	
	INNER JOIN aliases_staging a ON ipa.IpAddress = a.Data
WHERE
	s.IsServer = 1
	--AND i.IsActive = 1

UNION ALL

SELECT
	a.Name+'.sql.sweco.se' Alias
FROM
	[Server] s
	INNER JOIN Instance i ON s.ServerId = i.ServerId
	INNER JOIN aliases_staging a ON a.Data like i.InstanceName+'.sql.sweco.se%' OR a.Data like s.FQDN+'%'
WHERE
	s.IsServer = 1
	--AND i.IsActive = 1
)
"@
$INSTANCES = Invoke-DbaQuery -SqlInstance SESTODS039\SWSQL16P -Database CMDB -Query $Cmd | select-object -ExpandProperty Alias

$connectstatus = foreach ($instance in $instances) {
    Write-Host "Trying to connect: $instance"
    Test-DbaConnection -SqlInstance $instance | Select-Object ComputerName, InstanceName, SqlInstance, IpAddress, ConnectSuccess
    #$connect = Connect-DbaInstance -SqlInstance $instance -ErrorAction SilentlyContinue
    #Write-Host "Connect status Computername: $($connect.Computername) Alias: $($connect.Name)"
}
$connectstatus | Format-Table

