
######################################################################
# Migrate with distributed ag
#Basic settings (parameter setup)
$primaryPrimary = "SESTODS074.sweco.se\SESQL35T"
$primarySecondary = "SESTODS075.sweco.se\SESQL35T"
$SecondaryPrimary = "SESTODS072.sweco.se\SWSQL04TC"
$SecondarySecondary = "SESTODS073.sweco.se\SWSQL04TC"
$PrimaryListenerIP = "172.18.78.108"
$SecondaryListenerIP = "172.18.78.37"
$PrimaryAGName = "SWSQL02TA"
$SecondaryAGName = "SWSQL05TA"
$PrimaryListenerName = "SWSQL02TL"
$SecondaryListenerName = "SWSQL05TL"
$DistributedAGName = "DISTRIBUTED_AG"

######################################################################
######################################################################
# Prepare primary AG

######################################################################
# On Primary primary

# Create enpoint, should exist
$sql = @"
CREATE ENDPOINT [hadr_endpoint]  
    STATE=STARTED   
    AS TCP (LISTENER_PORT=5022)   
    FOR DATABASE_MIRRORING (ROLE=ALL);  
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql

# Make sure it listens on all ip:s
# This should all ready be the case
$sql = @"
ALTER ENDPOINT [hadr_endpoint]
    AS TCP (LISTENER_IP = ALL)
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql

# Add listener should all ready exist	
$sql = @"
ALTER AVAILABILITY GROUP [$PrimaryAGName]
ADD LISTENER N'$PrimaryListenerName' (WITH IP((N'$PrimaryListenerIP', N'255.255.255.0')),PORT=1433);
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql

# Give user rights to enpoint for all service accounts. Even the account running services on secondary ag
# This is probably needed. At least for the service account running the services on the secondary ag
$sql = @"
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\msvc_SESTOCL023$]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\svc_sql_SESTODS061]
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql



######################################################################
# Prepare Primary secondary

# Should exist
$sql = @"
ALTER AVAILABILITY GROUP [$PrimaryAGName] JOIN  
ALTER AVAILABILITY GROUP [$PrimaryAGName] GRANT CREATE ANY DATABASE  
"@
Invoke-DbaQuery -SqlInstance $primarySecondary -Query $sql


$sql = @"
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\msvc_SESTOCL023$]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\svc_sql_SESTODS061]
"@
Invoke-DbaQuery -SqlInstance $primarySecondary -Query $sql

######################################################################
######################################################################
# Prepare secondary AG


######################################################################
# Secondary primary 
$sql = @"
CREATE AVAILABILITY GROUP [$SecondaryAGName]  
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
"@
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql

# Create enpoint
$sql = @"
CREATE ENDPOINT [hadr_endpoint]  
    STATE=STARTED   
    AS TCP (LISTENER_PORT=5022)   
    FOR DATABASE_MIRRORING (ROLE=ALL);  
"@
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql

# Make sure it listens on all ip:s
$sql = @"
ALTER ENDPOINT [hadr_endpoint]
    AS TCP (LISTENER_IP = ALL)
"@
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql

# Give user rights to enpoint for all service accounts. Even the account running services on primary ag
$sql = @"
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\msvc_SESTOCL023$]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\svc_sql_SESTODS061]
"@
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql

######################################################################
# Secondary secondary 
$sql = @"
ALTER AVAILABILITY GROUP [$SecondaryAGName] JOIN  
ALTER AVAILABILITY GROUP [$SecondaryAGName] GRANT CREATE ANY DATABASE  
"@
Invoke-DbaQuery -SqlInstance $SecondarySecondary -Query $sql

# Create enpoint
$sql = @"
CREATE ENDPOINT [hadr_endpoint]  
    STATE=STARTED   
    AS TCP (LISTENER_PORT=5022)   
    FOR DATABASE_MIRRORING (ROLE=ALL);  
"@
Invoke-DbaQuery -SqlInstance $SecondarySecondary -Query $sql

# Make sure it listens on all ip:s
$sql = @"
ALTER ENDPOINT [hadr_endpoint]
    AS TCP (LISTENER_IP = ALL)
"@
Invoke-DbaQuery -SqlInstance $SecondarySecondary -Query $sql

# Give user rights to enpoint for all service accounts. Even the account running services on primary ag
$sql = @"
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\msvc_SESTOCL023$]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SWECO\svc_sql_SESTODS061]
"@
Invoke-DbaQuery -SqlInstance $SecondarySecondary -Query $sql


######################################################################
# Secondary primary again
# Add listener on secondary ag run on secondary primary
$sql = @"
ALTER AVAILABILITY GROUP [$SecondaryAGName]  
    ADD LISTENER N'$SecondaryListenerName' ( WITH IP ( (N'$SecondaryListenerIP',N'255.255.255.0') ) , PORT = 1433);    
"@
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql

######################################################################
######################################################################
# Prepare distributed AG

