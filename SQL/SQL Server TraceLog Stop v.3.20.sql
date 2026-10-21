-- Stops the SQL Server Extended Events log session.
-- Version: 3.20
-- Date: 2021-06-28
-- Created by: Morten Rasted, Deltek Engineering (Maconomy)

declare @sessionName varchar(255)
declare @cmd varchar(max)
declare @msg varchar(255)
declare @jobName1 varchar(255)
declare @jobName2 varchar(255)
declare @jobName3 varchar(255)
declare @jobName4 varchar(255)
declare @jobName5 varchar(255)
declare @companyName varchar(255)
declare @logDrive char(1)
declare @includeBGT bit
declare @duplRec int
declare @includeMcUsers bit
declare @enableMcUsersSchJob bit

SET NOCOUNT ON

set @includeMcUsers = 1

-- Cleanup temp tables:
begin try
	if object_id('tempdb..##SysInfo') is not null drop table ##SysInfo
	if object_id('tempdb..##IndexInfo') is not null drop table ##SysInfo
	if object_id('tempdb..##IndexStatisticsTemp') is not null drop table ##SysInfo
	if object_id('tempdb..##IndexStats') is not null drop table ##SysInfo
	if object_id('tempdb..##IndexTemp') is not null drop table ##SysInfo
	if object_id('tempdb..##TableInfo') is not null drop table ##SysInfo
	if object_id('tempdb..##LockEscalation') is not null drop table ##SysInfo
	if object_id('tempdb..##Views') is not null drop table ##SysInfo
	if object_id('tempdb..##IndexUsage') is not null drop table ##SysInfo
	if object_id('tempdb..##MissingIndexes') is not null drop table ##SysInfo
	if object_id('tempdb..##DupIndexes') is not null drop table ##SysInfo
	if object_id('tempdb..##logDrive') is not null drop table ##logDrive
	if object_id('tempdb..##includeBGT') is not null drop table ##includeBGT
end try
begin catch
end catch

EXEC sp_configure 'show advanced options', 1 
RECONFIGURE
EXEC sp_configure 'blocked process threshold', 5
RECONFIGURE
EXEC sp_configure 'show advanced options', 0 
RECONFIGURE
DBCC traceon(1222,-1)

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

set @companyName = (select top 1 NAME1 from COMPANYINFORMATION where THENUMBER = 1)
if @companyName is null
	set @companyName = 'Test'
if CHARINDEX(' ',@companyName) > 0
	begin
		set @companyName = LEFT(@companyName,CHARINDEX(' ',@companyName)-1) + '_'
	end -- if
else
	set @companyName = @companyName + '_'
