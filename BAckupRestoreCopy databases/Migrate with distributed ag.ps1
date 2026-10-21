
######################################################################
# Migrate with distributed ag
#Basic settings (parameter setup) (Do your changes here)
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
$Databases = "AdventureWorks2017", "SwecoLog", "Ag_Dummy"
$BackupPath = '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL024$SWSQL02TA' # Path to backup folder on primary primary
$ServiceAccountPrimaryAG = "SWECO\msvc_SESTOCL023$"
$ServiceAccountSecondsaryAG = "SWECO\svc_sql_SESTODS061"

# Parameter assignement, (do not change)
$primaryPrimaryShort = $primaryPrimary.Replace(".sweco.se", "")
$primarySecondaryShort = $primarySecondary.Replace(".sweco.se", "")
$SecondaryPrimaryShort = $SecondaryPrimary.Replace(".sweco.se", "")
$SecondarySecondaryShort = $SecondarySecondary.Replace(".sweco.se", "")
$PrimaryPrimaryServer = $primaryPrimary.Split("\")[0]
$primarySecondaryServer = $primarySecondary.Split("\")[0]
$SecondaryPrimaryServer = $SecondaryPrimary.Split("\")[0]
$SecondarySecondaryServer = $SecondarySecondary.Split("\")[0]

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
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$ServiceAccountPrimaryAG]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$ServiceAccountSecondsaryAG]
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
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$ServiceAccountPrimaryAG]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$ServiceAccountSecondsaryAG]
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
REPLICA ON N'$SecondaryPrimaryShort' WITH (ENDPOINT_URL = N'TCP://$SecondaryPrimaryServer:5022',  
    FAILOVER_MODE = MANUAL,  
    AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,  
    BACKUP_PRIORITY = 50,  
    SECONDARY_ROLE(ALLOW_CONNECTIONS = NO),  
    SEEDING_MODE = AUTOMATIC),  
N'$SecondarySecondaryShort' WITH (ENDPOINT_URL = N'TCP://$SecondarySecondaryServer:5022',  
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
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$ServiceAccountPrimaryAG]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$ServiceAccountSecondsaryAG]
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
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$ServiceAccountPrimaryAG]
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$ServiceAccountSecondsaryAG]
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
        SEEDING_MODE = MANUAL  
    ),  
    '$SecondaryAGName' WITH    
    (  
        LISTENER_URL = 'tcp://$SecondaryListenerName.sweco.se:5022',  
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
        FAILOVER_MODE = MANUAL,  
        SEEDING_MODE = MANUAL  
    );    
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql


$sql = @"
ALTER AVAILABILITY GROUP [$DistributedAGName] 
    MODIFY 
    AVAILABILITY GROUP ON 
    '$SecondaryAGName' WITH 
    (SEEDING_MODE = MANUAL);
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
        SEEDING_MODE = MANUAL  
    ),  
        '$SecondaryAGName' WITH
    (  
        LISTENER_URL = 'tcp://$SecondaryListenerName.sweco.se:5022',  
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
        FAILOVER_MODE = MANUAL,  
        SEEDING_MODE = MANUAL  
    );    
"@
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql

######################################################################
# Copy the databases to the secondary ag

Copy-DbaDatabase -Source $primaryPrimary -Destination $SecondaryPrimary -Database $Databases -BackupRestore -UseLastBackup -NoRecovery
Copy-DbaDatabase -Source $primaryPrimary -Destination $SecondarySecondary -Database $Databases -BackupRestore -UseLastBackup -NoRecovery

set-DbaAgentJob -SqlInstance $primaryPrimary -Job "DatabaseBackup - USER_DATABASES - LOG" -Disabled

foreach ($Database in $Databases) {
    Restore-DbaDatabase -SqlInstance $SecondaryPrimary -Path "$BackupPath\$Database" -Continue -NoRecovery
    Restore-DbaDatabase -SqlInstance $SecondarySecondary -Path "$BackupPath\$Database" -Continue -NoRecovery
}

# Add to dist ag
foreach ($Database in $Databases) {
    $sql = "ALTER DATABASE [$Database] SET HADR AVAILABILITY GROUP = [$DistributedAGName]"
    invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql
}

foreach ($Database in $Databases) {
    $sql = "ALTER DATABASE [$Database] SET HADR AVAILABILITY GROUP = [$SecondaryAGName];"
    invoke-DbaQuery -SqlInstance $SecondarySecondary -Query $sql
}

# Start log backups


set-DbaAgentJob -SqlInstance $primaryPrimary -Job "DatabaseBackup - USER_DATABASES - LOG" -Enabled



###########################################################################################
# Failover the distributed ag

# Note that the load must be turned off before doing the failover

# Set ag to synchronous commit
# Run on global primary and forwarder
$sql = @"
-- sets the distributed availability group to synchronous commit 
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
    
-- verifies the commit state of the distributed availability group
select 
    ag.name, 
    ag.is_distributed, 
    ar.replica_server_name, 
    ar.availability_mode_desc, 
    ars.connected_state_desc, 
    ars.role_desc, 
    ars.operational_state_desc, 
    ars.synchronization_health_desc 
from 
    sys.availability_groups ag  
    join sys.availability_replicas ar on ag.group_id=ar.group_id
    left join sys.dm_hadr_availability_replica_states ars on ars.replica_id=ar.replica_id
where 
    ag.is_distributed=1;
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql

# Verify the last log sequence number (LSN) is the same on the global primary and the forwarder

$sql = @"
-- Run this query on the Global Primary and the forwarder
-- Check the results to see if synchronization_state_desc is SYNCHRONIZED, and the last_hardened_lsn is the same per database on both the global primary and       forwarder 
-- If not rerun the query on both side every 5 seconds until it is the case
--
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
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql | Format-Table
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql | Format-Table

# When the last_hardened_lsn is the same for both availability groups per database, the availability group is ready to fail over

$sql = @"
ALTER AVAILABILITY GROUP $DistributedAGName SET (ROLE = SECONDARY);
"@
Invoke-DbaQuery -SqlInstance $primaryPrimary -Query $sql

$sql = @"
-- Once the last_hardened_lsn is the same per database on both sides
-- We can Fail over from the primary availability group to the secondary availability group. 
-- Run the following command on the forwarder, the SQL Server instance that hosts the primary replica of the secondary availability group.

ALTER AVAILABILITY GROUP $DistributedAGName FORCE_FAILOVER_ALLOW_DATA_LOSS;
"@
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql

# When everything is done you can remove the distributed ag

$sql = @"
DROP AVAILABILITY GROUP [$DistributedAGName]
"@
Invoke-DbaQuery -SqlInstance $PrimaryPrimary -Query $sql
Invoke-DbaQuery -SqlInstance $SecondaryPrimary -Query $sql