-- Global primary create ag
-- Note in a migration scenario. This should all ready exist.
--:Connect SESTODS074.sweco.se\SESQL35T
--CREATE AVAILABILITY GROUP [SWSQL02TA]  
--FOR DATABASE DB01,DB02
--REPLICA ON N'SESTODS074.sweco.se\SESQL35T' WITH (ENDPOINT_URL = N'TCP://SESTODS074.sweco.se:5022',  
--    FAILOVER_MODE = AUTOMATIC,  
--    AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,  
--    BACKUP_PRIORITY = 50,  
--    SECONDARY_ROLE(ALLOW_CONNECTIONS = NO),  
--    SEEDING_MODE = AUTOMATIC),  
--N'SESTODS075.sweco.se\SESQL35T' WITH (ENDPOINT_URL = N'TCP://SESTODS075.sweco.se:5022',  
--    FAILOVER_MODE = AUTOMATIC,  
--    AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,  
--    BACKUP_PRIORITY = 50,  
--    SECONDARY_ROLE(ALLOW_CONNECTIONS = NO),  
--    SEEDING_MODE = AUTOMATIC);  
--GO

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Prepare primary AG

----------------------------------------------------------------------------------------------
-- On Primary primary

-- Create enpoint, should exist
--:Connect SESTODS074.sweco.se\SESQL35T
--CREATE ENDPOINT [hadr_endpoint]  
--    STATE=STARTED   
--    AS TCP (LISTENER_PORT=5022)   
--    FOR DATABASE_MIRRORING (ROLE=ALL);  
--GO

-- Make sure it listens on all ip:s
:Connect SESTODS074.sweco.se\SESQL35T
ALTER ENDPOINT [hadr_endpoint]
    AS TCP (LISTENER_IP = ALL)

-- Add listener should all ready exist	
--:Connect SESTODS074.sweco.se\SESQL35T
--ALTER AVAILABILITY GROUP [SWSQL02TA]
--ADD LISTENER N'SWSQL02TL' (WITH IP((N'172.18.78.108', N'255.255.255.0')),PORT=1433);
--GO

-- Give user rights to enpoint for all service accounts. Even the account running services on secondary ag

:Connect SESTODS074.sweco.se\SESQL35T
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\msvc_SESTOCL023$]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\svc_sql_SESTODS061]




----------------------------------------------------------------------------------------------
-- Prepare Primary secondary

-- Should exist
--:Connect SQL02
--ALTER AVAILABILITY GROUP [SWSQL02TA] JOIN  
--ALTER AVAILABILITY GROUP [SWSQL02TA] GRANT CREATE ANY DATABASE  
--GO

 
:Connect SESTODS075.sweco.se\SESQL35T
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\msvc_SESTOCL023$]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\svc_sql_SESTODS061]

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Prepare secondary AG


----------------------------------------------------------------------------------------------
-- Secondary primary 
:Connect SESTODS072.sweco.se\SWSQL04TC
CREATE AVAILABILITY GROUP [SWSQL05TA]  
FOR  
REPLICA ON N'SESTODS072\SWSQL04TC' WITH (ENDPOINT_URL = N'TCP://SESTODS072.sweco.se:5022',  
    FAILOVER_MODE = MANUAL,  
    AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,  
    BACKUP_PRIORITY = 50,  
    SECONDARY_ROLE(ALLOW_CONNECTIONS = NO),  
    SEEDING_MODE = AUTOMATIC),  
N'SESTODS073\SWSQL04TC' WITH (ENDPOINT_URL = N'TCP://SESTODS073.sweco.se:5022',  
    FAILOVER_MODE = MANUAL,  
    AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,  
    BACKUP_PRIORITY = 50,  
    SECONDARY_ROLE(ALLOW_CONNECTIONS = NO),  
    SEEDING_MODE = AUTOMATIC);  
GO

-- Create enpoint
:Connect SESTODS072.sweco.se\SWSQL04TC
CREATE ENDPOINT [hadr_endpoint]  
    STATE=STARTED   
    AS TCP (LISTENER_PORT=5022)   
    FOR DATABASE_MIRRORING (ROLE=ALL);  
GO

-- Make sure it listens on all ip:s
:Connect SESTODS072.sweco.se\SWSQL04TC
ALTER ENDPOINT [hadr_endpoint]
    AS TCP (LISTENER_IP = ALL)
	
-- Give user rights to enpoint for all service accounts. Even the account running services on secondary ag

:Connect SESTODS072.sweco.se\SWSQL04TC
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\msvc_SESTOCL023$]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\svc_sql_SESTODS061]


