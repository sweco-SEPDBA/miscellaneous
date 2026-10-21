/*
    Purpose
    -------
    Create/configure a *least-privilege* SQL Server login/user for monitoring an instance
    (based on Redgate Monitor documented requirements).

    Assumptions
    -----------
    - You will monitor this SQL Server instance using the principal: [sql_monitor_account]
    - You run this as a sysadmin (or equivalent) on the instance.
    - If you want SQL Audit monitoring (Redgate Monitor Enterprise), see the SQL Audit section.

    Notes
    -----
    - This script is written to be re-runnable (idempotent) where practical.
    - It creates:
        - A server LOGIN (if missing)
        - A database USER in msdb, tempdb, and every user database (if missing)
        - Grants/role memberships required for monitoring
*/

SET NOCOUNT ON;

DECLARE @LoginName sysname = N'sql_monitor_account';

--------------------------------------------------------------------------------
-- 1) Create the server LOGIN (Windows or SQL login)
--    Choose ONE of the following approaches:
--    A) Windows login (recommended)  -> CREATE LOGIN [DOMAIN\user] FROM WINDOWS;
--    B) SQL login                    -> CREATE LOGIN ... WITH PASSWORD = ...
--
-- This script creates a SQL login only if it doesn't exist.
-- If you use a Windows login, comment out this section and create the login accordingly.
--------------------------------------------------------------------------------
IF SUSER_ID(@LoginName) IS NULL
BEGIN
    -- CHANGE THIS PASSWORD and store it securely if you use SQL authentication.
    -- Consider enforcing policy/expiration depending on your standards.
    DECLARE @Sql nvarchar(max) =
        N'CREATE LOGIN ' + QUOTENAME(@LoginName) + N'
          WITH PASSWORD = ''ChangeMe_ToA_StrongPassword!'',
               CHECK_POLICY = ON,
               CHECK_EXPIRATION = ON;';
    EXEC (@Sql);
END
GO

--------------------------------------------------------------------------------
-- 2) Ensure the msdb USER exists and grant msdb role memberships
--    Redgate requirements:
--      - Member of db_datareader in msdb
--      - Member of SQLAgentReaderRole in msdb
--------------------------------------------------------------------------------
USE msdb;
GO

IF DATABASE_PRINCIPAL_ID(N'sql_monitor_account') IS NULL
BEGIN
    -- Create a database user mapped to the server login.
    CREATE USER [sql_monitor_account] FOR LOGIN [sql_monitor_account];
END
GO

-- Add to msdb db_datareader (read access to msdb tables/views)
IF IS_ROLEMEMBER(N'db_datareader', N'sql_monitor_account') = 0
BEGIN
    ALTER ROLE [db_datareader] ADD MEMBER [sql_monitor_account];
END
GO

-- Add to msdb SQLAgentReaderRole (read SQL Agent metadata such as jobs, history)
IF IS_ROLEMEMBER(N'SQLAgentReaderRole', N'sql_monitor_account') = 0
BEGIN
    ALTER ROLE [SQLAgentReaderRole] ADD MEMBER [sql_monitor_account];
END
GO

--------------------------------------------------------------------------------
-- 3) Server-level permissions
--    Redgate requirements:
--      - VIEW ANY DEFINITION (read object definitions/metadata)
--      - VIEW SERVER STATE (read DMVs at server scope)
--      - ALTER TRACE (only if collecting trace data)
--      - ALTER ANY EVENT SESSION (for Extended Events monitoring)
--      - EXECUTE on xp_readerrorlog (read SQL Server error log)
--------------------------------------------------------------------------------
USE master;
GO

-- Read metadata definitions (procedures, views, etc.) across the instance
GRANT VIEW ANY DEFINITION TO [sql_monitor_account];
GO

-- Read server-level DMV/state information
GRANT VIEW SERVER STATE TO [sql_monitor_account];
GO

-- Needed only if you enable trace data collection (comment out if not needed)
GRANT ALTER TRACE TO [sql_monitor_account];
GO

-- Required to manage/read Extended Events sessions used by monitoring
GRANT ALTER ANY EVENT SESSION TO [sql_monitor_account];
GO

-- Allow reading error logs via xp_readerrorlog
GRANT EXECUTE ON [sys].[xp_readerrorlog] TO [sql_monitor_account];
GO

