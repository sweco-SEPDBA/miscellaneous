-- Creates a SQL Server Extended Events log session.
-- Version: 3.20
-- Date: 2021-06-28
-- Created by: Morten Rasted, Deltek Engineering (Maconomy)

-- INSTRUCTIONS:	1. Select the Maconomy database in SQL Server Management Studio.
--					2. Change the settings under "Settings" if needed. It is recommended to assign the same value to all the duration thresholds.
--					3. Run this script.
--					4. To stop the Extended Events session again, run the script "SQL Server TraceLog Stop v.3.19.sql".
--					5. Collect all the files in "C:\TraceLogs\".


declare @dbName varchar(255)
declare @dbName2 nvarchar(255)
declare @dbName3 varchar(255)
declare @sessionName varchar(255)
declare @duration varchar(50)
declare @durationPlan varchar(50)
declare @durationWaits varchar(50)
declare @durationLocks varchar(50)
declare @getWaitStats bit
declare @getExecutionPlan bit
declare @filename varchar(255)
declare @cmd varchar(max)
declare @FilePath nvarchar(255)
declare @rootFolder varchar(10)
declare @trcFolder varchar(200)
declare @cmd1 nvarchar(max)
declare @cmd2 nvarchar(max)
declare @cmd3 nvarchar(max)
declare @cmd4 nvarchar(max)
declare @cpuThreshold int
declare @cpuThresholdActivated bit
declare @cpuUtilCheckInterval int
declare @msg varchar(255)
declare @queryHashFilter bit
declare @usePlanCache bit
declare @baselineMode bit
declare @baselineTime int
declare @issueReplicationTimeInterval int
declare @startDate int
declare @endDate int
declare @startTime int
declare @endTime int
declare @freqSubdayType int
declare @testMode bit
declare @company varchar(255)
declare @schedulingEnabled bit
declare @schedules nvarchar(max)
declare @maxRolloverFiles int
declare @logDrive char(1)
declare @availabilityGroup varchar(255)
declare @includeBGT bit
declare @includeMcUsers bit
declare @blockedProcessThreshold char(2)
declare @enableMcUsersSchJob bit
declare @numberRows int

-- ====================================== Log Drive Settings ============================================================================================================
set @logDrive = 'G' -- Used for the "TraceLogs" folder, i.e. "C:\TraceLogs\" (Default: 'C'. DCO: 'F').

-- ====================================== Scheduler Settings ============================================================================================================
set @schedulingEnabled = 1	-- 0: Scheduling disabled. 1: Scheduling enabled (Default: 0).
set @schedules = N'2021-10-08T02:55:00,2021-10-08T06:15:00&'

