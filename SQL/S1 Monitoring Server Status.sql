SELECT  
    [ServerName]
    ,[Description]
    ,[HeartbeatDateTime]
    ,[LastInitializationDateTime]
  FROM [SentryOne].[dbo].[ManagementEngine]
ORDER BY LastInitializationDateTime desc


SELECT 
	me.ServerName,
	max(ds.LastEvaluationEndTimeUtc) AS LastEvaluation
FROM
	DynamicConditionStatus ds
	INNER JOIN Device d ON ds.ObjectID = d.ObjectID
	INNER JOIN ManagementEngine me ON d.ManagementEngineID = me.ID
WHERE
	ds.ConditionID = 'F55E7665-276D-40B3-A1BC-5FCB23F3B08B'
GROUP BY
	me.ServerName


SELECT 
	me.ServerName,
	d.HostName,
	max(ds.LastEvaluationEndTimeUtc) AS LastEvaluation
FROM
	DynamicConditionStatus ds
	INNER JOIN Device d ON ds.ObjectID = d.ObjectID
	INNER JOIN ManagementEngine me ON d.ManagementEngineID = me.ID
WHERE
	ds.ConditionID = 'F55E7665-276D-40B3-A1BC-5FCB23F3B08B'
GROUP BY
	me.ServerName,
	d.HostName
ORDER BY
	LastEvaluation