if CHARINDEX('\',@companyName) > 0 or CHARINDEX('/',@companyName) > 0
	begin
		set @companyName = REPLACE(@companyName,'\','')
		set @companyName = REPLACE(@companyName,'/','')
	end -- if

-- Stop Extended Event sessions:
set @sessionName = 'TraceLog ' + upper(DB_NAME())
begin try
	set @cmd = 'ALTER EVENT SESSION [McAlyzer ' + @sessionName + '] ON SERVER STATE = STOP'
	exec(@cmd)
	print 'Extended Event "McAlyzer ' + @sessionName + '" stopped"'
end try
begin catch
	--print ERROR_MESSAGE()
end catch
begin try
	set @cmd = 'DROP EVENT SESSION [McAlyzer ' + @sessionName + '] ON SERVER'
	exec(@cmd)
	print 'Extended Event "McAlyzer ' + @sessionName + '" deleted"'
end try
begin catch
	--print ERROR_MESSAGE()
end catch

-- Delete scheduled jobs:
declare jobsCursor cursor for
select name from msdb.dbo.sysjobs_view
where name like concat('McAlyzer SQL Trace ',upper(DB_NAME()),'%')
or name = 'Maconomy User SPID ' + upper(DB_NAME())
or name like concat('McAlyzer DB CPU Util Check ',upper(DB_NAME()),'%')
or name like concat('GetPlanCache ',upper(DB_NAME()),'%')
open jobsCursor
fetch next from jobsCursor into @jobName1
while @@FETCH_STATUS = 0
	begin
		begin try
			exec msdb.dbo.sp_delete_job @job_name =@jobName1, @delete_unused_schedule=1
			print 'Scheduled job "'+ @jobName1 + '" deleted'
		end try
		begin catch
		end catch
	end -- while
close jobsCursor
deallocate jobsCursor

GetSystemInfo:
--declare @cmd varchar(7000)
--declare @msg varchar(255)
declare @trcFolder varchar(255)
declare @filename varchar(255)
declare @dbName varchar(255)
declare @company varchar(255)
declare @columnStore varchar(3)
declare @compLevel int
declare @srvEdition varchar(50)
declare @srvPrdLevel varchar(50)
declare @prdBuild int
declare @fileGroups varchar(500)
declare @fgName varchar(50)
declare @dbCount INT
declare @cpuCount int
declare @counter INT
declare @coresSocket sql_variant
declare @vmType varchar(20)
declare @socketCount sql_variant
declare @softNUMAConf sql_variant
declare @numaCount sql_variant
declare @maxdop sql_variant
declare @ctfp sql_variant
declare @queryOptHotfixes sql_variant
declare @optAdHoc sql_variant -- OPTIMIZE_FOR_AD_HOC_WORKLOADS
declare @legacyCarEst sql_variant
declare @minSqlMem sql_variant
declare @maxSqlMem sql_variant
declare @maxSrvMem sql_variant
declare @memInUse sql_variant
declare @mcVer sql_variant
declare @outTbl TABLE (Servername varchar(50), SQLServerVer varchar(500), Edition varchar(500), ProductLevel varchar(500), ProductBuild INT,
	CompLevel INT, DBName varchar(50), Filegrps varchar(500), SuppClmStore varchar(3),SocketCount int, CpuCount int,CoresSocket int,[MAXDOP] sql_variant,OptFix sql_variant
	,OptAdHocFix sql_variant,LegacyCarEst sql_variant,SoftNUMAConf sql_variant,NUMACount int,VmType varchar(20))
declare @cpuInfo TABLE(cores_per_socket sql_variant,socket_count sql_variant,numa_node_count sql_variant)
declare @dbScopeConf TABLE(name sql_variant,value sql_variant)
declare @statement nvarchar(max)
declare @statement2 nvarchar(max)
declare @testString varchar(max)
declare @validDB bit = 1

SET NOCOUNT ON

-- Get information about the SQL Server and the Maconomy database:
RAISERROR (' ', 10, 1) with nowait
set @msg = 'Collecting information on the Maconomy database. This will take some minutes, please wait...'
RAISERROR (@msg, 10, 1) with nowait
RAISERROR (' ', 10, 1) with nowait

set @dbName = DB_NAME()
set @company = (select top 1 NAME1 from COMPANYINFORMATION where ROWID = 1)
if @company is null
	set @company = 'Test'
set @dbName = DB_NAME()
set @compLevel = (select compatibility_level from sys.databases where name = @dbName)
set @srvEdition = convert(varchar(20),serverproperty ('edition'))
set @srvPrdLevel = convert(varchar(20),serverproperty ('productlevel'))
set @prdBuild = convert(varchar(20),serverproperty ('ProductBuild'))
set @columnStore = case 
  when @compLevel >= 110 and (@srvEdition like 'Enterprise%' or @srvEdition like 'Developer%')
	then 'Yes'
  when @compLevel >= 130 and @srvPrdLevel != 'RTM'
	then 'Yes'
  else 'No' 
end -- case
set @fileGroups = ''
declare fgs cursor for
select CONVERT(nvarchar(50),name) from sys.filegroups
open fgs
	fetch next from fgs into @fgName
		while @@FETCH_STATUS = 0
			begin
				if @fileGroups = '' 
					set @fileGroups = @fgName
				else 
					set @fileGroups = @fileGroups + ', ' + @fgName
				fetch next from fgs into @fgName
			end -- while
close fgs
deallocate fgs

-- All SQL Server versions:
set @mcVer = (select TOP 1 concat(convert(varchar,[MAINVERSIONNUMBER]),'sp',convert(varchar,[PATCHNUMBER])) as [McVersion]
    from [dbo].[SYSTEMMAINTENANCELOG] order by ROWID desc)
set @cpuCount = (select cpu_count from sys.dm_os_sys_info)
set @testString = convert(varchar,@cpuCount)
set @ctfp = (select value from sys.configurations where configuration_id = 1538) -- Cost threshold for parallelism
set @softNUMAConf = (select value from sys.configurations where configuration_id = 1585)
if @softNUMAConf = '1' set @softNUMAConf = 'OFF'
else 
    set @softNUMAConf = 'ON (Auto)'
set @minSqlMem = (select value from sys.configurations where configuration_id = 1543) -- MB
set @minSqlMem = concat(convert(varchar,@minSqlMem),' MB')
set @maxSqlMem = (select value from sys.configurations where configuration_id = 1544) -- MB
set @maxSqlMem = concat(convert(varchar,@maxSqlMem),' MB')
set @maxSrvMem = (select maximum from sys.configurations where configuration_id = 1543) -- MB
set @maxSrvMem = concat(convert(varchar,@maxSrvMem),' MB')
set @memInUse = (select value_in_use from sys.configurations where configuration_id = 1543) -- MB
set @memInUse = concat(convert(varchar,@memInUse),' MB')
set @vmType = (select virtual_machine_type_desc from sys.dm_os_sys_info)

begin try
	-- SQL Server version >= 2016:
	set @statement = N'(select cores_per_socket,socket_count,numa_node_count from sys.dm_os_sys_info)'
	set @statement2 = N'(select name,value from sys.database_scoped_configurations)'
	insert into @cpuInfo (cores_per_socket,socket_count,numa_node_count) exec sp_executesql @statement
	insert into @dbScopeConf (name,value) exec sp_executesql @statement2
	set @coresSocket = (select cores_per_socket from @cpuInfo)
	set @socketCount = (select socket_count from @cpuInfo)
	set @numaCount = (select numa_node_count from @cpuInfo)
	set @maxdop = (select value from @dbScopeConf where name = 'MAXDOP')
	set @maxdop = concat(convert(varchar,@maxdop),' (DB)')
	set @testString = convert(varchar,@maxdop)
	set @queryOptHotfixes = (select value from @dbScopeConf where name = 'QUERY_OPTIMIZER_HOTFIXES')
	set @queryOptHotfixes = concat(convert(varchar,@queryOptHotfixes),' (DB)')
	set @optAdHoc = (select value from @dbScopeConf where name = 'OPTIMIZE_FOR_AD_HOC_WORKLOADS')
	set @optAdHoc = concat(convert(varchar,@optAdHoc),' (DB)')
	set @legacyCarEst = (select value from @dbScopeConf where name = 'LEGACY_CARDINALITY_ESTIMATION')
end try
begin catch
	-- SQL Server version < 2016:
	set @maxdop = (select value from sys.configurations where configuration_id = 1539)
	set @maxdop = concat(CONVERT(varchar,@maxdop),' (SRV)')
	set @optAdHoc = (select value from sys.configurations where configuration_id = 1581)
	set @optAdHoc = concat(convert(varchar,@optAdHoc),' (SRV)')
	set @socketCount = 'NA'
	set @coresSocket = 'NA'
	set @numaCount = 'NA'
	set @queryOptHotfixes = 'NA'
	set @legacyCarEst = 'NA'
end catch

if object_id('tempdb..##SysInfo') is not null drop table ##SysInfo
begin try
	set @cmd = concat('drop table [McCollog_',@companyName,DB_NAME(),'].dbo.SystemInfo')
	exec(@cmd)
end try
begin catch
	--Print concat('Table [McCollog_',@companyName,DB_NAME(),'].dbo.SystemInfo not dropped')
	--goto ScriptEnd
end catch

-- Check for duplicate records in JOBENTRYPAYMENTINFORMATION:
begin try
	set @duplRec = (select count(*)
	FROM JOBENTRYPAYMENTINFORMATION JEPI
	INNER JOIN (
	   SELECT MIN(ROWID) MINROWID, JOBNUMBER, JOBENTRYNUMBER, CUSTOMERNUMBER, CUSTOMERLINENUMBER, VENDORNUMBER, VENDORLINENUMBER, 
			  OPENCLOSED,INVOICENUMBER, INVOICELINENUMBER, PURCHASEORDERNUMBER, PURCHASEORDERLINENUMBER, JOBINVOICEALLOCATIONNUMBER
			  , INVOICEINSTANCEKEY 
	   FROM JOBENTRYPAYMENTINFORMATION
	   GROUP BY JOBNUMBER, JOBENTRYNUMBER, CUSTOMERNUMBER, CUSTOMERLINENUMBER, VENDORNUMBER, VENDORLINENUMBER,
				OPENCLOSED, INVOICENUMBER, INVOICELINENUMBER, PURCHASEORDERNUMBER, PURCHASEORDERLINENUMBER, JOBINVOICEALLOCATIONNUMBER
				, INVOICEINSTANCEKEY 
				) MINJEPI
	ON JEPI.JOBNUMBER=MINJEPI.JOBNUMBER AND JEPI.JOBENTRYNUMBER=MINJEPI.JOBENTRYNUMBER AND JEPI.CUSTOMERNUMBER=MINJEPI.CUSTOMERNUMBER AND JEPI.CUSTOMERLINENUMBER=MINJEPI.CUSTOMERLINENUMBER 
	AND JEPI.VENDORNUMBER=MINJEPI.VENDORNUMBER AND JEPI.VENDORLINENUMBER=MINJEPI.VENDORLINENUMBER AND JEPI.OPENCLOSED=MINJEPI.OPENCLOSED 
	AND JEPI.INVOICENUMBER=MINJEPI.INVOICENUMBER AND JEPI.INVOICELINENUMBER=MINJEPI.INVOICELINENUMBER AND JEPI.PURCHASEORDERNUMBER=MINJEPI.PURCHASEORDERNUMBER AND JEPI.PURCHASEORDERLINENUMBER=MINJEPI.PURCHASEORDERLINENUMBER AND JEPI.JOBINVOICEALLOCATIONNUMBER=MINJEPI.JOBINVOICEALLOCATIONNUMBER 
	AND JEPI.INVOICEINSTANCEKEY=MINJEPI.INVOICEINSTANCEKEY 
	WHERE JEPI.ROWID <> MINJEPI.MINROWID)
end try
begin catch
	set @duplRec = -1
end catch

if object_id('tempdb..##SysInfo') is not null drop table ##SysInfo
select @company as [Company],@mcVer as [McVersion],@@SERVERNAME as [DB Server],@@VERSION as [SQL Server Version],@srvPrdLevel as [Prod Level],@prdBuild as [Prod Build],
	 @compLevel as [Comp Level],@dbName as [DB Name],@fileGroups as [Filegroups],@columnStore as [Columnstore Index],@socketCount as [Socket Count],@cpuCount as [CPU Count],
	 @coresSocket as [Cores Per Socket],@maxdop as [MAXDOP],@ctfp as [CTFP],@queryOptHotfixes as [Query Opt Fix],@optAdHoc as [Opt for AdHoc],@legacyCarEst as [Legacy Car Est],@softNUMAConf as [Soft NUMA],
	 @numaCount as [NUMA Count],@minSqlMem as [Min SqlSrv Mem],@maxSqlMem as [Max SqlSrvMem],@maxSrvMem as [Max Srv Mem],@memInUse as [Mem In Use],@vmType as [VM Type],
	 @duplRec as [DuplRecs]
	 into ##SysInfo

set @cmd = concat('set nocount on select * into [McCollog_',@companyName,DB_NAME(),'].dbo.SystemInfo from ##SysInfo')
exec(@cmd)
drop table ##SysInfo

GetIndexDefinition:
declare @SchemaName varchar(100)
declare @TableName varchar(256)
declare @IndexName varchar(256)
declare @ColumnName varchar(512)
declare @is_unique varchar(100)
declare @IndexTypeDesc varchar(100)
declare @FileGroupName varchar(100)
declare @is_disabled varchar(100)
declare @IndexOptions varchar(max)
declare @IndexColumnId int
declare @IsDescendingKey int 
declare @IsIncludedColumn int
declare @TSQLScripCreationIndex varchar(max)
declare @TSQLScripDisableIndex varchar(max)
declare @indexes varchar(max)
declare @McIndexName varchar(255)
declare @McCollogDB varchar(255)

set @McCollogDB = concat('[McCollog_',@companyName ,DB_NAME(),']')

IF OBJECT_ID('McCollog_' + @companyName + DB_NAME()) IS NULL
	begin
		set @cmd = 'CREATE DATABASE [McCollog_' + @companyName + DB_NAME() + ']'
		begin try
			exec(@cmd)
		end try
		begin catch
		end catch
	end -- if
IF OBJECT_ID('IndexDefinition') IS NULL
	begin
		set @cmd = '
		CREATE TABLE [McCollog_' + @companyName + DB_NAME() + '].[dbo].[IndexDefinition](
			[TableName] [varchar](255) NULL,
			[IndexName] [varchar](255) NULL,
			[CreateStatement] [varchar](max) NULL
		) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]'
		begin try
			exec (@cmd)
		end try
		begin catch
		end catch
	end -- if
IF OBJECT_ID('IndexDefinition') IS NULL
	begin
		set @cmd = '
		CREATE TABLE [McCollog_' + @companyName + DB_NAME() + '].[dbo].[IndexStatistics](
			[TableName] [varchar](255) NULL,
			[IndexName] [varchar](255) NULL,
			[Stats_Stream] [varbinary](max) NULL,
			[Rows] [int] NULL,
			[Data Pages] [int] NULL
		) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]'
		begin try
			exec (@cmd)
		end try
		begin catch
		end catch
	end -- if