--------------------------------------------------------------------------------
-- 4) Database-level permissions on ALL databases
--    Redgate requirements:
--      - VIEW DATABASE STATE on all databases (read DB-scoped DMVs/state)
--      - SELECT on sys.sql_expression_dependencies on all databases
--
--    Also ensures the database USER exists in each database.
--------------------------------------------------------------------------------
DECLARE @db sysname, @cmd nvarchar(max);

DECLARE dbs CURSOR FAST_FORWARD FOR
SELECT name
FROM sys.databases
WHERE state_desc = N'ONLINE'
  -- Exclude databases where creating users is not allowed/meaningful
  AND name NOT IN (N'master', N'tempdb', N'msdb') ;  -- master handled at server scope; model optional

OPEN dbs;
FETCH NEXT FROM dbs INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cmd = N'
USE ' + QUOTENAME(@db) + N';

-- Create the user if it does not exist in this database
IF DATABASE_PRINCIPAL_ID(N''sql_monitor_account'') IS NULL
BEGIN
    CREATE USER [sql_monitor_account] FOR LOGIN [sql_monitor_account];
END;

-- Grant VIEW DATABASE STATE (needed for DB-scoped DMVs)
GRANT VIEW DATABASE STATE TO [sql_monitor_account];

-- Grant SELECT on dependency metadata view (required by Redgate Monitor)
GRANT SELECT ON [sys].[sql_expression_dependencies] TO [sql_monitor_account];
';
    EXEC sp_executesql @cmd;

    FETCH NEXT FROM dbs INTO @db;
END

CLOSE dbs;
DEALLOCATE dbs;
GO

--------------------------------------------------------------------------------
-- 5) tempdb permissions (choose ONE option)
--
-- Option A (higher privilege): add to db_owner in tempdb
--   - This is what Redgate lists as one option.
--   - Least privilege is usually NOT db_owner; prefer Option B if supported/available.
--
-- Option B (preferred least privilege): avoid tempdb db_owner by enabling the setting
--   in the Redgate Monitor repository database (see next section).
--------------------------------------------------------------------------------

/*** OPTION A: Grant tempdb db_owner (comment out if using Option B) ***/
USE tempdb;
GO

IF DATABASE_PRINCIPAL_ID(N'sql_monitor_account') IS NULL
BEGIN
    CREATE USER [sql_monitor_account] FOR LOGIN [sql_monitor_account];
END
GO

IF IS_ROLEMEMBER(N'db_owner', N'sql_monitor_account') = 0
BEGIN
    ALTER ROLE [db_owner] ADD MEMBER [sql_monitor_account];
END
GO

/*
    OPTION B: (Recommended) Reduce tempdb permissions required
    -----------------------------------------------------------
    Run the next section ONLY if:
      - You have the Redgate Monitor repository database available (example: [RedGateMonitor])
      - You prefer not to grant tempdb db_owner
    If you enable Option B, you should typically REMOVE the tempdb db_owner membership above.
*/

--------------------------------------------------------------------------------
-- 6) Redgate Monitor repository setting (OPTION B for tempdb)
--    This is executed AGAINST the Redgate Monitor repository database.
--    It reduces/avoids the need for tempdb db_owner.
--------------------------------------------------------------------------------
/*
USE [RedGateMonitor];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM [settings].[KeyValuePairs]
    WHERE [KeyName] = 'ReducePermissionsRequiredOnTempDb'
)
BEGIN
    INSERT INTO [settings].[KeyValuePairs] ([KeyName],[KeyValue],[KeyValueType])
    VALUES ('ReducePermissionsRequiredOnTempDb','True','BOOLEAN');
END
ELSE
BEGIN
    UPDATE [settings].[KeyValuePairs]
    SET [KeyValue] = 'True',
        [KeyValueType] = 'BOOLEAN'
    WHERE [KeyName] = 'ReducePermissionsRequiredOnTempDb';
END
GO
*/

--------------------------------------------------------------------------------
-- 7) SQL Audit permissions (ONLY if you use Redgate Monitor Enterprise SQL Audit)
--
-- Two choices per Redgate documentation:
--   Option 1 (broad): CONTROL SERVER
--   Option 2 (minimum): ALTER ANY SERVER AUDIT + VIEW SERVER SECURITY AUDIT
--
-- For least privilege, use Option 2.
--------------------------------------------------------------------------------

/*** OPTION 1 (broad, not least-privilege): ***/
-- GRANT