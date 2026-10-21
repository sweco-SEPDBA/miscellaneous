USE [PeoplePlannerLicense]
GO

DECLARE @LOG_PATH NVARCHAR(MAX);
SET @LOG_PATH = 'C:\Logs\PeoplePlannerLicense.log';

DECLARE @LOG NVARCHAR(MAX);
SET @LOG =
(
	select top 1 CONCAT(CONVERT(varchar, Date, 106), ': ', ResourceCount) as Count
	from ResourceAssignments
	order by Id DESC
)

BEGIN
	DECLARE @OLE INT
	DECLARE @FILE_ID INT

	EXECUTE sp_OACreate 'Scripting.FileSystemObject', @OLE OUT
	EXECUTE sp_OAMethod @OLE, 'OpenTextFile', @FILE_ID OUT, @LOG_PATH, 8, 1
	EXECUTE sp_OAMethod @FILE_ID, 'WriteLine', null, @LOG

	EXECUTE sp_OADestroy @FILE_ID
	EXECUTE sp_OADestroy @OLE
END
