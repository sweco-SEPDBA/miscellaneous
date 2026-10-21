
SELECT  TOP (100) 
	*
FROM 
	[CMDB].[dbo].[RestoreLogs]
WHERE 1 = 1
	AND RestoreResult NOT IN ('Success', 'Skipped-AG-Secondary', 'Skipped-LS-Secondary')
    --AND SourceServer = 'SESTODS072.sweco.se\SWSQL06PC'
	--AND RestoreStart > DATEADD(day,-1,GETDATE())
	--AND [Database] = 'BI'
    --AND [TestServer] = 'SESTODS099.sweco.se\SWSQL33T'
ORDER BY
	Id desc

SELECT
	*
FROM
	RunningRestoreTest
WHERE 1 = 1
	-- AND DestInstance LIKE 'SEDCX%'
	--AND DestInstance = 'SESTODS076.sweco.se\SESQL43T'
	AND DestInstance = 'SESTODS099.sweco.se\SWSQL33T'

SELECT TOP 100
	*
FROM
	RestoreLogs
WHERE 1 = 1
	AND TestServer = 'SESTODS076.sweco.se\SESQL43T'
ORDER BY
	Id desc
	
SELECT
	DestInstance,
	RestoreStart,
	count(*)
FROM
	RunningRestoreTest
GROUP BY
	DestInstance,
	RestoreStart

-- Next to restore
;WITH LastRestoreTest AS (
SELECT 
    SourceServer,
    [Database],
    MAX(RestoreEnd) LastRestore
FROM
    RestoreLogs 
WHERE
    RestoreEnd > DATEADD(day,-50,GETDATE())
GROUP BY
    SourceServer, [Database]
)
    
SELECT  TOP (1)
    MAX(DATEDIFF(day,COALESCE(lrt.LastREstore,DATEADD(day,-100,GETDATE())),getdate())) [Days-Since-Last-Restore] --  last restore or 100 days if never restored
FROM 
    [Server] s
    INNER JOIN Instance i ON s.ServerId = i.ServerId
    INNER JOIN [Database] d ON i.InstanceId = d.InstanceId
    LEFT JOIN LastRestoreTest lrt ON i.SqlInstance = lrt.SourceServer AND d.[Name] = lrt.[Database]
    LEFT JOIN RunningRestoreTest rrt ON i.SqlInstance = rrt.SqlInstance --AND d.[Name] = rrt.[DBName]
WHERE
    s.IsServer = 1
    and i.IsActive = 1
    and d.DatabaseStatusId = 2 --2 = Database in normal state
    and i.EnvironmentId = 1 --1 = Production
    and rrt.SqlInstance IS NULL
    and d.[Name] NOT IN ('tempdb')
    and s.InDmz = 0
    and (i.SkipBackup = 0 OR i.SkipBackup IS NULL)


;WITH LastRestoreTest AS (
SELECT 
    SourceServer,
    [Database],
    MAX(RestoreEnd) LastRestore
FROM
    RestoreLogs 
WHERE
    RestoreEnd > DATEADD(day,-50,GETDATE())
GROUP BY
    SourceServer, [Database]
), LastRestoreDetails AS (  
SELECT top (10)
    i.SqlInstance,
    d.[Name],
    d.SizeMb,
    DATEDIFF(day,COALESCE(lrt.LastREstore,DATEADD(day,-100,GETDATE())),getdate()) [Days-Since-Last-Restore] --  last restore or 100 days if never restored
FROM 
    [Server] s
    INNER JOIN Instance i ON s.ServerId = i.ServerId
    INNER JOIN [Database] d ON i.InstanceId = d.InstanceId
    LEFT JOIN LastRestoreTest lrt ON i.SqlInstance = lrt.SourceServer AND d.[Name] = lrt.[Database]
    LEFT JOIN RunningRestoreTest rrt ON i.SqlInstance = rrt.SqlInstance --AND d.[Name] = rrt.[DBName]
WHERE
    s.IsServer = 1
    and i.IsActive = 1
    and d.DatabaseStatusId = 2 --2 = Database in normal state
    and i.EnvironmentId = 1 --1 = Production
    and rrt.SqlInstance IS NULL
    and d.[Name] NOT IN ('tempdb')
    and s.InDmz = 0
    and (i.SkipBackup = 0 OR i.SkipBackup IS NULL)
ORDER BY     [Days-Since-Last-Restore] DESC, i.SqlInstance, d.[Name]
)

SELECT STRING_AGG(lrd.SqlInstance + ' ' + lrd.Name + ' ' + CAST(lrd.[Days-Since-Last-Restore] AS NVARCHAR(20)) + ' days', CHAR(13) + CHAR(10))
            FROM LastRestoreDetails lrd