--goto GetIndexStatistics

if object_id('tempdb..##IndexInfo') is not null drop table ##IndexInfo
create table ##IndexInfo (TableName varchar(255),IndexName varchar(255),CreateStatement varchar(max))

-- Create a list of all the Maconomy indexes:
declare McIndexes cursor for
	select [name] from [sys].[indexes] where object_id > 100 order by object_id
open McIndexes
fetch next from McIndexes into  @McIndexName
while (@@fetch_status=0)
	begin
		set @indexes = concat(@indexes, char(13),@McIndexName)
		fetch next from McIndexes into @McIndexName
	end -- while
close McIndexes
deallocate McIndexes

-- Generate CREATE statements for the indexes:
declare CursorIndex cursor for
 select schema_name(t.schema_id) [schema_name], t.name, ix.name,
 case when ix.is_unique = 1 then 'UNIQUE ' else '' END 
 , ix.type_desc,
 case when ix.is_padded=1 then 'PAD_INDEX = ON, ' else 'PAD_INDEX = OFF, ' end
 + case when ix.allow_page_locks=1 then 'ALLOW_PAGE_LOCKS = ON, ' else 'ALLOW_PAGE_LOCKS = OFF, ' end
 + case when ix.allow_row_locks=1 then  'ALLOW_ROW_LOCKS = ON, ' else 'ALLOW_ROW_LOCKS = OFF, ' end
 + case when INDEXPROPERTY(t.object_id, ix.name, 'IsStatistics') = 1 then 'STATISTICS_NORECOMPUTE = ON, ' else 'STATISTICS_NORECOMPUTE = OFF, ' end
 + case when ix.ignore_dup_key=1 then 'IGNORE_DUP_KEY = ON, ' else 'IGNORE_DUP_KEY = OFF, ' end
 + 'SORT_IN_TEMPDB = OFF' AS IndexOptions
 , ix.is_disabled , FILEGROUP_NAME(ix.data_space_id) FileGroupName
 from sys.tables t 
 inner join sys.indexes ix on t.object_id=ix.object_id
 where ix.type>0 and ix.is_primary_key=0 and ix.is_unique_constraint=0 --and schema_name(tb.schema_id)= @SchemaName and tb.name=@TableName
 and t.is_ms_shipped=0 and t.name<>'sysdiagrams' 
 --and (ix.name like '_dev%' or ix.name like '_its%' or ix.name like '_test%' or ix.name like '_dta%')
 and CHARINDEX(ix.name,@indexes,1)>0
 order by schema_name(t.schema_id), t.name, ix.name

open CursorIndex
fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique, @IndexTypeDesc, @IndexOptions,@is_disabled, @FileGroupName
while (@@fetch_status=0)
begin
	declare @IndexColumns varchar(max)
	declare @IncludedColumns varchar(max)
 
	set @IndexColumns=''
	set @IncludedColumns=''
 
	declare CursorIndexColumn cursor for 
	select col.name, ixc.is_descending_key, ixc.is_included_column
	from sys.tables tb 
	inner join sys.indexes ix on tb.object_id=ix.object_id
	inner join sys.index_columns ixc on ix.object_id=ixc.object_id and ix.index_id= ixc.index_id
	inner join sys.columns col on ixc.object_id =col.object_id  and ixc.column_id=col.column_id
	where ix.type>0 and (ix.is_primary_key=0 or ix.is_unique_constraint=0)
	and schema_name(tb.schema_id)=@SchemaName and tb.name=@TableName and ix.name=@IndexName
	order by ixc.index_column_id
 
	open CursorIndexColumn 
	fetch next from CursorIndexColumn into  @ColumnName, @IsDescendingKey, @IsIncludedColumn
	while (@@fetch_status=0)
	begin
		if @IsIncludedColumn=0 
		set @IndexColumns=@IndexColumns + @ColumnName  + case when @IsDescendingKey=1  then ' DESC, ' else  ' ASC, ' end
		else 
		set @IncludedColumns=@IncludedColumns  + @ColumnName  +', ' 
		fetch next from CursorIndexColumn into @ColumnName, @IsDescendingKey, @IsIncludedColumn
	end --while

	close CursorIndexColumn
	deallocate CursorIndexColumn

	if @IndexColumns <> ''
		set @IndexColumns = substring(@IndexColumns, 1, len(@IndexColumns)-1)
	if @IncludedColumns <> ''
		set @IncludedColumns = case when len(@IncludedColumns) >0 then substring(@IncludedColumns, 1, len(@IncludedColumns)-1) else '' end
	set @TSQLScripCreationIndex =''
	set @TSQLScripDisableIndex =''
	set @TSQLScripCreationIndex='CREATE '+ @is_unique  +@IndexTypeDesc + ' INDEX ' +QUOTENAME(@IndexName)+' ON ' + QUOTENAME(@SchemaName) +'.'+ QUOTENAME(@TableName)+ '('+@IndexColumns+') '+ 
	case when len(@IncludedColumns)>0 
		then ' INCLUDE (' + @IncludedColumns+ ')' 
		else '' end + ' WITH (' + @IndexOptions+ ') ON ' + QUOTENAME(@FileGroupName) + ';'
	insert into ##IndexInfo (TableName,IndexName,CreateStatement) values(@TableName,@IndexName,@TSQLScripCreationIndex)
	if @is_disabled=1
		begin
			set @TSQLScripDisableIndex=  CHAR(13) +'ALTER INDEX ' +QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@SchemaName) +'.'+ QUOTENAME(@TableName) + ' DISABLE;'
			insert into ##IndexInfo (TableName,IndexName,CreateStatement) values(@TableName,@IndexName,@TSQLScripDisableIndex)
		end -- if
	fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique, @IndexTypeDesc, @IndexOptions,@is_disabled, @FileGroupName
end --while
close CursorIndex
deallocate CursorIndex

-- Get Primary Key (PK) indexes:
declare CursorIndex cursor for
 select t.name, ix.name from sys.tables t 
 inner join sys.indexes ix on t.object_id=ix.object_id
 where ix.type>0 and  (ix.is_primary_key=1 or ix.is_unique_constraint=1)
 and t.is_ms_shipped=0 and t.name<>'sysdiagrams'
 order by schema_name(t.schema_id), t.name, ix.name
 open CursorIndex
fetch next from CursorIndex into  @TableName, @IndexName
while (@@fetch_status=0)
	begin
		insert into ##IndexInfo (TableName,IndexName) values(@TableName,@IndexName)
		fetch next from CursorIndex into  @TableName, @IndexName
	end -- while
set @cmd = concat('use ',@McCollogDB,' SET NOCOUNT ON insert into IndexDefinition select TableName,IndexName,CreateStatement from ##IndexInfo')
exec(@cmd)
drop table ##IndexInfo
goto GetMcTableInfo

GetIndexStatistics:
-- Get complete index statistics with histogram:
declare @statsStream varbinary(max)
declare @rows int
declare @dataPages int

if object_id('tempdb..##IndexStatisticsTemp') is not null 
	drop table ##IndexStatisticsTemp
if object_id('tempdb..##IndexStats') is not null 
	drop table ##IndexStats

create table ##IndexStatisticsTemp (TableName varchar(255),IndexName varchar(255),[Stats_Stream] varbinary(max),[Rows] int,[Data Pages] int)
create table ##IndexStats ([Stats_Stream] varbinary(max),Rows int,[Data Pages] int)
set @cmd = concat('select TableName,IndexName into ##IndexTemp from ',@McCollogDB,'.dbo.IndexDefinition')
exec(@cmd)
declare IndexCursor cursor for
select TableName,IndexName from ##IndexTemp order by TableName,IndexName
open IndexCursor 
fetch next from IndexCursor into  @TableName, @IndexName
	while (@@fetch_status=0)
	begin
		delete from ##IndexStats
		set @cmd = concat('DBCC SHOW_STATISTICS ("[',DB_NAME(),'].dbo.',@TableName,'", [',@IndexName,']) WITH STATS_STREAM, NO_INFOMSGS')
		insert into ##IndexStats exec(@cmd)
		set @statsStream = (select top 1 [Stats_Stream] from ##IndexStats)
		set @rows = (select top 1 [Rows] from ##IndexStats)
		set @dataPages = (select top 1 [Data Pages] from ##IndexStats)
		insert into ##IndexStatisticsTemp select @TableName,@IndexName,@statsStream,@rows,@dataPages
		fetch next from IndexCursor into  @TableName, @IndexName
	end -- while
close IndexCursor
deallocate IndexCursor

set @cmd = concat('insert into ',@McCollogDB,'.dbo.IndexStatistics select TableName,IndexName,[Stats_Stream],[Rows],[Data Pages] from ##IndexStatisticsTemp')
exec(@cmd)

drop table ##IndexStats
drop table ##IndexTemp
drop table ##IndexStatisticsTemp

GetMcTableInfo:
-- Get all information on the Maconomy tables:
declare @table_name varchar(max)
declare @object_name sysname
declare @object_id int
declare @rc sql_variant

if object_id('tempdb..##TableInfo') is not null drop table ##TableInfo
create table ##TableInfo (CreateStatement varchar(max))

declare McTables CURSOR FOR
select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_TYPE='BASE TABLE' order by TABLE_NAME
OPEN McTables
fetch next from McTables into @table_name
while @@FETCH_STATUS = 0
    begin
        set @table_name = 'dbo.' + @table_name
        select 
              @object_name = '[' + s.name + '].[' + o.name + ']'
            , @object_id = o.[object_id]
        from sys.objects o with (nowait)
        JOIN sys.schemas s with (nowait) ON o.[schema_id] = s.[schema_id]
        where s.name + '.' + o.name = @table_name
            AND o.[type] = 'U'
            AND o.is_ms_shipped = 0

        declare @SQL varchar(max) = '';

        with index_column as 
        (select 
                  ic.[object_id]
                , ic.index_id
                , ic.is_descending_key
                , ic.is_included_column
                , c.name
            from sys.index_columns ic with (nowait)
            JOIN sys.columns c with (nowait) ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
            where ic.[object_id] = @object_id),
        fk_columns as 
        (select 
                  k.constraint_object_id
                , cname = c.name
                , rcname = rc.name
            from sys.foreign_key_columns k with (nowait)
            JOIN sys.columns rc with (nowait) ON rc.[object_id] = k.referenced_object_id AND rc.column_id = k.referenced_column_id 
            JOIN sys.columns c with (nowait) ON c.[object_id] = k.parent_object_id AND c.column_id = k.parent_column_id
            where k.parent_object_id = @object_id)
        select @SQL = 'create table ' + @object_name +  '(' +  STUFF((
            select ', [' + c.name + '] ' + 
                case when c.is_computed = 1
                    then 'AS ' + cc.[definition] 
                    else UPPER(tp.name) + 
                        case when tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text')
                               then '(' + case when c.max_length = -1 then 'MAX' else CAST(c.max_length as varchar(5)) end + ')'
                             when tp.name IN ('nvarchar', 'nchar', 'ntext')
                               then '(' + case when c.max_length = -1 then 'MAX' else CAST(c.max_length / 2 as varchar(5)) end + ')'
                             when tp.name IN ('datetime2', 'time2', 'datetimeoffset') 
                               then '(' + CAST(c.scale as varchar(5)) + ')'
                             when tp.name = 'decimal' 
                               then '(' + CAST(c.[precision] as varchar(5)) + ',' + CAST(c.scale as varchar(5)) + ')'
                            else ''
                        end +
                        case when c.collation_name IS NOT NULL then ' COLLATE ' + c.collation_name else '' end +
                        case when c.is_nullable = 1 then ' NULL' else ' NOT NULL' end +
                        case when dc.[definition] IS NOT NULL then ' DEFAULT' + dc.[definition] else '' end + 
                        case when ic.is_identity = 1 then ' IDENTITY(' + CAST(ISNULL(ic.seed_value, '0') as char(1)) + ',' + CAST(ISNULL(ic.increment_value, '1') as char(1)) + ')' else '' end 
                end -- case
            from sys.columns c with (nowait)
            JOIN sys.types tp with (nowait) ON c.user_type_id = tp.user_type_id
            LEFT JOIN sys.computed_columns cc with (nowait) ON c.[object_id] = cc.[object_id] AND c.column_id = cc.column_id
            LEFT JOIN sys.default_constraints dc with (nowait) ON c.default_object_id != 0 AND c.[object_id] = dc.parent_object_id AND c.column_id = dc.parent_column_id
            LEFT JOIN sys.identity_columns ic with (nowait) ON c.is_identity = 1 AND c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
            where c.[object_id] = @object_id
            order by c.column_id
            for xml path(''), TYPE).value('.', 'nvarchar(MAX)'), 1, 2, ' ')
            + ISNULL((select ', CONSTRAINT [' + k.name + '] PRIMARY KEY (' + 
                            (select STUFF((
                                 select ', [' + c.name + '] ' + case when ic.is_descending_key = 1 then 'DESC' else 'ASC' end
                                 from sys.index_columns ic with (nowait)
                                 JOIN sys.columns c with (nowait) ON c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
                                 where ic.is_included_column = 0
                                     AND ic.[object_id] = k.parent_object_id 
                                     AND ic.index_id = k.unique_index_id     
                                 for xml path(N''), TYPE).value('.', 'nvarchar(MAX)'), 1, 2, ''))+ ')'
                    from sys.key_constraints k with (nowait)
                    where k.parent_object_id = @object_id 
                        AND k.[type] = 'PK'), '') + ')' + ISNULL((select (
                select 
                     'ALTER TABLE ' + @object_name + ' with' 
                    + case when fk.is_not_trusted = 1 
                        then ' NOCHECK' 
                        else ' CHECK' 
                      end + 
                      ' ADD CONSTRAINT [' + fk.name  + '] FOREIGN KEY(' 
                      + STUFF((
                        select ', [' + k.cname + ']'
                        from fk_columns k
                        where k.constraint_object_id = fk.[object_id]
                        for xml path(''), TYPE).value('.', 'nvarchar(MAX)'), 1, 2, '')
                       + ')' +
                      ' REFERENCES [' + SCHEMA_NAME(ro.[schema_id]) + '].[' + ro.name + '] ('
                      + STUFF((
                        select ', [' + k.rcname + ']'
                        from fk_columns k
                        where k.constraint_object_id = fk.[object_id]
                        for xml path(''), TYPE).value('.', 'nvarchar(MAX)'), 1, 2, '')
                       + ')'
                    + case 
                        when fk.delete_referential_action = 1 then ' ON DELETE CASCADE' 
                        when fk.delete_referential_action = 2 then ' ON DELETE SET NULL'
                        when fk.delete_referential_action = 3 then ' ON DELETE SET DEFAULT' 
                        else '' 
                      end
                    + case 
                        when fk.update_referential_action = 1 then ' ON UPDATE CASCADE'
                        when fk.update_referential_action = 2 then ' ON UPDATE SET NULL'
                        when fk.update_referential_action = 3 then ' ON UPDATE SET DEFAULT'  
                        else '' 
                      end 
                    +  'ALTER TABLE ' + @object_name + ' CHECK CONSTRAINT [' + fk.name  + ']'
                from sys.foreign_keys fk with (nowait)
                JOIN sys.objects ro with (nowait) ON ro.[object_id] = fk.referenced_object_id
                where fk.parent_object_id = @object_id
                for xml path(N''), TYPE).value('.', 'nvarchar(MAX)')), '')
            + ISNULL(((select
                  'CREATE' + case when i.is_unique = 1 then ' UNIQUE' else '' end 
                        + ' NONCLUSTERED INDEX [' + i.name + '] ON ' + @object_name + ' (' +
                        STUFF((
                        select ', [' + c.name + ']' + case when c.is_descending_key = 1 then ' DESC' else ' ASC' end
                        from index_column c
                        where c.is_included_column = 0
                            AND c.index_id = i.index_id
                        for xml path(''), TYPE).value('.', 'nvarchar(MAX)'), 1, 2, '') + ')'  
                        + ISNULL( 'INCLUDE (' + 
                            STUFF((
                            select ', [' + c.name + ']'
                            from index_column c
                            where c.is_included_column = 1
                                AND c.index_id = i.index_id
                            for xml path(''), TYPE).value('.', 'nvarchar(MAX)'), 1, 2, '') + ')', '')  
                from sys.indexes i with (nowait)
                where i.[object_id] = @object_id
                    AND i.is_primary_key = 0
                    AND i.[type] = 2
                for xml path(''), TYPE).value('.', 'nvarchar(MAX)')
            ), '')
            insert into ##TableInfo (CreateStatement) values(@SQL)
            fetch next from McTables into @table_name
        end -- while
CLOSE McTables 
DEALLOCATE McTables

set @cmd = concat('SET NOCOUNT ON select * into [McCollog_',@companyName,DB_NAME(),'].dbo.TableInfo from ##TableInfo')
exec(@cmd)
drop table ##TableInfo

LockEscalation:
-- Get lock escalation for tables:
SELECT s.name as [Schema Name], object_name (t.object_id) as [Table Name], t.lock_escalation_desc as [Lock Escalation Desc]
into ##LockEscalation
FROM sys.tables t, sys.schemas s
WHERE s.name = 'dbo' and s.schema_id = t.schema_id order by [Table Name]
set @cmd = concat('SET NOCOUNT ON select * into [McCollog_',@companyName,DB_NAME(),'].dbo.LockEscalation from ##LockEscalation')
exec(@cmd)
drop table ##LockEscalation

GetViewsInfo:
-- Get definitions for all views:
declare @viewInfo varchar(max)
declare @viewName varchar(255)
declare @schema varchar(3)

create table ##Views (ViewDefinition varchar(max))
declare CursorViews cursor for
SELECT OBJECT_SCHEMA_NAME(v.object_id) schema_name,v.name FROM sys.views as v order by v.name
open CursorViews
fetch next from CursorViews into  @schema,@viewName
while (@@fetch_status=0)
	begin
		set @viewInfo = (select object_definition(OBJECT_ID(@viewName)) as ViewDefinition)
		set @viewInfo = replace(@viewInfo,char(9),' ')
		set @viewInfo = replace(@viewInfo,char(10),' ')
		set @viewInfo = replace(@viewInfo,char(13),' ')
		set @viewInfo = replace(@viewInfo,'  ',' ')
		set @viewInfo = replace(@viewInfo,'    ',' ')
		set @viewInfo = replace(@viewInfo,'  ',' ')
		set @viewInfo = replace(@viewInfo,'    ',' ')
		set @viewInfo = replace(@viewInfo,'    ',' ')
		set @viewInfo = replace(@viewInfo,'   ',' ')
		set @viewInfo = replace(@viewInfo,' )',')')
		insert into ##Views (ViewDefinition) values(@viewInfo)
		fetch next from CursorViews into  @schema,@viewName
	end
close CursorViews
deallocate CursorViews
set @cmd = concat('SET NOCOUNT ON select * into [McCollog_',@companyName,DB_NAME(),'].dbo.ViewInfo from ##Views')
exec(@cmd)
drop table ##Views
goto MissingIndexes

IndexUsage:
-- Get index usage statistics:
if object_id('tempdb..##IndexUsage') is not null drop table ##IndexUsage
SELECT
       sch.name + '.' + t.name AS [TableName],
       i.name AS [IndexName],
       i.index_id AS [IndexId],
       i.type_desc AS [IndexType], 
       ISNULL(user_updates,0) AS [TotalWrites],
       ISNULL(user_seeks + user_scans + user_lookups,0) AS [TotalReads],
       ISNULL(user_updates,0) - ISNULL((user_seeks + user_scans + user_lookups),0) AS [Difference],
       s.last_user_seek AS [LastUserSeek],
       s.last_user_scan AS [LastUserScan],
       s.last_user_lookup AS [LastUserLookup], 
       p.reserved_page_count * 8.0 / 1024 AS [SpaceInMB]
into ##IndexUsage
FROM sys.indexes AS i WITH (NOLOCK) 
       LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s      
       WITH (NOLOCK) ON s.object_id = i.object_id  AND i.index_id = s.index_id 
       AND s.database_id=db_id()  AND objectproperty(s.object_id,'IsUserTable') = 1 
       INNER JOIN           sys.tables                              
       AS t   WITH (NOLOCK) ON i.object_id = t.object_id 
       INNER JOIN           sys.schemas                             
       AS sch WITH (NOLOCK) ON t.schema_id = sch.schema_id 
       LEFT OUTER JOIN sys.dm_db_partition_stats AS p  
       WITH (NOLOCK) ON i.index_id = p.index_id and i.object_id = p.object_id
               WHERE  s.last_user_seek is null AND last_User_scan is null AND last_user_lookup is null
ORDER BY 7 desc

--set @filename = '"' + @trcFolder + 'IndexUsage - ' + @company + ' - ' + upper(@dbName) + '.csv"'
--set @cmd = concat('sqlcmd -Q "SET NOCOUNT ON select * from ##IndexUsage" -s; -y0 -o ',@filename)
--exec master..xp_cmdshell @cmd, NO_OUTPUT
set @cmd = 'set nocount on select * into ' + @McCollogDB + '.dbo.IndexUsage from ##IndexUsage'
exec(@cmd)
drop table ##IndexUsage

PlanGuide:
set @counter = (select count(*) from sys.plan_guides)
if  @counter > 0
	begin
		set @cmd = 'set nocount on select * into ' + @McCollogDB + '.dbo.PlanGuides from sys.plan_guides'
		exec(@cmd)		
	end -- if

MissingIndexes:
-- Get top 25 missing indexes:
if object_id('tempdb..##MissingIndexes') is not null drop table ##MissingIndexes
SELECT TOP 25 dm_mid.database_id AS DatabaseID, 
              dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) Avg_Estimated_Impact, 
              dm_migs.last_user_seek AS Last_User_Seek, 
              OBJECT_NAME(dm_mid.OBJECT_ID, dm_mid.database_id) AS [TableName], 
              'CREATE INDEX [IX_' + OBJECT_NAME(dm_mid.OBJECT_ID, dm_mid.database_id) + '_' + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns, ''), ', ', '_'), '[', ''), ']', '') + CASE
                                                  WHEN dm_mid.equality_columns IS NOT NULL
                                                  AND dm_mid.inequality_columns IS NOT NULL
                                                  THEN '_'
                                                  ELSE ''
                                                  END + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns, ''), ', ', '_'), '[', ''), ']', '') + ']' + ' ON ' + dm_mid.statement + ' (' + ISNULL(dm_mid.equality_columns, '') + CASE
                                                  WHEN dm_mid.equality_columns IS NOT NULL
                                                  AND dm_mid.inequality_columns IS NOT NULL
                                                  THEN ','
                                                  ELSE ''
