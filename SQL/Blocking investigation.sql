SELECT * FROM data.Cluster_SqlServer_SqlProcess_Instances_View
WHERE Cluster_Name = 'sestocl020.sweco.se'
  AND Cluster_SqlServer_Name = 'sestods952\swerp06pc'
  AND (Cluster_SqlServer_SqlProcess_SessionId = 135
    OR Cluster_SqlServer_SqlProcess_SessionId IN (SELECT Cluster_SqlServer_SqlProcess_SessionId 
                                                    FROM data.Cluster_SqlServer_SqlProcess_UnstableSamples_View
                                                    WHERE Cluster_Name = 'sestocl020.sweco.se'
                                                    AND Cluster_SqlServer_Name = 'sestods952\swerp06pc'
                                                    AND Cluster_SqlServer_SqlProcess_BlockingSessionId = 135
                                                 ))

SELECT * FROM data.Cluster_SqlServer_SqlProcess_UnstableSamples_View
WHERE Cluster_Name = 'sestocl020.sweco.se'
  AND Cluster_SqlServer_Name = 'sestods952\swerp06pc'
  AND (Cluster_SqlServer_SqlProcess_SessionId = 135
    OR Cluster_SqlServer_SqlProcess_BlockingSessionId = 135)

SELECT * FROM data.Cluster_SqlServer_SqlProcess_UnstableSamples_View
WHERE Cluster_Name = 'sestocl020.sweco.se'
  AND Cluster_SqlServer_Name = 'sestods952\swerp06pc'
  AND (Cluster_SqlServer_SqlProcess_SessionId = 21
    OR Cluster_SqlServer_SqlProcess_BlockingSessionId = 21)


SELECT * FROM data.Cluster_SqlServer_SqlProcess_UnstableSamples_View
                                                    WHERE Cluster_Name = 'sestocl020.sweco.se'
                                                    AND Cluster_SqlServer_Name = 'sestods952\swerp06pc'
                                                    AND Cluster_SqlServer_SqlProcess_SessionId = 21
                                                    --AND Cluster_SqlServer_SqlProcess_BlockingSessionId = 21