-- ====================================== Script Settings for Extended Events ===========================================================================================
set @duration = '100'				-- Duration threshold for SQL statements in milliseconds (It's a string, not an integer. Default: '10').
set @durationPlan = '1'				-- Duration threshold for execution plans in milliseconds (It's a string, not an integer. Default: '1').
set @durationWaits = '1'			-- Duration threshold for wait statistics in milliseconds (It's a string, not an integer. Default: '1').
set @durationLocks = '1'			-- Duration threshold for DB locks in milliseconds (It's a string, not an integer. Default: '1').
set @blockedProcessThreshold = '0'	-- Duration threshold for blocked processes in milliseconds (String. Default: 5).

set @getWaitStats = 1				-- 1: Get wait statistics. 0: Don't get wait statistics (default: 1).

set @getExecutionPlan = 1			-- 1: Get execution plans. 0: Don't get execution plans (default: 1).

set @includeBGT = 1					-- 1: Copy the background task tables to the McCollog db. 0: Don't copy BGT tables.
set @includeMcUsers = 1				-- 1: Copy the MACONOMY_USERS table to the McCollog db. 0: Don't copy the MACONOMY_USERS table.
set @enableMcUsersSchJob = 0		-- 1: Enable the "Get Maconomy User SPID" scheduled job. 0: Don't enable it.

set @maxRolloverFiles = 150			-- Max number of Extended Events files (*.xel) of 128 MB each which will be generated in "C:\TraceLogs\" before the first file will be overriden
									-- (Default: 20).

set @cpuThresholdActivated = 0		-- 1: Activates the logging when the CPU utilization >= @cpuThreshold, and deactivates again when CPU utilization < @cpuThreshold.
--									   0: Activates logging at once (default: 0).
set @cpuThreshold = 1				-- The CPU utilization threshold in percent (integer value) that start the logging when @cpuThresholdActivated = 1 (default: 60).
--									   NOTE: The CPU utilization is for the Maconomy database only, all other SQL Server activity is disregarded!
set @cpuUtilCheckInterval = 2		-- The interval in minutes (integer) where the Maconomy db utilization will be checked.

-- ====================================== Script Settings for Use Plan Cache ============================================================================================
set @usePlanCache = 0		--	1: Use Plan Cache (this will disable Extended Events mode). 0: Use Extended Events.
set @baselineMode = 0		--	1: Only collect the Plan Cache once a day (baseline mode). 0: Issue Replication mode. This will collect the Plan Cache at a given time interval.
set @issueReplicationTimeInterval = 30	-- The time interval in minutes in which the Plan Cache will be collected. Will only be used if @baselineMode = 0.
-- ====================================== DON'T CHANGE ANYTHING BELOW THIS LINE! ========================================================================================

EXEC sp_configure 'show advanced options', 1 
RECONFIGURE
EXEC sp_configure 'blocked process threshold', @blockedProcessThreshold
RECONFIGURE
EXEC sp_configure 'show advanced options', 0 
RECONFIGURE
DBCC traceon(1222,-1)

set @testMode = 0
if @schedulingEnabled = 0
	begin
		set @startDate = 20200901
		set @endDate = 99991231
		set @startTime = 0
		set @endTime = 235959
	end -- if
if @baselineMode = 1
	begin
		set @freqSubdayType = 1
		set @startTime = 0
	end -- if
else
	set @freqSubdayType = 4
if @testMode = 1
	begin
		set @freqSubdayType = 2
		set @issueReplicationTimeInterval = 5
		if @issueReplicationTimeInterval < 10
			set @issueReplicationTimeInterval = 10
	end -- if

SET NOCOUNT ON

-- Check if a valid Maconomy database has been selected:
begin try
	set @cmd = 'declare @McCheck int select @McCheck = count(*) from [' + DB_NAME() + '].dbo.SYSTEMINFORMATION'
	exec(@cmd)
end try
begin catch
	set @msg = concat('"',DB_NAME(),'" is not a valid Maconomy database. Please select the right database and try again.')
	RAISERROR (@msg, 10, 1) WITH NOWAIT
	goto ScriptEnd
end catch
set @cmd = 'Test'

-- Create the "C:\TraceLogs\" folder:
set @rootFolder = ''
set @trcFolder = concat(@logDrive,':\TraceLogs\') -- Trace file folder
EXEC master.dbo.xp_create_subdir @trcFolder
set @dbName = concat('''',DB_NAME(),'''')
set @dbName2 = upper(DB_NAME())
set @dbName3 = DB_NAME()

-- Create the McCollog database:
set @company = (select top 1 NAME1 from COMPANYINFORMATION where THENUMBER = 1)
if CHARINDEX(' ',@company) > 0
	begin
		set @company = LEFT(@company,CHARINDEX(' ',@company)-1) + '_'
	end -- if
else
	set @company = @company + '_'
if CHARINDEX('\',@company) > 0 or CHARINDEX('/',@company) > 0
	begin
		set @company = REPLACE(@company,'\','')
		set @company = REPLACE(@company,'/','')
	end -- if
begin try
	-- Check if the McCollog database is a member of an availability group:
	set @availabilityGroup = (select top 1
		AG.name as [AvailabilityGroupName]
	from master.sys.availability_groups as AG
	inner join master.sys.availability_replicas as AR
	   on AG.group_id = AR.group_id
	inner join master.sys.dm_hadr_availability_replica_states as arstates
	   on AR.replica_id = arstates.replica_id AND arstates.is_local = 1
	inner join master.sys.dm_hadr_database_replica_cluster_states as dbcs
	   on arstates.replica_id = dbcs.replica_id
	where dbcs.database_name = 'McCollog_' + @company + DB_NAME())
	if @availabilityGroup is not null
		begin
			set @cmd = concat('ALTER AVAILABILITY GROUP ',@availabilityGroup,' REMOVE DATABASE McCollog_',@company,DB_NAME())
			exec(@cmd)
		end -- if
	DECLARE @kill varchar(8000) = 'USE [master];';  
	SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
	FROM sys.dm_exec_sessions
	WHERE database_id  = db_id('McCollog_' + @company + DB_NAME())
	EXEC(@kill)		
	set @cmd = 'Test2'

	set @cmd = concat('drop database [McCollog_',@company,DB_NAME(),']')
	exec(@cmd)
end try
begin catch
end catch
set @cmd = concat('CREATE DATABASE [McCollog_',@company,DB_NAME(),']')
begin try
	exec(@cmd)
end try
begin catch
	set @msg = ERROR_MESSAGE()
	RAISERROR(@msg, 10, 1) WITH NOWAIT	
end catch

--declare @includeMcUsers bit
--declare @blockedProcessThreshold char(2)


set @cmd = concat('CREATE TABLE [McCollog_',@company,DB_NAME(),'].[dbo].[TraceLogSetup](
	[logDrive] [char](1) NOT NULL,[includeBGT] [bit] NOT NULL,[includeMcUsers] [bit] NOT NULL,[enableMcUsersSchJob] [bit] NOT NULL,[blockedProcessThreshold] [char](2) NOT NULL,[schedulingEnabled] [bit] NOT NULL,[schedules] [nvarchar](max) NOT NULL,[duration] [int] NOT NULL,[durationPlan] [int] NOT NULL,
	[durationWaits] [int] NOT NULL,[getExecutionPlan] [bit] NOT NULL,[maxRolloverFiles] [int] NOT NULL,[cpuThresholdActivated] [bit] NOT NULL,
	[cpuThreshold] [int] NOT NULL,[cpuUtilCheckInterval] [int] NOT NULL,[usePlanCache] [bit] NOT NULL,[baselineMode] [bit] NOT NULL,
	[issueReplicationTimeInterval] [int] NOT NULL
)')
begin try
	exec(@cmd)
end try
begin catch
	set @msg = ERROR_MESSAGE()
	RAISERROR(@msg, 10, 1) WITH NOWAIT	
end catch

--if  @enableMcUsersSchJob = 1
--	begin
set @cmd = concat('CREATE TABLE [McCollog_',@company,DB_NAME(),'].[dbo].[MaconomyUsers](
	[SessionID] [int] NOT NULL,[LoginTime] [datetime] NOT NULL,[McUserName] [varchar](255) NOT NULL,[SystemLoginName] [nvarchar](255) NULL,
	CONSTRAINT [PK_MaconomyUsers] PRIMARY KEY CLUSTERED ([SessionID] ASC,[LoginTime] ASC,[McUserName] ASC))')
begin try
	exec(@cmd)
end try
begin catch
	set @msg = ERROR_MESSAGE()
	RAISERROR(@msg, 10, 1) WITH NOWAIT	
end catch
--	end -- if
set @cmd = concat('CREATE TABLE [McCollog_',@company,DB_NAME(),'].[dbo].[TraceLogSchedules](
	[SchNo] [int] NULL,[StartDate] [date] NULL,[StartTime] [time](7) NULL,[EndDate] [date] NULL,[EndTime] [time](7) NULL,
	[StartDateTime] [datetime] NOT NULL,[EndDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_TraceLogSchedules] PRIMARY KEY CLUSTERED ([StartDateTime] ASC,[EndDateTime] ASC))')
begin try
	exec(@cmd)
end try
begin catch
	set @cmd = concat('delete from [McCollog_',@company,DB_NAME(),'].[dbo].[TraceLogSchedules]')
	exec(@cmd)
end catch

-- Save TraceLog setup to McCollog:
set @cmd = concat('insert into [McCollog_',@company,DB_NAME(),'].[dbo].[TraceLogSetup] values(''',@logDrive,''',',@includeBGT,',',@includeMcUsers,',',@enableMcUsersSchJob,',''',@blockedProcessThreshold,''',',
    @schedulingEnabled,',''',@schedules,''',',@duration,',',
	@durationPlan,',',@durationWaits,',',@getExecutionPlan,',',@maxRolloverFiles,',',@cpuThresholdActivated,',',@cpuThreshold,',',@cpuUtilCheckInterval,',',@usePlanCache,
	',',@baselineMode,',',@issueReplicationTimeInterval,')')

begin try
	exec(@cmd)
end try
begin catch
end catch

-- Check for blocking sessions:
set @cmd = concat('
use ',DB_NAME(),'
SELECT DISTINCT
    SUBSTRING(CAST(SYSDATETIME() AS VARCHAR(28)), 1, 28) AS CurrentTime,
    SUBSTRING(DB_NAME(rWaiting.database_id),1,10) AS [Database],
	rWaiting.blocking_session_id AS BlockingSID,
    rBlocking.transaction_id AS BlockingTranID,
    SUBSTRING(uBlocking.USERNAME, 1, 14) AS BlockingUser,
    rWaiting.session_id AS WaitingSID,
    rWaiting.transaction_id AS WaitingTranID,
    SUBSTRING(uWaiting.USERNAME, 1, 14) AS WaitingUser,
    rWaiting.wait_time/1000 AS WaitingSeconds,
    SUBSTRING((CASE lWaiting.resource_type WHEN ''OBJECT'' THEN OBJECT_NAME(lWaiting.resource_associated_entity_id, lWaiting.resource_database_id) WHEN ''DATABASE'' THEN DB_NAME(lWaiting.resource_database_id) ELSE (SELECT OBJECT_NAME(pat.[object_id], lWaiting.resource_database_id) FROM sys.partitions pat WHERE pat.hobt_id = lWaiting.resource_associated_entity_id) END), 1, 30) AS ObjectName,
    (SELECT SUBSTRING(text, (pBlocking.stmt_start/2) + 1, ((CASE pBlocking.stmt_end WHEN -1 THEN DATALENGTH(text) ELSE pBlocking.stmt_end END - pBlocking.stmt_start)/2) + 1) FROM sys.dm_exec_sql_text(pBlocking.sql_handle)) AS BlockingSQLText,
    (SELECT SUBSTRING(text, (pWaiting.stmt_start/2) + 1, ((CASE pWaiting.stmt_end WHEN -1 THEN DATALENGTH(text) ELSE pWaiting.stmt_end END - pWaiting.stmt_start)/2) + 1) FROM sys.dm_exec_sql_text(pWaiting.sql_handle)) AS WaitingSQLText
into [McCollog_',@company,DB_NAME(),'].[dbo].[ShowBlockingSessions]
FROM
    sys.sysprocesses AS pWaiting
    INNER JOIN sys.sysprocesses AS pBlocking ON pBlocking.spid = pWaiting.blocked
    INNER JOIN sys.dm_exec_requests AS rWaiting ON rWaiting.session_id = pWaiting.spid
    LEFT JOIN sys.dm_exec_requests AS rBlocking ON rBlocking.session_id = pBlocking.spid
    INNER JOIN sys.dm_tran_locks AS lWaiting ON lWaiting.request_session_id = rWaiting.session_id AND lWaiting.request_owner_id = rWaiting.transaction_id
    LEFT JOIN dbo.MACONOMY_USERS AS uWaiting ON uWaiting.SESSIONID = pWaiting.spid
    LEFT JOIN dbo.MACONOMY_USERS AS uBlocking ON uBlocking.SESSIONID = pBlocking.spid
WHERE
    pWaiting.dbid = DB_ID()
ORDER BY
    WaitingSeconds DESC')
exec(@cmd)
--set @cmd = concat('use [McCollog_',@company,DB_NAME(),']
--select count(*) from ShowBlockingSessions')
--set @numberRows = (select exec(@cmd))

if @usePlanCache = 1
	goto UsePlanCache

UseExtendedEvents:
set @sessionName = 'TraceLog ' + upper(DB_NAME())
IF EXISTS (SELECT name FROM sys.server_event_sessions WHERE name = concat('McAlyzer ',@sessionName))
	begin
		set @cmd = 'DROP EVENT SESSION [McAlyzer ' + @sessionName + '] ON SERVER'
		exec(@cmd)
		print 'Existing Extended Event "McAlyzer ' + @sessionName + '" deleted.'
	end -- if

set @filename = concat('''',@logDrive,':\TraceLogs\',@sessionName,' ',' ',REPLACE(LEFT(SYSDATETIME(),CHARINDEX('.',SYSDATETIME())-1),':','-'))

-- Define Extended Event session:
set @cmd = concat('
CREATE EVENT SESSION [McAlyzer ',@sessionName,'] ON SERVER ')
if @getWaitStats = 1
	set @cmd = concat(@cmd,'
ADD EVENT sqlos.wait_info(
    ACTION(
		sqlserver.database_id,
		sqlserver.plan_handle,
		sqlserver.query_hash,
		sqlserver.query_plan_hash,
		sqlserver.session_id,
		sqlserver.sql_text
		)
    WHERE ([duration]>=(' + @durationWaits + ') AND [sqlserver].[query_hash]<>(0) AND [sqlserver].[database_name]=' + @dbName + ')),')

set @cmd = concat(@cmd,'
ADD EVENT sqlserver.blocked_process_report(
    ACTION(
		package0.last_error,
		sqlos.task_time,
		sqlserver.is_system,
		sqlserver.plan_handle,
		sqlserver.query_hash,
		sqlserver.query_plan_hash,
		sqlserver.session_id,
		sqlserver.sql_text,
		sqlserver.username)
    --WHERE ([database_name]=' + @dbName + ')
	),

ADD EVENT sqlserver.lock_deadlock_chain(
    ACTION(
		package0.event_sequence,
		sqlserver.database_id,
		sqlserver.database_name,
		sqlserver.is_system,
		sqlserver.plan_handle,
		sqlserver.query_hash,
		sqlserver.query_plan_hash,
		sqlserver.session_id,
		sqlserver.sql_text,
		sqlserver.transaction_id,
		sqlserver.username)
	--WHERE ([database_name]=' + @dbName + ')
	),

ADD EVENT sqlserver.lock_escalation(
    ACTION(
		sqlserver.database_id,
		sqlserver.database_name,
		sqlserver.is_system,
		sqlserver.plan_handle,
		sqlserver.query_hash,
		sqlserver.query_plan_hash,
		sqlserver.session_id,
		sqlserver.sql_text,
		sqlserver.transaction_id,
		sqlserver.username)
	--WHERE ([database_name]=' + @dbName + ')
	),

ADD EVENT sqlserver.locks_lock_waits(
    ACTION(
		package0.event_sequence,
		sqlserver.database_id,
		sqlserver.database_name,
		sqlserver.is_system,
		sqlserver.query_hash,
		sqlserver.query_plan_hash,
		sqlserver.session_id,
		sqlserver.sql_text,
		sqlserver.transaction_id,
		sqlserver.username)
    WHERE ([sqlserver].[database_name]=' + @dbName + ')
	),

ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1),collect_statement=(1)
    ACTION(
		sqlserver.database_id,
		sqlserver.plan_handle,
		sqlserver.query_hash,
		sqlserver.query_plan_hash,
		sqlserver.session_id,
		sqlserver.sql_text)
     WHERE ([duration]>=(',@duration,') AND [sqlserver].[query_hash]<>(0) AND [sqlserver].[database_name]=',@dbName,')),

ADD EVENT sqlserver.sql_statement_completed(
    ACTION(
		sqlserver.database_id,
		sqlserver.plan_handle,
		sqlserver.query_hash,
		sqlserver.query_plan_hash,
		sqlserver.session_id,
		sqlserver.sql_text)
    WHERE ([duration]>=(',@duration,') AND [sqlserver].[query_hash]<>(0) AND [sqlserver].[database_name]=',@dbName,'))')
if @getExecutionPlan = 1
	set @cmd = concat(@cmd,'
,
ADD EVENT sqlserver.query_post_execution_showplan(
    ACTION(
		sqlserver.database_id,
		sqlserver.plan_handle,
		sqlserver.query_hash,
		sqlserver.query_plan_hash,
		sqlserver.session_id,
		sqlserver.sql_text)

    WHERE ([sqlos].[task_execution_time]>=(',@durationPlan,') AND [sqlserver].[query_hash]<>(0) AND [sqlserver].[database_name]=',@dbName,')),
	
ADD EVENT sqlserver.xml_deadlock_report(
    ACTION(
		package0.event_sequence,
		sqlos.cpu_id,
		sqlserver.database_id,
		sqlserver.database_name,
		sqlserver.is_system,
		sqlserver.plan_handle,
		sqlserver.query_hash,
		sqlserver.query_plan_hash,
		sqlserver.session_id,
		sqlserver.sql_text,
		sqlserver.transaction_id,
		sqlserver.username))
')
set @cmd = concat(@cmd,'


WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,
    STARTUP_STATE=OFF)')

-- Create Extended Event session:
begin try
	execute(@cmd)
	print 'Extended Event "McAlyzer ' + @sessionName + '" created succesfully.'
end try
begin catch
	print 'Extended Event "McAlyzer ' + @sessionName + '" could not be created.'
	print concat('Error: ',ERROR_MESSAGE())
	print 'Please send this message to Deltek Engineering!'
	print ''
	print 'Script terminated.'
	goto ScriptEnd
end catch

-- Start Extended Event session:
if @cpuThresholdActivated = 0 and @schedulingEnabled = 0
	begin
		begin try
			set @cmd =concat('ALTER EVENT SESSION [McAlyzer ',@sessionName,'] ON SERVER ',
				'ADD TARGET package0.event_file(SET filename=',@filename,'.xel','''',
				',max_file_size=(128),max_rollover_files=(',@maxRolloverFiles,'),metadatafile=N',@filename,'.xem','''',')')
			exec(@cmd)
			if @schedulingEnabled = 0
				begin
					set @cmd = concat('alter event session [McAlyzer ',@sessionName,'] on server state = START')
					exec(@cmd)
					if exists (select name from sys.server_event_sessions where name = concat('McAlyzer ',@sessionName))
						print concat('Extended Event "McAlyzer ',@sessionName,'" started succesfully.')
				end -- if
		end try
		begin catch
			print concat('Extended Event "McAlyzer ',@sessionName,'" did not start:')
			print concat('Error: ',ERROR_MESSAGE())
			print ''
			print 'Please send this message to Deltek Engineering!'
			print 'Script terminated.'
			goto ScriptEnd
		end catch
end --if

--use [msdb]
TestBreakPoint:
DECLARE @jobId BINARY(16)
declare @jobName nvarchar(255)

if @schedulingEnabled = 0
	goto CreateScheduledTask
EnableTraceScheduler:
-- Scheduling enabled:
declare @noSchedules int
declare @scheduleTmp nvarchar(40)
declare @pos1 int
declare @tmpStr nvarchar(40)
declare @counter int = 1
declare @startDateTmp date
declare @startTimeTmp time
declare @endDateTmp date
declare @endTimeTmp time
declare @startDateTime datetime
declare @endDateTime datetime
declare @endDateTimeTest datetime

--create table ##Schedules (SchNo int,StartDate date,StartTime time,EndDate date,EndTime time,StartDateTime datetime,EndDateTime datetime)

-- Validate date and time in @schedules:
set @noSchedules = (len(@schedules collate database_default) - len(replace(@schedules collate database_default,N'&',N'')))
set @schedules = replace(@schedules collate database_default,N' ',N'')
set @schedules = replace(@schedules collate database_default,char(9),N'')
set @schedules = replace(@schedules collate database_default,char(10),N'')
set @schedules = replace(@schedules collate database_default,char(13),N'')

while @noSchedules > 0
	begin
		set @pos1 = charindex(N'&',@schedules collate database_default)
		set @scheduleTmp = left(@schedules collate database_default,@pos1)
		set @pos1 = charindex(N',',@schedules collate database_default) - 1
		set @tmpStr = left(@scheduleTmp collate database_default,@pos1)
		if ISDATE(replace(@tmpStr collate database_default,N'T',N' ')) = 0
			begin
				print concat('Invalid date/time: ',@tmpStr)
				print concat('Please correct schedule no.',@counter,' in the "Scheduler Settings" section at the top of this script.')
				print ''
				print 'Script terminated'
				goto ScriptEnd
			end -- if
		set @startDateTmp = left(@scheduleTmp collate database_default,10)
		set @startTimeTmp = substring(@scheduleTmp collate database_default,12,8)
		set @endDateTmp = substring(@scheduleTmp collate database_default,21,10)
		set @endTimeTmp = substring(@scheduleTmp collate database_default,32,8)
		set @startDateTime = convert(datetime,convert(char(8),@startDateTmp,112) + ' ' + convert(char(8),@startTimeTmp,108))
		set @endDateTime = convert(datetime,convert(char(8),@endDateTmp,112) + ' ' + convert(char(8),@endTimeTmp,108))
		-- Check if @startDateTime comes before @endDateTime:
		if @startDateTime > @endDateTime
			begin
				print concat('Error in schedule no.',@counter,': The end time (',@endDateTime,') must not come before the start time (',@startDateTime,')')
				print concat('Please correct schedule no.',@counter,' in the "Scheduler Settings" section at the top of this script.')
				print ''
				print 'Script terminated'
				goto ScriptEnd
			end -- if
		-- Test for overlapping schedules:
		if @counter > 1
			begin
				set @cmd = concat('select top 1 EndDateTime into ##Result from [McCollog_',@company,DB_NAME(),'].[dbo].[TraceLogSchedules] order by EndDateTime desc')
				exec(@cmd)
				set @endDateTimeTest = (select top 1 EndDateTime from ##Result)
				drop table ##Result
				if @endDateTimeTest > @startDateTime
					begin
						print concat('Schedule no.',@counter-1,' and no.',@counter,' overlaps.')
						print concat('Please correct schedule no.',@counter-1,' and no.',@counter,' in the "Scheduler Settings" section at the top of this script.')
						print ''
						print 'Script terminated'
						goto ScriptEnd
					end -- if
			end -- if
		set @cmd = concat('insert into [McCollog_',@company,DB_NAME(),'].[dbo].[TraceLogSchedules] values(''',@counter,''',''',@startDateTmp,''',''',@startTimeTmp,''',''',
			@endDateTmp,''',''',@endTimeTmp,''',''',@startDateTime,''',''',@endDateTime,''')')
		begin try
			exec(@cmd)
		end try
		begin catch
			print ERROR_MESSAGE()
			print concat('Error in schedule no.',@counter,': All the schedules must be unique.')
			print concat('Please correct schedule no.',@counter,' in the "Scheduler Settings" section at the top of this script.')
			print ''
			print 'Script terminated'
			goto ScriptEnd
		end catch
		set @schedules = substring(@schedules collate database_default,41,len(@schedules collate database_default))
		set @counter = @counter + 1
		set @noSchedules = @noSchedules - 1
	end -- while


-- Schedule McAlyzer SQL Trace jobs:
set @counter = 1
if object_id('tempdb..##TraceLogSchedules') is not null drop table ##TraceLogSchedules
set @cmd = concat('SELECT [StartDate],[StartTime],[EndDate],[EndTime],[StartDateTime],[EndDateTime] into ##TraceLogSchedules FROM [McCollog_',@company,DB_NAME(),'].[dbo].[TraceLogSchedules]')
exec(@cmd)
set @noSchedules = (SELECT count([StartDate]) FROM ##TraceLogSchedules)
use [msdb]
declare ScheduleCursor cursor for
SELECT [StartDate],[StartTime],[EndDate],[EndTime],[StartDateTime],[EndDateTime] FROM ##TraceLogSchedules
open ScheduleCursor
fetch next from ScheduleCursor into @startDateTmp,@startTimeTmp,@endDateTmp,@endTimeTmp,@startDateTime,@endDateTime
while @noSchedules > 0
	begin
		set @jobId = NULL
		--set @tmpStr = replace(@startDateTmp,'-','')
		set @startDate = convert(int,replace(@startDateTmp,'-',''))
		set @startTime = convert(int,replace(left(@startTimeTmp,8),':',''))
		set @endDate = convert(int,replace(@endDateTmp,'-',''))
		set @endTime = convert(int,replace(left(@endTimeTmp,8),':',''))
		set @jobName = concat(N'McAlyzer SQL Trace ',@dbName2,' - ',replace(convert(varchar,@startDateTime,120),':','-'),' - Start ',@counter)
		begin try
			exec msdb.dbo.sp_delete_job @job_name =@jobName, @delete_unused_schedule=1
		end try
		begin catch
		end catch
		--set @cmd = ''alter event session [McAlyzer ' + @sessionName + '] on server state = START''
		set @tmpStr = replace(convert(varchar,@startDateTime,120),':','-')
		set @cmd1 = concat(N'
declare @dbName varchar(255)
declare @sessionActive bit
declare @filename varchar(255)
declare @sessionName varchar(255)
declare @jobName varchar(255)
declare @cmd varchar(max)

set @dbName = ''',@dbName3,''' -- <==== DB NAME
set @sessionName = ''McAlyzer TraceLog '' + upper(@dbName)
--set @filename = concat('''''''',''',@logDrive,':\TraceLogs\'',@sessionName,'' '',''',@tmpStr,''')
set @filename = concat('''''''',''',@logDrive,':\TraceLogs\'',@sessionName,'' '',REPLACE(LEFT(SYSDATETIME(),CHARINDEX(''.'',SYSDATETIME())-1),'':'',''-''))
set @jobName = ''Maconomy User SPID '' + upper(@dbName) + ''''

SET NOCOUNT ON

begin try
	-- Check if target exists before adding it:
	if (select count(S.event_session_id) from sys.server_event_sessions as S
		inner join sys.server_event_session_targets as T
		on S.event_session_id = T.event_session_id
		where S.name = @sessionName) = 0
		begin
			set @cmd =''ALTER EVENT SESSION ['' + @sessionName + ''] ON SERVER '' +
			''ADD TARGET package0.event_file(SET filename='' + @filename + ''.xel'' + '''''''' + '',max_file_size=(128),max_rollover_files=(',@maxRolloverFiles,'),metadatafile=N'' + 
			@filename + ''.xem'' + '''''''' + '')''
			exec(@cmd)
		end -- if
end try
begin catch
	print ERROR_MESSAGE()
end catch
begin try
	set @cmd = ''ALTER EVENT SESSION ['' + @sessionName + ''] ON SERVER
	STATE = START''
	exec(@cmd)
	--print ''Extended Event "McAlyzer TraceLog" started: ''
end try
begin catch
	--print concat(''Extended Event "McAlyzer TraceLog" NOT started: '',ERROR_MESSAGE())
end catch
exec(@cmd)
begin try
EXEC msdb.dbo.sp_update_job @job_name=@jobName,@enabled=1
end try
begin catch
end catch')
		begin try
			EXEC msdb.dbo.sp_add_job @job_name=@jobName, 
					@enabled=1, 
					@notify_level_eventlog=0, 
					@notify_level_email=0, 
					@notify_level_netsend=0, 
					@notify_level_page=0, 
					@delete_level=3, 
					@description=N'No description available.', 
					@category_name=N'[Uncategorized (Local)]', 
					@owner_login_name=N'sa', @job_id = @jobId OUTPUT
			EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start Extended Event', 
					@step_id=1, 
					@cmdexec_success_code=0, 
					@on_success_action=1, 
					@on_success_step_id=0, 
					@on_fail_action=1, 
					@on_fail_step_id=0, 
					@retry_attempts=0, 
					@retry_interval=0, 
					@os_run_priority=0, @subsystem=N'TSQL', 
					@command= @cmd1, 
					@database_name=N'master', 
					@flags=0
			EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
			EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Start Extended Events', 
					@enabled=1, 
					@freq_type=1, 
					@freq_interval=0, 
					@freq_subday_type=0, 
					@freq_subday_interval=0, 
					@freq_relative_interval=0, 
					@freq_recurrence_factor=0, 
					@active_start_date=@startDate, 
					@active_end_date=@endDate, 
					@active_start_time=@startTime, 
					@active_end_time=@endTime
			begin try
				EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = @@SERVERNAME
				print concat('Scheduled job "',@jobName,'" created succesfully.')
				--print ''
			end try
			begin catch
				--set @msg = ERROR_MESSAGE()
				--RAISERROR(@msg, 10, 1) WITH NOWAIT
			end catch
		end try
		begin catch
			-- Delete scheduled jobs:
			print 'Scheduled job "' + @jobName + '" NOT created succesfully.'
			print ERROR_MESSAGE()
			if exists (select job_id from msdb.dbo.sysjobs_view where name = @jobName)
				begin
					exec msdb.dbo.sp_delete_job @job_name =@jobName, @delete_unused_sahedule=1
					print 'Existing scheduled job "' + @jobName + '" deleted.'
					--print ERROR_MESSAGE()
				end -- if
		end catch
		-- Create Stop job:
		set @jobId = NULL
		set @jobName = concat(N'McAlyzer SQL Trace ',@dbName2,' - ',replace(convert(varchar,@endDateTime,120),':','-'),' - Stop ',@counter)
		begin try
			exec msdb.dbo.sp_delete_job @job_name =@jobName, @delete_unused_schedule=1
		end try
		begin catch
		end catch
		set @cmd1 = concat(N'declare @cmd varchar(max)
			set @cmd = ''alter event session [McAlyzer ',@sessionName,'] on server state = STOP
			alter event session [McAlyzer ',@sessionName,'] on server DROP TARGET package0.event_file''
			exec(@cmd)
			begin try
				EXEC msdb.dbo.sp_update_job @job_name=''Maconomy User SPID ',upper(@dbName3),''',@enabled=0
			end try
			begin catch
			end catch')
		begin try
			EXEC msdb.dbo.sp_add_job @job_name=@jobName, 
					@enabled=1, 
					@notify_level_eventlog=0, 
					@notify_level_email=0, 
					@notify_level_netsend=0, 
					@notify_level_page=0, 
					@delete_level=3, 
					@description=N'No description available.', 
					@category_name=N'[Uncategorized (Local)]', 
					@owner_login_name=N'sa', @job_id = @jobId OUTPUT
			EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Stop Extended Event', 
					@step_id=1, 
					@cmdexec_success_code=0, 
					@on_success_action=1, 
					@on_success_step_id=0, 
					@on_fail_action=1, 
					@on_fail_step_id=0, 
					@retry_attempts=0, 
					@retry_interval=0, 
					@os_run_priority=0, @subsystem=N'TSQL', 
					@command= @cmd1, 
					@database_name=N'master', 
					@flags=0
			EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
			EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Stop Extended Events', 
					@enabled=1, 
					@freq_type=1, 
					@freq_interval=0, 
					@freq_subday_type=0, 
					@freq_subday_interval=0, 
					@freq_relative_interval=0, 
					@freq_recurrence_factor=0, 
					@active_start_date=@endDate, 
					@active_end_date=@endDate, 
					@active_start_time=@endTime, 
					@active_end_time=@endTime 
			begin try
				EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = @@SERVERNAME
				print 'Scheduled job "' + @jobName + '" created succesfully.'
				--print ''
			end try
			begin catch
				set @msg = ERROR_MESSAGE()
				RAISERROR(@msg, 10, 1) WITH NOWAIT
			end catch
		end try
		begin catch
			-- Delete scheduled jobs:
			print 'Scheduled job "' + @jobName + '" NOT created succesfully.'
			print ERROR_MESSAGE()
			if exists (select job_id from msdb.dbo.sysjobs_view where name = @jobName)
				begin
					exec msdb.dbo.sp_delete_job @job_name =@jobName, @delete_unused_schedule=1
					print 'Existing scheduled job "' + @jobName + '" deleted.'
					print ERROR_MESSAGE()
				end -- if
		end catch
		set @counter = @counter + 1
		set @noSchedules = @noSchedules - 1
		fetch next from ScheduleCursor into @startDateTmp,@startTimeTmp,@endDateTmp,@endTimeTmp,@startDateTime,@endDateTime
	end -- while
close ScheduleCursor
deallocate ScheduleCursor
drop table ##TraceLogSchedules

CreateScheduledTask:
if @enableMcUsersSchJob = 1
	begin
		declare @jobEnabled bit = 1
		if @schedulingEnabled = 1
			set @jobEnabled = 0
		set @jobName = N'Maconomy User SPID ' + @dbName2
		set @jobId = NULL
		begin try
		EXEC  msdb.dbo.sp_add_job @job_name=@jobName, 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=2, 
				@notify_level_page=2, 
				@delete_level=0, 
				@category_name=N'[Uncategorized (Local)]', 
				@owner_login_name=N'sa', @job_id = @jobId OUTPUT

		EXEC msdb.dbo.sp_add_jobserver @job_name=@jobName, @server_name =  @@SERVERNAME

		set @cmd1 = concat(N'
		begin try
			insert into [McCollog_',@company,@dbName3,'].dbo.MaconomyUsers
			SELECT
			 M.SESSIONID as SessionID
			,S.login_time as LoginTime
			,M.USERNAME as McUserName
			,S.login_name as SystemLoginName
			FROM [',@dbName3,'].dbo.MACONOMY_USERS M
			left join master.sys.dm_exec_sessions S on M.SESSIONID = S.session_id
			where S.login_time is not null
		end try
		begin catch
		end catch')
		EXEC msdb.dbo.sp_add_jobstep @job_name=@jobName, @step_name=N'Get Maconomy User SPID''s', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=3, 
				@on_fail_action=3, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=@cmd1, 
				@database_name=N'master', 
				@flags=0

		EXEC msdb.dbo.sp_update_job @job_name=@jobName, 
				@enabled=@jobEnabled, 
				@start_step_id=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=2, 
				@notify_level_page=2, 
				@delete_level=0, 
				@description=N'', 
				@category_name=N'[Uncategorized (Local)]', 
				@owner_login_name=N'sa', 
				@notify_email_operator_name=N'', 
				@notify_page_operator_name=N''

		DECLARE @schedule_id int
		EXEC msdb.dbo.sp_add_jobschedule @job_name=@jobName, @name=N'5 min.', 
				@enabled=1, 
				@freq_type=4, 
				@freq_interval=1, 
				@freq_subday_type=4, 
				@freq_subday_interval=5, 
				@freq_relative_interval=0, 
				@freq_recurrence_factor=1, 
				@active_start_date=@startDate, 
				@active_end_date=@endDate, 
				@active_start_time=@startTime, 
				@active_end_time=@endTime, @schedule_id = @schedule_id OUTPUT
		end try
		begin catch
			-- Delete scheduled jobs:
			--set @msg = ERROR_MESSAGE()
			--RAISERROR(@msg, 10, 1) WITH NOWAIT
			if exists (select job_id from msdb.dbo.sysjobs_view where name = @jobName)
				begin
					--print concat('Error: ',ERROR_MESSAGE())
					exec msdb.dbo.sp_delete_job @job_name =@jobName, @delete_unused_schedule=1
					print 'Existing scheduled job "' + @jobName + '" deleted.'
				end -- if
			goto CreateScheduledTask
		end catch
		print 'Scheduled job "' + @jobName + '" created succesfully.'
	end -- if
if @cpuThresholdActivated = 1
	goto CreateSchTaskStartXETrace
else
	goto ScriptEnd

CreateSchTaskStartXETrace:
set @jobId = NULL
set @jobName = N'McAlyzer DB CPU Util Check ' + @dbName2
if exists (select job_id from msdb.dbo.sysjobs_view where name = @jobName)
	begin
		exec msdb.dbo.sp_delete_job @job_name =@jobName, @delete_unused_schedule=1
		print 'Existing scheduled job "' + @jobName + '" deleted.'
	end -- if
set @cmd1 = concat(N'use ',@dbName3,'

declare @pct decimal (5, 2) = 0 
declare @dbName varchar(255)
declare @cpuThreshold decimal (5, 2)
declare @sessionActive bit
declare @filename varchar(255)
declare @sessionName varchar(255)
declare @cmd varchar(max)

set @dbName = ''',@dbName3,''' -- <==== DB NAME
set @sessionName = ''McAlyzer TraceLog '' + upper(@dbName)
set @filename = concat('''''''',''',@logDrive,':\TraceLogs\'',@sessionName,'' '',REPLACE(LEFT(SYSDATETIME(),CHARINDEX(''.'',SYSDATETIME())-1),'':'',''-''))

SET NOCOUNT ON

set @cpuThreshold = ',@cpuThreshold,'; -- <==== CPU THRESHOLD

with CPU_Per_Db
	as
	(select 
		dmpa.DatabaseID
		, DB_Name(dmpa.DatabaseID) as [Database]
		, SUM(dmqs.total_worker_time) as CPUTimeAsMS
		from sys.dm_exec_query_stats dmqs 
	CROSS APPLY 
	(select 
		CONVERT(int, value) as [DatabaseID] 
		from sys.dm_exec_plan_attributes(dmqs.plan_handle)
		where attribute = N''dbid'') dmpa group by dmpa.DatabaseID)
   
select
	[Database] 
	,[CPUTimeAsMS] 
	 ,CAST([CPUTimeAsMS] * 1.0 / SUM([CPUTimeAsMS]) over() * 100.0 as decimal(5, 2)) as [CPU_util]
	into #cpuUtil from CPU_Per_Db
	order by [CPUTimeAsMS] desc
if (select top 1 CPU_util from #cpuUtil where [Database] = @dbName) is not null
	set @pct = (select top 1 CPU_util from #cpuUtil where [Database] = @dbName)
print @pct
drop table #cpuUtil 

if @pct >= @cpuThreshold
	begin
		IF EXISTS (SELECT name FROM sys.server_event_sessions WHERE name = @sessionName)
			begin
				begin try
					-- Check if target exists before adding it:
					if (select count(S.event_session_id) from sys.server_event_sessions as S
						inner join sys.server_event_session_targets as T
						on S.event_session_id = T.event_session_id
						where S.name = @sessionName) = 0
						begin
							set @cmd =''ALTER EVENT SESSION ['' + @sessionName + ''] ON SERVER '' +
							''ADD TARGET package0.event_file(SET filename='' + @filename + ''.xel'' + '''''''' + '',max_file_size=(128),max_rollover_files=(20),metadatafile=N'' + 
							@filename + ''.xem'' + '''''''' + '')''
							exec(@cmd)
						end -- if
				end try
				begin catch
					print ERROR_MESSAGE()
				end catch
				begin try
					set @cmd = ''ALTER EVENT SESSION ['' + @sessionName + ''] ON SERVER	STATE = START
					alter event session ['' + @sessionName + ''] on server DROP TARGET package0.event_file''
					exec(@cmd)
					print ''Extended Event "McAlyzer TraceLog" started: ''
				end try
				begin catch
					print concat(''Extended Event "McAlyzer TraceLog" NOT started: '',ERROR_MESSAGE())
				end catch
			end -- if
	end -- if
else
	begin
		IF EXISTS (SELECT name FROM sys.server_event_sessions WHERE name = @sessionName)
			begin
				begin try
					set @cmd = ''ALTER EVENT SESSION ['' + @sessionName + ''] ON SERVER STATE = STOP''
					exec(@cmd)
					print ''Extended Event "McAlyzer TraceLog" stopped''
				end try
				begin catch
					print ERROR_MESSAGE()
				end catch
			end -- if
	end -- else')

SET @jobId = NULL
begin try
	EXEC msdb.dbo.sp_add_job @job_name=@jobName, 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'[Uncategorized (Local)]', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check DB CPU Utilization', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=3, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command= @cmd1, 
			@database_name=@dbName2, 
			@flags=0
	EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'CheckSchedule', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=4, 
			@freq_subday_interval=@cpuUtilCheckInterval, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20200707, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959 
	begin try
		EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = @@SERVERNAME
	end try
	begin catch
	end catch
	print 'Scheduled job "' + @jobName + '" created succesfully.'
	print ''
end try
begin catch
	-- Delete scheduled jobs:
	print 'Scheduled job "' + @jobName + '" NOT created succesfully.'
	print ERROR_MESSAGE()
	if exists (select job_id from msdb.dbo.sysjobs_view where name = @jobName)
		begin
			exec msdb.dbo.sp_delete_job @job_name =@jobName, @delete_unused_schedule=1
			--print 'Existing scheduled job "' + @jobName + '" deleted.'
			--print ERROR_MESSAGE()
		end -- if
end catch
goto ScriptEnd

UsePlanCache:
IF OBJECT_ID('PlanCache') IS NULL
	begin
		set @cmd = concat(N'
		CREATE TABLE [McCollog_',@company,DB_NAME(),'].[dbo].[PlanCache](
			[creation_time] [datetime] NOT NULL,
			[last_execution_time] [datetime] NOT NULL,
			[query_hash] [binary](8) NOT NULL,
			[query_plan_hash] [binary](8) NOT NULL,
			[session_id] [smallint] NULL,
			[execution_count] [bigint] NULL,
			[mc_user_name] [varchar](255) NULL,
			[sys_login_name] [nvarchar](128) NULL,
			[cacheobjtype] [nvarchar](50) NULL,
			[objtype] [nvarchar](20) NULL,
			[db_name] [nvarchar](128) NULL,
			[query_plan] [xml] NULL,
			[last_rows] [bigint] NULL,
			[last_elapsed_time] [bigint] NULL,
			[min_elapsed_time] [bigint] NULL,
			[max_elapsed_time] [bigint] NULL,
			[blocking_session_id] [smallint] NULL,
			[blocking_mc_user] [varchar](255) NULL,
			[lock_timeout] [int] NULL,
			[wait_resource] [nvarchar](256) NULL,
			[last_wait_type] [nvarchar](60) NULL,
			[wait_time] [int] NULL,
		 CONSTRAINT [PK_PlanCache] PRIMARY KEY CLUSTERED 
		([creation_time] ASC,[last_execution_time] ASC,[query_hash] ASC,[query_plan_hash] ASC)
			WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]')
		begin try
			exec (@cmd)
		end try
		begin catch
		end catch
	end -- if

-- Create scheduled task GetPlanCache:
--declare @jobName varchar(255)
set @jobName = concat('GetPlanCache ',DB_NAME())
	if exists (select job_id from msdb.dbo.sysjobs_view where name = @jobName)
	begin
		begin try
			exec msdb.dbo.sp_delete_job @job_name =@jobName, @delete_unused_schedule=1
			--print 'Old scheduled job "' + @jobName + '" deleted'
		end try
		begin catch
		end catch
	end -- if
set @jobName = concat(N'GetPlanCache ',DB_NAME())

--DECLARE @jobId BINARY(16)
set @jobId = NULL
EXEC msdb.dbo.sp_add_job @job_name=@jobName, 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT

--EXEC msdb.dbo.sp_add_jobserver @job_name=@jobName, @server_name =  @@SERVERNAME
set @cmd = concat(N'use [',DB_NAME(),']

insert into [McCollog_',@company,DB_NAME(),'].dbo.PlanCache
SELECT 
	query_stats.creation_time
	,query_stats.last_execution_time
	,query_stats.query_hash
	,query_stats.query_plan_hash
	,exec_requests.session_id
	,query_stats.execution_count
	,(select top 1 USERNAME from MACONOMY_USERS where SESSIONID=exec_requests.session_id) as mc_user_name
	,(select top 1 login_name from master.sys.dm_exec_sessions where session_id=exec_requests.session_id) as sys_login_name
	,cached_plans.cacheobjtype
	,cached_plans.objtype
	,DB_NAME() as [db_name]
	,query_plan.query_plan
	,query_stats.last_rows
	,query_stats.last_elapsed_time
	,query_stats.min_elapsed_time
	,query_stats.max_elapsed_time
	,exec_requests.blocking_session_id
	,(select top 1 USERNAME from MACONOMY_USERS where SESSIONID=exec_requests.blocking_session_id) as blocking_mc_user
	,exec_requests.lock_timeout
	,exec_requests.wait_resource
	,exec_requests.last_wait_type
	,exec_requests.wait_time
  FROM sys.dm_exec_cached_plans as cached_plans
  full outer join sys.dm_exec_query_stats as query_stats on cached_plans.plan_handle = query_stats.plan_handle
  OUTER APPLY sys.dm_exec_query_plan(cached_plans.plan_handle) as query_plan
  full outer join sys.dm_exec_requests as exec_requests on exec_requests.query_plan_hash = query_stats.query_plan_hash
  where [dbid]=DB_ID() and query_plan.query_plan is not null and query_stats.query_hash is not null
ORDER BY query_stats.last_execution_time desc')

begin try
	EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'PlanCache', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=3, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=@cmd,
			@database_name=@dbName2, 
			@flags=0
	EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'GetPlanCacheSchedule', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=@freqSubdayType,      -- <== 1: Once a day, 2: Seconds interval, 4: Minutes interval
			@freq_subday_interval=@issueReplicationTimeInterval, -- Interval
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20200821, 
			@active_end_date=20200828, 
			@active_start_time=0, 
			@active_end_time=235959 
	EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	if @baselineMode = 1 and @testMode = 0
		print 'New scheduled job "' + @jobName + '" started in baseline mode'
	else
		print 'New scheduled job "' + @jobName + '" started'
end try
begin catch
	print ''
	print 'New scheduled job "' + @jobName + '" could not be created.'
	print concat('Error: ',ERROR_MESSAGE())
	print 'Please send this message to Deltek Engineering (Maconomy)!'
	print ''
	print 'Script terminated.'
	goto ScriptEnd
end catch

ScriptEnd:

