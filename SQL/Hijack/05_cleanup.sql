-- This script drops databases, logins and certificates created in the
-- other scripts.
USE master
go
IF db_id('AppDB') IS NOT NULL
BEGIN
   ALTER DATABASE AppDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE
   DROP DATABASE AppDB
END
go
IF db_id('AnotherDB') IS NOT NULL
BEGIN
   ALTER DATABASE AnotherDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE
   DROP DATABASE AnotherDB
END
go
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'DebbieOwner')
   DROP LOGIN DebbieOwner
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'DevDave')
   DROP LOGIN DevDave
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'AppLogin')
   DROP LOGIN AppLogin
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'AnotherDB$owner')
   DROP LOGIN AnotherDB$owner
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'SIGN [AppDB].[dbo].[ReloadTableOne]')
   DROP LOGIN "SIGN [AppDB].[dbo].[ReloadTableOne]"
IF EXISTS (SELECT * FROM sys.certificates WHERE name = 'SIGN [AppDB].[dbo].[ReloadTableOne]')
   DROP CERTIFICATE "SIGN [AppDB].[dbo].[ReloadTableOne]"

IF EXISTS (select * from sys.triggers where name = 'EvilDdlTri') DROP Trigger EvilDdlTri ON Database

IF EXISTS (SELECT * FROM sys.sysusers where name = 'DebbieOwner') DROP USER DebbieOwner 

IF EXISTS (SELECT * FROM sys.tables where name = 'TableOne') DROP TABLE TableOne



IF EXISTS (select * from sys.procedures where name = 'DavesSP')
    DROP procedure DavesSP