END + ISNULL(dm_mid.inequality_columns, '') + ')' + ISNULL(' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement
into ##MissingIndexes
FROM sys.dm_db_missing_index_groups dm_mig
     INNER JOIN sys.dm_db_missing_index_group_stats dm_migs ON dm_migs.group_handle = dm_mig.index_group_handle
     INNER JOIN sys.dm_db_missing_index_details dm_mid ON dm_mig.index_handle = dm_mid.index_handle
WHERE dm_mid.database_ID = DB_ID()
ORDER BY Avg_Estimated_Impact DESC;
set @cmd ='set nocount on select * into ' + @McCollogDB + '.dbo.MissingIndexes from ##MissingIndexes'
exec(@cmd)
if object_id('tempdb..##MissingIndexes') is not null drop table ##MissingIndexes
goto UpdateMaconomyUsers

DuplicateIndexes:
-- Identify duplicate indexes:
declare  @First	smallint
declare  @Last	smallint
declare  @IsUnique smallint
declare  @HasNonKeyCols	char(1)
declare  @IndexType	varchar(13)
declare  @IndexColsOrder varchar(1000) 
declare  @IncludedColsOrder varchar(1000) 
declare @Indexes2 TABLE ([RowNo] smallint IDENTITY(1, 1)
					   ,[TableName] varchar(1024)
					   ,[IndexName] varchar(1024)
					   ,[IsUnique] smallint
					   ,[IndexType] varchar(13))
declare @AllIndexes TABLE ([RowNo] smallint IDENTITY(1, 1)
						  ,[TableName] varchar(1024)
						  ,[IndexName] varchar(1024)
						  ,[IndexType] varchar(13)
						  ,[KeyColumns] varchar(1024)
						  ,[NonKeyColumns] varchar(max)
						  ,[KeyColumnsOrder] varchar(1024)
						  ,[NonKeyColumnsOrder] varchar(1024)
						  ,[IsUnique] char(1)
						  ,[HasNonKeyColumns] char(1))

IF OBJECT_ID('Tempdb.dbo.#Temp') IS NOT NULL  
 DROP TABLE #Temp

SELECT o.[object_id] AS [ObjectID]
	  ,OBJECT_NAME(o.[object_id]) AS [TableName]
	  ,i.[index_id] AS [IndexID]
	  ,i.[name] AS [IndexName]
	  ,CASE i.[type]
		WHEN 0 THEN 'Heap' 
		WHEN 1 THEN 'Clustered' 
		WHEN 2 THEN 'Non-Clustered' 
		WHEN 3 THEN 'XML'
		ELSE 'Unknown' 
	   END AS [IndexType]
	  ,ic.[column_id] AS [ColumnID]
	  ,c.[name] AS [ColumnName]
	  ,ic.[is_included_column] [IncludedColumns]
	  ,i.[is_unique] AS [IsUnique]
INTO #Temp
FROM sys.indexes i
INNER JOIN sys.objects o
	ON i.object_id = o.object_id
	AND o.type = 'U' AND i.index_id > 0
INNER JOIN sys.index_columns ic
	ON i.index_id = ic.index_id
	AND i.object_id = ic.object_id
INNER JOIN sys.columns c
	ON c.column_id = ic.column_id
	AND c.object_id = ic.object_id

INSERT INTO @Indexes2
SELECT DISTINCT 
	 [TableName]
	,[IndexName]
	,[IsUnique]
	,[IndexType]
FROM #Temp

SELECT @First = MIN([RowNo]) FROM @Indexes2
SELECT @Last = MAX([RowNo]) FROM @Indexes2

WHILE @First <= @Last
BEGIN
	SET @IndexColumns		=	NULL
	SET @IncludedColumns	=	NULL
	SET @IncludedColsOrder	=	NULL
	SET @IndexColsOrder		=	NULL

	SELECT @TableName = [TableName]
		  ,@IndexName = [IndexName]
		  ,@IsUnique  = [IsUnique]
		  ,@IndexType = [IndexType]
	FROM @Indexes2 
	WHERE [RowNo] = @First

	SELECT @IndexColumns = COALESCE(@IndexColumns + ', ', '') + [ColumnName]
	FROM #Temp
	WHERE [TableName] = @TableName AND [IndexName] = @IndexName AND [IncludedColumns] = 0
	ORDER BY [IndexName], [ColumnName]

	SELECT @IncludedColumns = COALESCE(@IncludedColumns+ ', ', '') + [ColumnName]
	FROM #Temp
	WHERE [TableName] = @TableName AND [IndexName] = @IndexName AND [IncludedColumns] = 1
	ORDER BY [IndexName], [ColumnName]

	SELECT @IndexColsOrder = COALESCE(@IndexColsOrder + ', ', '') + [ColumnName]
	FROM #Temp
	WHERE [TableName] = @TableName AND [IndexName] = @IndexName AND [IncludedColumns] = 0

	SELECT @IncludedColsOrder = COALESCE(@IncludedColsOrder + ', ', '') + [ColumnName]
	FROM #Temp
	WHERE [TableName] = @TableName AND [IndexName] = @IndexName AND [IncludedColumns] = 1

	SET @HasNonKeyCols = 'N'

	IF @IncludedColumns IS NOT NULL
	BEGIN
		 SET @HasNonKeyCols = 'Y'
	END

	INSERT INTO @AllIndexes ([TableName],[IndexName],[IndexType],[IsUnique],[KeyColumns],[KeyColumnsOrder],[HasNonKeyColumns],[NonKeyColumns],[NonKeyColumnsOrder])
	SELECT @TableName
		  ,@IndexName
		  ,@IndexType
		  ,CASE @IsUnique 
			WHEN 1 THEN 'Y'
			WHEN 0 THEN 'N'
		   END
		  ,@IndexColumns
		  ,@IndexColsOrder
		  ,@HasNonKeyCols
		  ,@IncludedColumns
		  ,@IncludedColsOrder
	SET @First = @First + 1 
END

create table ##DupIndexes ([TableName] varchar(2048)
						  ,[IndexName] varchar(2048)
						  ,[IndexType] varchar(255)
						  ,[KeyColumns] varchar(max)
						  ,[NonKeyColumns] varchar(max)
						  ,[KeyColumnsOrder] varchar(max)
						  ,[NonKeyColumnsOrder] varchar(max)
						  ,[IsUnique] varchar(2048)
						  ,[HasNonKeyColumns] varchar(2048)
						  ,[DropStatement] varchar(max))
						  
