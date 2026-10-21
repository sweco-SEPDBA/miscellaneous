
# What's available
Get-DbaInstanceProperty -SqlInstance SESTODS965\SWERP18T | Get-Member
#Example
Get-DbaInstanceProperty -SqlInstance SESTODS965\SWERP18T | select-object * | OUT-GridView

Get-DbaInstanceProperty -SqlInstance SESTODS965\SWERP18T -InstanceProperty VersionMajor, VersionMinor, BuildNumber, VersionString, Edition, Collation, PhysicalMemory, Processors, OSVersion  | Select-Object @{n = 'CmsServerName'; e = { $instance}}, Name, Value

# What's available for sp_configure
get-dbaspconfigure -sqlinstance SESTODS965\SWERP18T | get-member
#Example
get-dbaspconfigure -sqlinstance SESTODS965\SWERP18T | select-object * | out-gridview
Get-DbaService -SqlInstance SESTODS971\SWERP12TC | select-object * | get-member

#Here we go
$SqlInstance = "SESTODS971.sweco.se\SWERP12TC"
get-dbaspconfigure -sqlinstance $Instance -Name MinServerMemory, MaxServerMemory, CostThresholdForParallelism, MaxDegreeOfParallelism | select-object @{n = 'SqlInstance'; e = { $SqlInstance}}, Name, ConfiguredValue
Get-DbaInstanceProperty -SqlInstance $Instance -InstanceProperty VersionMajor, VersionMinor, BuildNumber, VersionString, Edition, Collation, PhysicalMemory, Processors, OSVersion  | Select-Object @{n = 'SqlInstance'; e = { $SqlInstance}}, Name, Value
Get-DbaService -SqlInstance $Instance | select-object @{n = 'SqlInstance'; e = { $SqlInstance}}, @{n = 'ServiceAccount'; e = { $_.StartName }}, @{n = 'ServiceType'; e = { $_.ServiceType }}



######################################################

$SqlInstanceCmdb = "SESTODS039\SWSQL16P"
$Database = "CMDB"



#Region ActiveDbs except DMZ

$Cmd = @"
SELECT
	i.SqlInstance,
	i.CmsServerName
FROM
	[Server] s 
	INNER JOIN Instance i ON s.ServerId = i.ServerId
WHERE
	s.IsServer = 1 
	AND i.IsActive = 1
    AND s.InDmz = 0
    AND i.DontCare = 0
ORDER BY SqlInstance
"@
$instances = Invoke-DbaQuery -SqlInstance $SqlInstanceCmdb -Query $Cmd -Database $Database | select-object -expandproperty CmsServerName

foreach ($instance in $instances) {


}







$b = foreach ($instance in $instances) {
    Write-Host "Collecting data from: $instance" -ForegroundColor Cyan

    $Props = [ordered]@{ SqlInstance = $instance }

    # --- Source 1: sp_configure settings ---
    $spConfig = Get-DbaSpConfigure -SqlInstance $instance -Name MinServerMemory, MaxServerMemory, CostThresholdForParallelism, MaxDegreeOfParallelism

    foreach ($item in $spConfig) {
        $Props[$item.Name] = $item.ConfiguredValue
    }

    # --- Source 2: instance properties ---
    $instanceProps = Get-DbaInstanceProperty -SqlInstance $instance -InstanceProperty VersionMajor, VersionMinor, BuildNumber, VersionString, Edition, Collation, PhysicalMemory, Processors, OSVersion

    foreach ($item in $instanceProps) {
        $Props[$item.Name] = $item.Value
    }

    # --- Source 3: services (only Engine and Agent) ---
    $services = Get-DbaService -SqlInstance $instance -Type Engine, Agent

    $engine = $services.Where({ $_.ServiceType -eq 'Engine' })
    $agent  = $services.Where({ $_.ServiceType -eq 'Agent' })

    $Props['EngineServiceAccount'] = $engine.StartName
    $Props['AgentServiceAccount']  = $agent.StartName

    [PSCustomObject]$Props
}

################################################################################

