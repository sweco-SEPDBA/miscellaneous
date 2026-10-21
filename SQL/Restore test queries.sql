SELECT  [SqlInstance]
      ,[DBName]
  FROM [CMDB].[dbo].[RunningRestoreTest]

 -- truncate table [CMDB].[dbo].[RunningRestoreTest]
 -- Delete from RestoreLogs where [Database] = 'API_Access ASGRD_96514 BI BIanalytics BIanalytics_Prod BudgetTool Cardpresso cashm cfa contact driftcenter FrameworkAgreement  globalsoftwareusage HRCore HRSweden InternalAudit IR MaartrondeDWH MaartrondeDWH_Meta MaartrondeDWH_STG MaconomyIntegration messagehandler O365Service ocra14 ocrawork ProjectFolder ProjectLinkService ProjectMember ProjectModel ProjectWiseService ProjectWorkspace RaetHR RaetJournals RaetToCore ramavtal RiskAssessment Signature sots staging swecoaccess SwecoApi SwecoApplications Swecoarkiv swecoatwork swecocore swecocoreexpo SwecoGpt SwecoIntranetEPiServer SwecoIntranetEPiServerCommunity SwecoIntranetStaging SwecoJob SwecoLog SwecoText2SQL swecotranslation Telenor TelephonyNL Tellus TEM TIME TravelExpense tre webbeko VendorInvoices vRDDb2015'

 select top 500 * from RestoreLogs order by RestoreEnd desc

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
    LEFT JOIN RunningRestoreTest rrt ON i.SqlInstance = rrt.SqlInstance AND d.[Name] = rrt.[DBName]
WHERE
    s.IsServer = 1
    and i.IsActive = 1
    and d.DatabaseStatusId = 2 --2 = Database in normal state
    and i.EnvironmentId = 1 --1 = Production
    and rrt.SqlInstance IS NULL
    AND (d.SizeMb IS NULL
        OR d.SizeMb BETWEEN 512000 AND 10240000)
    and d.[Name] NOT IN ('tempdb')
ORDER BY
    [Last-Restore], i.SqlInstance, d.[Name])
SELECT
    i.SqlInstance,
    d.[Name],
	d.SizeMb,
	ort.[Last-Restore]
FROM
	Instance i
	INNER JOIN [Database] d ON i.InstanceId = d.InstanceId
	INNER JOIN OldestRestoreTest ort ON i.SqlInstance = ort.SqlInstance
WHERE
	d.DatabaseStatusId = 2 --2 = Database in normal state
    and i.EnvironmentId = 1 --1 = Production
    AND (d.SizeMb IS NULL
        OR d.SizeMb BETWEEN 512000 AND 10240000)
    and d.[Name] NOT IN ('tempdb')
	


	-- delete from RunningRestoreTest where SqlInstance = 'SESTODS037.sweco.se\SWSQL91PC'