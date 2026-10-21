USE tempdb
go
-- Restore this database (backup is in download material)
RESTORE DATABASE AnotherDB FROM DISK = 'C:\Temp\AnotherDB.bak'
WITH MOVE 'AnotherDB'     TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\AnotherDB.mdf',
     MOVE 'AnotherDB_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\AnotherDB.ldf'
go

-- Move to this database and try to impersonate dbo.
USE AnotherDB
go
EXECUTE AS USER = 'dbo'
go
REVERT
go

-- This fails. Here is the reason: the owner_sid in sys.databases does
-- not match dbo in the database.
SELECT owner_sid FROM sys.databases WHERE name = db_name()
UNION ALL
SELECT sid FROM sys.database_principals WHERE name = 'dbo'

go
-- Remedy is to change the owner. And while we're at it, let's follow best
-- practice and create an SQL login which exists solely to own that database.
DECLARE @sql nvarchar(MAX)
SELECT @sql = concat(
     'CREATE LOGIN AnotherDB$owner WITH PASSWORD = ''', newid(), '''')
EXEC(@sql)
ALTER LOGIN AnotherDB$owner DISABLE
ALTER AUTHORIZATION ON DATABASE::AnotherDB TO AnotherDB$owner
go
-- Try to impersonate dbo again.
EXECUTE AS USER = 'dbo'
go
REVERT
