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
$UpdateQuery = @"
	
    /* 4) Create user in all databases and grant database-level permissions
        - Grants VIEW DATABASE STATE on all databases
        - Grants SELECT on sys.sql_expression_dependencies on all databases
    */
    DECLARE @db sysname, @cmd nvarchar(max);

    DECLARE dbs CURSOR FAST_FORWARD FOR
    SELECT d.name
    FROM sys.databases d
    LEFT JOIN sys.dm_hadr_database_replica_states drs ON d.database_id = drs.database_id AND drs.is_local = 1
    WHERE 
        d.is_read_only = 0
        AND d.state_desc = N'ONLINE'
        AND name NOT IN (N'master', N'tempdb', N'msdb') 
        AND (drs.is_primary_replica = 1     
            OR drs.is_primary_replica IS NULL)

    OPEN dbs;
    FETCH NEXT FROM dbs INTO @db;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @cmd = N'
    USE ' + QUOTENAME(@db) + N';

    -- Create the user if it does not exist in this database
    IF DATABASE_PRINCIPAL_ID(N''$MonitoringAccount'') IS NULL
    BEGIN
        CREATE USER [$MonitoringAccount] FOR LOGIN [$MonitoringAccount];
    END;

    -- Grant VIEW DATABASE STATE (needed for DB-scoped DMVs)
    GRANT VIEW DATABASE STATE TO [$MonitoringAccount];

    -- Grant SELECT on dependency metadata view (required by Redgate Monitor)
    GRANT SELECT ON [sys].[sql_expression_dependencies] TO [$MonitoringAccount];
    ';
        EXEC sp_executesql @cmd;

        FETCH NEXT FROM dbs INTO @db;
    END

    CLOSE dbs;
    DEALLOCATE dbs;
    GO
"@
    Write-Host "Updating Monitoring User Rights on instance: |$($_.SqlInstance)| installed on |$($_.FQDN)| with the user rights: $($_.MonitoringAccount)" -ForegroundColor DarkGreen

	Invoke-DbaQuery -SqlInstance $($_.SqlInstance) -Query $UpdateQuery -Database master 
    start-sleep -Seconds 1
} 

Invoke-DbaQuery -SqlInstance SESTODS094\SWSQL58P -Database 'RedGateMonitor' -Query $sql | ForEach-Object {
$MonitoringAccount = $_.MonitoringAccount
$UpdateQuery = @"
	
    /* 4) Create user in all databases and grant database-level permissions
        - Grants VIEW DATABASE STATE on all databases
        - Grants SELECT on sys.sql_expression_dependencies on all databases
    */
    DECLARE @db sysname, @cmd nvarchar(max);

    DECLARE dbs CURSOR FAST_FORWARD FOR
    SELECT d.name
    FROM sys.databases d
    LEFT JOIN sys.dm_hadr_database_replica_states drs ON d.database_id = drs.database_id AND drs.is_local = 1
    WHERE 
        d.is_read_only = 0
        AND d.state_desc = N'ONLINE'
        AND name NOT IN (N'master', N'tempdb', N'msdb') 
        AND (drs.is_primary_replica = 1     
            OR drs.is_primary_replica IS NULL)

    OPEN dbs;
    FETCH NEXT FROM dbs INTO @db;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @cmd = N'
    USE ' + QUOTENAME(@db) + N';

    -- Create the user if it does not exist in this database
    IF DATABASE_PRINCIPAL_ID(N''$MonitoringAccount'') IS NULL
    BEGIN
        CREATE USER [$MonitoringAccount] FOR LOGIN [$MonitoringAccount];
    END;

    -- Grant VIEW DATABASE STATE (needed for DB-scoped DMVs)
    GRANT VIEW DATABASE STATE TO [$MonitoringAccount];

    -- Grant SELECT on dependency metadata view (required by Redgate Monitor)
    GRANT SELECT ON [sys].[sql_expression_dependencies] TO [$MonitoringAccount];
    ';
        EXEC sp_executesql @cmd;

        FETCH NEXT FROM dbs INTO @db;
    END

    CLOSE dbs;
    DEALLOCATE dbs;
    GO
"@
    Write-Host "Updating Monitoring User Rights on instance: |$($_.SqlInstance)| installed on |$($_.FQDN)| with the user rights: $($_.MonitoringAccount)" -ForegroundColor DarkGreen

	Invoke-DbaQuery -SqlInstance $($_.SqlInstance) -Query $UpdateQuery -Database master 
    start-sleep -Seconds 1
} 
