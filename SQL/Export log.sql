
SELECT 
	* 
FROM 
	ExportLog
WHERE
	Result <> 'Success'
	AND StartTime > DATEADD(Day,-1,GETDATE())
ORDER BY StartTime desc
