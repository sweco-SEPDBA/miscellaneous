;with doubles as (
	SELECT 
		id.[Device name] AS DeviceName
	FROM
		[IntuneData-SystemHealth-Import-stage] id
		LEFT JOIN Devices d ON id.[Device name] = d.DeviceName 
		LEFT JOIN [WindowsUpdate-SystemHealth-Import-stage] wu ON id.[Device name] = wu.Computer
		--where Manufacturer not IN ('Apple', 'Samsung')
	group by
		id.[Device name] having COUNT(*) > 1)
,filtered as (
	SELECT d.DeviceName, id.[Managed by] 
	FROM 
		doubles d 
		inner join [IntuneData-SystemHealth-Import-stage] id ON id.[Device name] = d.DeviceName
	where [Managed by] = 'ConfigMgr')
,lastdouble as (
SELECT
	d.DeviceName, MAX(id.[Last check-in]) AS LastCheckin
FROM
	doubles d
	LEFT JOIN filtered f ON d.DeviceName = f.DeviceName
	INNER JOIN [IntuneData-SystemHealth-Import-stage] id ON id.[Device name] = d.DeviceName
WHERE
	f.DeviceName IS NULL
GROUP BY
	d.DeviceName)
,windowsupdates as (
SELECT 
	wu.Computer, MAX(wu.LastScan) LastScan
FROM
	[WindowsUpdate-SystemHealth-Import-stage] wu
GROUP BY
	wu.Computer
)



MERGE Devices  AS t
USING (
		
-- Devices with double no ConfigMgr
SELECT
	id.[Device name], 
	COALESCE(id.[Serial number], d.SerialNumber) AS SerialNumber,
	id.[Device ID] AS IntuneDeviceId,
	wu.LastScan AS WindowsUpdate_LastScan
FROM
	filtered f
	INNER JOIN [IntuneData-SystemHealth-Import-stage] id ON id.[Device name] = f.DeviceName AND id.[Managed by] = f.[Managed by]
	LEFT JOIN Devices d ON id.[Device name] = d.DeviceName 
	LEFT JOIN WindowsUpdates wu ON id.[Device name] = wu.Computer

UNION

 --Devices with double Last Checkin
SELECT
	id.[Device name], 
	COALESCE(id.[Serial number], d.SerialNumber) AS SerialNumber,
	id.[Device ID] AS IntuneDeviceId,
	wu.LastScan AS WindowsUpdate_LastScan
FROM
	lastdouble du
	INNER JOIN [IntuneData-SystemHealth-Import-stage] id ON id.[Device name] = du.DeviceName AND id.[Last check-in] = du.LastCheckin
	LEFT JOIN Devices d ON id.[Device name] = d.DeviceName 
	LEFT JOIN WindowsUpdates wu ON id.[Device name] = wu.Computer
UNION

-- Entries without dobles
SELECT 
	id.[Device name], 
	COALESCE(id.[Serial number], d.SerialNumber) AS SerialNumber,
	id.[Device ID] AS IntuneDeviceId,
	wu.LastScan AS WindowsUpdate_LastScan
FROM 
	[IntuneData-SystemHealth-Import-stage] id 
	LEFT JOIN doubles du ON id.[Device name] = du.DeviceName 
	LEFT JOIN Devices d ON id.[Device name] = d.DeviceName 
	LEFT JOIN WindowsUpdates wu ON id.[Device name] = wu.Computer
WHERE
	du.DeviceName is null

) AS s(DeviceName, SerialNumber, IntuneDeviceId, WindowsUpdate_LastScan)
ON t.DeviceName = s.DeviceName
WHEN MATCHED THEN
	UPDATE SET t.SerialNumber = t.SerialNumber, t.IntuneDeviceId = s.IntuneDeviceId, t.WindowsUpdate_LastScan = s.WindowsUpdate_LastScan
WHEN NOT MATCHED THEN
	INSERT (DeviceName, SerialNumber, IntuneDeviceId, WindowsUpdate_LastScan)
	VALUES (s.DeviceName, s.SerialNumber, s.IntuneDeviceId, s.WindowsUpdate_LastScan)
;