insert into ##DupIndexes
SELECT DISTINCT 
		a1.[TableName]
	  ,a1.[IndexName]
	  ,a1.[IndexType]
	  ,a1.[KeyColumns]
	  ,a1.[HasNonKeyColumns]
	  ,a1.[NonKeyColumns]
	  ,a1.[KeyColumnsOrder]
	  ,a1.[NonKeyColumnsOrder]
	  ,a1.[IsUnique]
	  ,concat('DROP INDEX [',a1.[IndexName],'] ON [dbo].[',a1.[TableName],']') as DropStmt
FROM @AllIndexes a1
JOIN @AllIndexes a2
ON a1.[TableName] = a2.TableName
AND a1.[IndexName] <> a2.[IndexName]
AND a1.[KeyColumns] = a2.[KeyColumns] 
AND ISNULL(a1.[NonKeyColumns], '') = ISNULL(a2.[NonKeyColumns], '')  
WHERE a1.[IndexType] <> 'XML' 
and a1.KeyColumnsOrder = a2.KeyColumnsOrder
order by TableName,KeyColumns

set @cmd ='set nocount on select * into ' + @McCollogDB + '.dbo.DuplicateIndexes from ##DupIndexes '
exec(@cmd)
drop table ##DupIndexes

UpdateMaconomyUsers:
set @cmd = '
begin try
	insert into [McCollog_' + @companyName + DB_NAME() + '].dbo.MaconomyUsers
	SELECT
	 M.SESSIONID as SessionID
	,S.login_time as LoginTime
	,M.USERNAME as McUserName
	,S.login_name as SystemLoginName
	FROM [' + DB_NAME() + '].dbo.MACONOMY_USERS M
	left join master.sys.dm_exec_sessions S on M.SESSIONID = S.session_id
	where S.login_time is not null