----------------------------------------------------------------------------------------------
-- Secondary secondary 
:Connect SESTODS073.sweco.se\SWSQL04TC
ALTER AVAILABILITY GROUP [SWSQL05TA] JOIN  
ALTER AVAILABILITY GROUP [SWSQL05TA] GRANT CREATE ANY DATABASE  
GO


-- Create enpoint
:Connect SESTODS073.sweco.se\SWSQL04TC
CREATE ENDPOINT [hadr_endpoint]  
    STATE=STARTED   
    AS TCP (LISTENER_PORT=5022)   
    FOR DATABASE_MIRRORING (ROLE=ALL);  
GO

-- Make sure it listens on all ip:s
:Connect SESTODS073.sweco.se\SWSQL04TC
ALTER ENDPOINT [hadr_endpoint]
    AS TCP (LISTENER_IP = ALL)
	
-- Give user rights to enpoint for all service accounts. Even the account running services on secondary ag

:Connect SESTODS073.sweco.se\SWSQL04TC
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\msvc_SESTOCL023$]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\svc_sql_SESTODS061]


-- Add listener on secondary ag run on secondary primary
:Connect SESTODS072.sweco.se\SWSQL04TC
ALTER AVAILABILITY GROUP [SWSQL05TA]  
    ADD LISTENER N'SWSQL05TL' ( WITH IP ( (N'172.18.78.37',N'255.255.255.0') ) , PORT = 1433);    
GO


----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Prepare distributed AG

-- Run on global primary
-- Create the distributed ag
:Connect SESTODS074.sweco.se\SESQL35T
CREATE AVAILABILITY GROUP [DISTRIBUTED_AG]  
   WITH (DISTRIBUTED)  
   AVAILABILITY GROUP ON  
      'SWSQL02TA' WITH    
      (  
         LISTENER_URL = 'tcp://SWSQL02TL.sweco.se:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC  
      ),  
      'SWSQL05TA' WITH    
      (  
         LISTENER_URL = 'tcp://SWSQL05TL.sweco.se:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC  
      );    
GO

-- Secondary Primary
-- join second ag to distributed ag
:Connect SESTODS072.sweco.se\SWSQL04TC
ALTER AVAILABILITY GROUP [DISTRIBUTED_AG]  
   JOIN  
   AVAILABILITY GROUP ON  
      'SWSQL02TA' WITH
      (  
         LISTENER_URL = 'tcp://SWSQL02TL.sweco.se:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC  
      ),  
        'SWSQL05TA' WITH
      (  
         LISTENER_URL = 'tcp://SWSQL05TL.sweco.se:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC  
      );    
GO

--Global primary
-- Chagned distributed ag to synchronous commit in global primary
:Connect SESTODS074.sweco.se\SESQL35T
ALTER AVAILABILITY GROUP [DISTRIBUTED_AG]
 MODIFY
 AVAILABILITY GROUP ON
  'SWSQL02TA' WITH
  (
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
  ),
  'SWSQL05TA' WITH
  (
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
  );
GO

--Run on secondary primary 
-- Cange distributed ag to synchronous commit in second ag (why is this needed?)
:Connect SESTODS072.sweco.se\SWSQL04TC
ALTER AVAILABILITY GROUP [DISTRIBUTED_AG]
 MODIFY
 AVAILABILITY GROUP ON
  'SWSQL02TA' WITH
  (
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
  ),
  'SWSQL05TA' WITH
  (
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
  );

GO

























 

:Connect SESTODS074.sweco.se\SESQL35T
ALTER AVAILABILITY GROUP DISTRIBUTED_AG SET (ROLE = SECONDARY);





-- Run this query on the Global Primary and the forwarder
-- Check the results to see if the last_hardened_lsn is the same per database on both the global primary and forwarder
-- The availability group is ready to fail over when the last_hardened_lsn is the same for both availability groups per database
--
 SELECT ag.name,
     drs.database_id,
     db_name(drs.database_id) as database_name,
     drs.group_id,
     drs.replica_id,
     drs.last_hardened_lsn
FROM sys.dm_hadr_database_replica_states drs
INNER JOIN sys.availability_groups ag ON drs.group_id = ag.group_id;
GO
 
 
SELECT *
FROM sys.dm_hadr_availability_group_states


:Connect SESTODS072.sweco.se\SWSQL04TC
ALTER AVAILABILITY GROUP DISTRIBUTED_AG FORCE_FAILOVER_ALLOW_DATA_LOSS;

