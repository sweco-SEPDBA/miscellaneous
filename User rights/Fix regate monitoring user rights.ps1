$Credential = get-credential

#Get a lits of monitored servers from nl database
$sql = @"
;with InstanceAccount (FQDN, SqlInstance, MonitoringAccount) AS (
SELECT 
	CASE 
		WHEN c.[IsCluster] = 1 THEN SUBSTRING(i.[Name],1,CHARINDEX('\',i.[NAME],1)-1) + '.' + COALESCE(c.Domain, 'sweco.se')
		WHEN c.[IsCluster] = 0 THEN c.[Name] 
	END AS FQDN,
	CASE 
		WHEN c.[IsCluster] = 1 THEN i.[Name]
		WHEN c.[IsCluster] = 0 THEN c.[Name] + 
			CASE WHEN i.[name] = '' THEN '' ELSE '\' + i.[Name] END
	END COLLATE Finnish_Swedish_CI_AS AS SqlInstance 
	,CASE	
		WHEN c.[CredentialsDiscriminator] = 0 THEN 'SWECO\svc_SqlMonitor'
		ELSE c.[Domain] + '\' + c.[User]
	END COLLATE Finnish_Swedish_CI_AS AS MonitoringAccount

FROM 
	[RedGateMonitor].[settings].[Clusters] c
	INNER JOIN [RedGateMonitor].[settings].[SqlServers] i on c.Id = i.ParentId
WHERE
	i.Address is not null
)
SELECT 
	FQDN,
	REPLACE(SqlInstance,'.sweco.se','') AS SqlInstance,
	REPLACE(MonitoringAccount,'sweco.se','SWECO') AS MonitoringAccount
FROM
	InstanceAccount
ORDER BY 
	SqlInstance

"@

Invoke-DbaQuery -SqlInstance NLAMSDS030\SWSQL52P -Database 'RedGateMonitor' -Query $sql | ForEach-Object {
$MonitoringAccount = $_.MonitoringAccount
$SqlInstance = $_.SqlInstance
$FQDN = $_.FQDN

    Write-Host "Updating Monitoring User Rights on instance: |$($_.SqlInstance)| installed on |$($_.FQDN)| with the user rights: $($_.MonitoringAccount)" -ForegroundColor DarkGreen

	try {
        Set-SwRedgateUserRights -FQDN $FQDN -SqlInstance $SqlInstance -MonitoringAccount $MonitoringAccount -Credential $Credential -ErrorAction Stop
    }
    catch {
        Add-Content -Path 'C:\Temp\FailedFQDNs.txt' -Value $FQDN
        Write-Host "Failed on FQDN: $FQDN - $($_.Exception.Message)" -ForegroundColor Red
    }
    start-sleep -Seconds 1
} 

Invoke-DbaQuery -SqlInstance SESTODS094\SWSQL58P -Database 'RedGateMonitor' -Query $sql | ForEach-Object {
$MonitoringAccount = $_.MonitoringAccount
$SqlInstance = $_.SqlInstance
$FQDN = $_.FQDN

    Write-Host "Updating Monitoring User Rights on instance: |$($_.SqlInstance)| installed on |$($_.FQDN)| with the user rights: $($_.MonitoringAccount)" -ForegroundColor DarkGreen

	
	try {
        Set-SwRedgateUserRights -FQDN $FQDN -SqlInstance $SqlInstance -MonitoringAccount $MonitoringAccount -Credential $Credential -ErrorAction Stop
    }
    catch {
        Add-Content -Path 'C:\Temp\FailedFQDNs.txt' -Value $FQDN
        Write-Host "Failed on FQDN: $FQDN - $($_.Exception.Message)" -ForegroundColor Red
    }
    start-sleep -Seconds 1
} 