end try
begin catch
end catch'
exec(@cmd)

UpdatePlanCache:
-- Update plan cache if used:
set @cmd = concat(N'use [',DB_NAME(),']
insert into [McCollog_',@companyName,DB_NAME(),'].dbo.PlanCache
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
	exec(@cmd)
	set @msg = 'Plan cache updated'
	RAISERROR (@msg, 10, 1) WITH NOWAIT
end try
begin catch
end catch

GetBGT:
begin try
	drop table ##includeBGT
end try
begin catch
end catch
set @cmd = concat('select includeBGT into ##includeBGT from [McCollog_',@companyName,DB_NAME(),'].dbo.TraceLogSetup')
exec(@cmd)
set @includeBGT = (select top 1 includeBGT from ##includeBGT)

if @includeBGT = 1
	begin
		set @cmd = concat('
		SET NOCOUNT ON
		select * into ',@McCollogDB,'.dbo.BACKGROUNDTASK from BACKGROUNDTASK
		select * into ',@McCollogDB,'.dbo.BACKGROUNDTASKEXECUTION from BACKGROUNDTASKEXECUTION
		select * into ',@McCollogDB,'.dbo.BACKGROUNDTASKLOCK from BACKGROUNDTASKLOCK
		select * into ',@McCollogDB,'.dbo.BACKGROUNDTASKLOGLINE from BACKGROUNDTASKLOGLINE
		select * into ',@McCollogDB,'.dbo.BACKGROUNDTASKPARAMETER from BACKGROUNDTASKPARAMETER')
		exec(@cmd)
	end

IncludeMcUsers:
begin try
	drop table ##includeMcUsers
end try
begin catch
end catch
set @cmd = concat('select includeMcUsers into ##includeMcUsers from [McCollog_',@companyName,DB_NAME(),'].dbo.TraceLogSetup')
exec(@cmd)
set @includeMcUsers = (select top 1 includeMcUsers from ##includeMcUsers)
if @includeMcUsers = 1
	begin
		set @cmd = concat('select * 
			into [McCollog_',@companyName,DB_NAME(),'].dbo.MACONOMY_USERS
			from MACONOMY_USERS')
		begin try
			exec(@cmd)
		end try
		begin catch
		end catch
	end -- if

QueryMemoryGrants:
set @cmd = concat('select SYSDATETIME() as [timestamp],* into ',@McCollogDB,'.dbo.QueryMemoryGrants from sys.dm_exec_query_memory_grants')
exec(@cmd)

-- Get log drive from McCollog:
begin try
	drop table ##logDrive
end try
begin catch
end catch
set @cmd = concat('select logDrive into ##logDrive from [McCollog_',@companyName,DB_NAME(),'].dbo.TraceLogSetup')
exec(@cmd)
set @logDrive = (select top 1 logDrive from ##logDrive)
if @logDrive is null
	set @logDrive = 'C'

BackupMcCollogDB:
begin try
	-- Backup the McCollog database to "C:\TraceLogs\" and drop it afterwards:
	set @msg = 'Please wait for McCollog backup to complete...'
	RAISERROR (@msg, 10, 1) WITH NOWAIT
	set @filename = concat('','',@logDrive,':\TraceLogs\McCollog_',@companyName,DB_NAME(),'_',REPLACE(LEFT(SYSDATETIME(),CHARINDEX('.',SYSDATETIME())-1),':','-'),'.bak')
	set @cmd = 'BACKUP DATABASE [McCollog_' + @companyName + DB_NAME() + '] TO DISK = N'''  + @filename + ''' with  NOFORMAT, INIT,
	NAME = N''McCollog_' + @companyName + DB_NAME() + '-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10'
	exec(@cmd)
	-- Kill active jobs on McCollog db and drop it:
	DECLARE @kill varchar(8000) = 'USE [master];';  
	SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
	FROM sys.dm_exec_sessions
	WHERE database_id  = db_id('McCollog_' + @companyName + DB_NAME())
	EXEC(@kill)			
	set @cmd = 'drop database [McCollog_' + @companyName + DB_NAME() + ']'
	exec(@cmd)
	RAISERROR ('', 10, 1) WITH NOWAIT
	--set @msg = 'Please collect all the files in "',@logDrive,':\TraceLogs\" and attach them to the Deltek RNT support case. Thank you.'
	--RAISERROR (@msg, 10, 1) WITH NOWAIT
end try
begin catch
	RAISERROR ('', 10, 1) WITH NOWAIT
	set @msg = 'Problem with McCollog database file: ' + ERROR_MESSAGE()
	RAISERROR (@msg, 10, 1) WITH NOWAIT
end catch

CloneDB:
begin try
	-- Clone the database:
	set @msg = 'Cloning database...'
	RAISERROR (@msg, 10, 1) WITH NOWAIT
	set @filename = concat('','',@logDrive,':\TraceLogs\',@companyName,DB_NAME(),'_Clone_',REPLACE(LEFT(SYSDATETIME(),CHARINDEX('.',SYSDATETIME())-1),':','-'),'.bak')
	set @cmd = concat('DBCC CLONEDATABASE (',DB_NAME(),',',@companyName,DB_NAME(),'_Clone)')
	exec(@cmd)
	--set @cmd = concat('ALTER DATABASE [',@companyName,DB_NAME(),'_Clone_','] SET  READ_ONLY WITH NO_WAIT')
	--exec(@cmd)
	set @cmd = 'BACKUP DATABASE [' + @companyName + DB_NAME() + '_Clone] TO DISK = N'''  + @filename + ''' with  NOFORMAT, INIT,
	NAME = N''' + @companyName + DB_NAME() + '_Clone -Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10'
	exec(@cmd)
	set @cmd = 'drop database [' + @companyName + DB_NAME() + '_Clone]'
	exec(@cmd)
	RAISERROR ('', 10, 1) WITH NOWAIT
	set @msg = concat('Please collect all the files in "',@logDrive,':\TraceLogs\" and attach them to the Deltek RNT support case. Thank you.')
	RAISERROR (@msg, 10, 1) WITH NOWAIT
end try
begin catch
	RAISERROR ('', 10, 1) WITH NOWAIT
	set @msg = 'Problem with clone database file: ' + ERROR_MESSAGE()
	RAISERROR (@msg, 10, 1) WITH NOWAIT
end catch

ScriptEnd:
