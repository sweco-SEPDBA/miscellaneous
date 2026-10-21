
SELECT TOP (2000) [Id]
    ,[SourceServer]
    ,[TestServer]
    ,[Database]
    ,[RestoreResult]
    ,[RestoreStart]
FROM [CMDB].[dbo].[RestoreLogs]
    --Where TestServer = 'SESTODS076.sweco.se\SESQL37T'
    --Where TestServer = 'SESTODS004.sweco.se\SWSQL23T'
    --Where TestServer = 'SESTODS065.sweco.se\SESQL20T'
    --where SourceServer = 'GBMAHAS002.sweco.se\PLANASSESSOR6'
    --where SourceServer = 'SESTODS017.sweco.se\SWSQL48P'
    --where SourceServer = 'NLAMSDS026.sweco.se\NLSQL20P'
    --where SourceServer = 'SESTODS052.sweco.se\SWSQL29P'
    --where SourceServer = 'SESTOAS122.sweco.se\AUTODESK' and [database] = 'sestoas749_15501936-008_reppu_univar_p3d_15501936-008-skumslackningssystem-univar-copenhagen_PnId'
    --where [Database] = 'Ekonom_T'
order by id desc


SELECT 
	DestInstance, SqlInstance, RestoreStart, count(*)
FROM RunningRestoreTest 
GROUP BY
	DestInstance, SqlInstance, RestoreStart
ORDER BY
	DestInstance, RestoreStart



SELECT 
	*
FROM RunningRestoreTest 
WHERE 1 = 1
    AND DestInstance = 'GBLDSDS004.sweco.se\GBSQL13T'
ORDER BY RestoreStart desc


begin transaction
DELETE FROM RunningRestoreTest 
WHERE 1 = 1
   -- AND DestInstance = 'SESTODS065.sweco.se\SESQL20T' 
    AND SqlInstance = 'SESTODS072.sweco.se\SWSQL06PC' 
   -- AND RestoreStart < DATEADD(HOUR, -3,getdate())
rollback


;WITH LastRestoreTest AS (
SELECT 
    SourceServer,
    [Database],
    MAX(RestoreEnd) LastRestore
FROM
    RestoreLogs 
GROUP BY
    SourceServer, [Database]),

OldestRestoreTest AS (
SELECT TOP (1) 
    i.SqlInstance,
    d.[Name],
    d.SizeMb,
    COALESCE(lrt.LastREstore,'2000-01-01 00:00:00') [Last-Restore] 
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
    AND (d.SizeMb IS NULL
        OR d.SizeMb BETWEEN 0 AND 10240000)
    and i.CountryCode LIKE '%'
    and i.SqlInstance LIKE '%'
    and d.[Name] LIKE '%'
    and d.[Name] NOT IN ('tempdb')
    and s.InDmz = 0
    and (i.SkipBackup = 0 OR i.SkipBackup IS NULL)
ORDER BY
    [Last-Restore], i.SqlInstance, d.[Name])

SELECT
    i.SqlInstance,
    d.[Name] dbName,
    '$Destinstance' DestInstance,
    getdate() RestoreStart,
    d.SizeMb,
    ort.[Last-Restore]
FROM
    [Server] s
    INNER JOIN Instance i ON s.ServerId = i.ServerId
    INNER JOIN [Database] d ON i.InstanceId = d.InstanceId
    INNER JOIN OldestRestoreTest ort ON i.SqlInstance = ort.SqlInstance
WHERE
    d.DatabaseStatusId = 2 --2 = Database in normal state
    and i.EnvironmentId = 1 --1 = Production
    AND (d.SizeMb IS NULL
        OR d.SizeMb BETWEEN 0 AND 10240000)
    and i.CountryCode LIKE '%'
    and i.SqlInstance LIKE '%'
    and d.[Name] LIKE '%'
    and d.[Name] NOT IN ('tempdb')
    and s.InDmz = 0
    and (i.SkipBackup = 0 OR i.SkipBackup IS NULL)

SELECT TOP (1000) [Id]
      ,[SourceServer]
      ,[TestServer]
      ,[Database]
      ,[RestoreResult]
      ,[RestoreStart]
  FROM [CMDB].[dbo].[RestoreLogs]
  --Where TestServer = 'SESTODS076.sweco.se\SESQL37T'
  --Where TestServer = 'SESTODS004.sweco.se\SWSQL23T'
  -- Where TestServer = 'SESTODS065.sweco.se\SESQL20T'
  --where SourceServer = 'GBMAHAS002.sweco.se\PLANASSESSOR6'
  where SourceServer = 'SESTODS017.sweco.se\SWSQL48P'
  --where TestServer = 'GBLDSDS004.sweco.se\GBSQL13T'
  order by id desc

SELECT 
	* 
FROM
	Instance i
WHERE 1 = 1
	and i.SqlInstance = 'SESTOAS005.sweco.se\RTC'
	and i.InstancePurposeId = 24
	and i.IsActive = 1

BEGIN TRANSACTION
UPDATE Instance
SET SkipBackup = 1
WHERE 1 = 1
	and SqlInstance = 'SESTOAS005.sweco.se\RTC'
	--and InstancePurposeId = 24
	and IsActive = 1
ROLLBACK