Get-DbaAvailabilityGroup -SqlInstance sestods971\swerp12tc | select-object $_.Properties
Get-DbaAvailabilityGroup -SqlInstance sestods971\swerp12tc | get-member
$AG | select-object -ExpandProperty AvailabilityReplicas
$AG | select-object -ExpandProperty AvailabilityDatabases
$AG | select-object -ExpandProperty AvailabilityGroupListeners

Get-DbaWsfcCluster -ComputerName SESTODS971

Get-DbaAgReplica -SqlInstance SESTODS971\SWERP12TC | get-member
Get-DbaAgReplica -SqlInstance SESTODS971\SWERP12TC | select-object $_.Properties

GET-dbaaglistener -SqlInstance SESTODS971\SWERP12TC


Get-DbaAgDatabase -SqlInstance SESTODS971\SWERP12TC

Get-DbaAvailabilityGroup -AvailabilityGroup SWERP12TA

Get-DbaAgDatabaseReplicaState -SqlInstance SESTODS971\SWERP12TC

Get-DbaAgBackupHistory -SqlInstance SESTODS971\SWERP12TC -AvailabilityGroup SWERP12TA



$SqlInstanceCmdb = "cmdb_dbw.sql.sweco.net"
$Database = "CMDB"

$Cmd = @"
SELECT
	i.SqlInstance,
	i.CmsServerName
FROM
	[Server] s 
	INNER JOIN Instance i ON s.ServerId = i.ServerId
WHERE
	s.IsServer = 1 
	AND i.IsActive = 1
    AND s.InDmz = 0
ORDER BY SqlInstance
"@
$instances = Invoke-DbaQuery -SqlInstance $SqlInstanceCmdb -Query $Cmd -Database $Database | select-object -expandproperty CmsServerName
 
$AGs = foreach ($instance in $instances) {
    write-host "Collecting data from: $instance" -ForegroundColor Cyan
    #Get-DbaInstanceProperty -SqlInstance $instance -InstanceProperty VersionMajor, VersionMinor, BuildNumber, VersionString, Edition, Collation, PhysicalMemory, Processors, OSVersion  | Select-Object @{n = 'CmsServerName'; e = { $instance}}, Name, Value
    Get-DbaAvailabilityGroup -SqlInstance  $instance
}
$AGs = $AGs | where-object { $_.PrimaryReplica -eq $_.SqlInstance}

$AGs | Write-DbaDataTable -SqlInstance $SqlInstanceCmdb -Database $Database -Table AvailabilityGroup_Stage -Truncate -AutoCreateTable


$Replicas = foreach ($AG in $AGs) {
    write-host "Collecting replicas for AG: $($AG.Name)" -ForegroundColor Cyan
    Get-DbaAgReplica -SqlInstance $AG.PrimaryReplica -AvailabilityGroup $AG.Name | select-object $_.Properties
}
$Replicas | Write-DbaDataTable -SqlInstance $SqlInstanceCmdb -Database $Database -Table AvailabilityGroupReplica_Stage -Truncate -AutoCreateTable

$Listeners = foreach ($AG in $AGs) {
    write-host "Collecting listeners for AG: $($AG.Name)" -ForegroundColor Cyan
    Get-DbaAgListener -SqlInstance $AG.PrimaryReplica -AvailabilityGroup $AG.Name | select-object $_.Properties
}
$Listeners | Write-DbaDataTable -SqlInstance $SqlInstanceCmdb -Database $Database -Table AvailabilityGroupListener_Stage -Truncate -AutoCreateTable

$Databases = foreach ($AG in $AGs) {
    write-host "Collecting databases for AG: $($AG.Name)" -ForegroundColor Cyan
    Get-DbaAgDatabase -SqlInstance $AG.PrimaryReplica -AvailabilityGroup $AG.Name | select-object $_.Properties
}
$Databases | Write-DbaDataTable -SqlInstance $SqlInstanceCmdb -Database $Database -Table AvailabilityGroupDatabase_Stage -Truncate -AutoCreateTable