# Run on global primary
# Create the distributed ag
$sql = @"
CREATE AVAILABILITY GROUP [$DistributedAGName]  
    WITH (DISTRIBUTED)  
    AVAILABILITY GROUP ON  
    '$PrimaryAGName' WITH    
    (  
        LISTENER_URL = 'tcp://$PrimaryListenerName.sweco.se:5022',    
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
        FAILOVER_MODE = MANUAL,  
        SEEDING_MODE = AUTOMATIC  
    ),  
    '$SecondaryAGName' WITH    
    (  
        LISTENER_URL = 'tcp://$SecondaryListenerName.sweco.se:5022',  
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
        FAILOVER_MODE = MANUAL,  
        SEEDING_MODE = AUTOMATIC  
    );    
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql

# Secondary Primary
# join second ag to distributed ag
$sql = @"
ALTER AVAILABILITY GROUP [$DistributedAGName]  
    JOIN  
    AVAILABILITY GROUP ON  
    '$PrimaryAGName' WITH
    (  
        LISTENER_URL = 'tcp://$PrimaryListenerName.sweco.se:5022',    
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
        FAILOVER_MODE = MANUAL,  
        SEEDING_MODE = AUTOMATIC  
    ),  
        '$SecondaryAGName' WITH
    (  
        LISTENER_URL = 'tcp://$SecondaryListenerName.sweco.se:5022',  
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
        FAILOVER_MODE = MANUAL,  
        SEEDING_MODE = AUTOMATIC  
    );    
"@
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql

#Global primary
# Chagned distributed ag to synchronous commit in global primary
$sql = @"
ALTER AVAILABILITY GROUP [$DistributedAGName]
    MODIFY
    AVAILABILITY GROUP ON
    '$PrimaryAGName' WITH
    (
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
    ),
    '$SecondaryAGName' WITH
    (
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
    );
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql

#Run on secondary primary 
# Cange distributed ag to synchronous commit in second ag (why is this needed?)
$sql = @"
ALTER AVAILABILITY GROUP [$DistributedAGName]
    MODIFY
    AVAILABILITY GROUP ON
    '$PrimaryAGName' WITH
    (
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
    ),
    '$SecondaryAGName' WITH
    (
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
    );
"@
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql


######################################################################

# Primary primary
# ALTER AVAILABILITY GROUP DISTRIBUTED_AG SET (ROLE = SECONDARY);

# # Run this query on the Global Primary and the forwarder
# # Check the results to see if the last_hardened_lsn is the same per database on both the global primary and forwarder
# # The availability group is ready to fail over when the last_hardened_lsn is the same for both availability groups per database
#
# $Sql = @"
#  SELECT ag.name,
#      drs.database_id,
#      db_name(drs.database_id) as database_name,
#      drs.group_id,
#      drs.replica_id,
#      drs.last_hardened_lsn
# FROM sys.dm_hadr_database_replica_states drs
# INNER JOIN sys.availability_groups ag ON drs.group_id = ag.group_id;
# "@
# Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $Sql
# Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $Sql
$Sql = @"
SELECT
    ag.[name] AS [AG Name],
    ag.is_distributed,
    ar.replica_server_name AS [Underlying AG],
    ars.role_desc AS [Role],
    ars.synchronization_health_desc AS [Sync Status]
FROM  
    sys.availability_groups AS ag
    INNER JOIN sys.availability_replicas AS ar ON  ag.group_id = ar.group_id
    INNER JOIN sys.dm_hadr_availability_replica_states AS ars ON  ar.replica_id = ars.replica_id
WHERE 
    ag.is_distributed = 1;
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $Sql
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $Sql

# shows endpoint url and sync state for ag, and dag
$Sql = @"
SELECT
    ag.name AS group_name,
    ag.is_distributed,
    ar.replica_server_name AS replica_name,
    ar.endpoint_url,
    ar.availability_mode_desc,
    ar.failover_mode_desc,
    ar.primary_role_allow_connections_desc AS allow_connections_primary,
    ar.secondary_role_allow_connections_desc AS allow_connections_secondary,
    ar.seeding_mode_desc AS seeding_mode
FROM 
    sys.availability_replicas AS ar
    JOIN sys.availability_groups AS ag ON ar.group_id = ag.group_id;
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $Sql
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $Sql

$Sql = @"
SELECT ag.name 
       , drs.database_id 
       , db_name(drs.database_id) as database_name 
       , drs.group_id 
       , drs.replica_id 
       , drs.synchronization_state_desc 
       , drs.last_hardened_lsn   
FROM sys.dm_hadr_database_replica_states drs  
INNER JOIN sys.availability_groups ag on drs.group_id = ag.group_id;
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $Sql
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $Sql





# SELECT *
# FROM sys.dm_hadr_availability_group_states

# Seondary primary
# ALTER AVAILABILITY GROUP DISTRIBUTED_AG FORCE_FAILOVER_ALLOW_DATA_LOSS;

