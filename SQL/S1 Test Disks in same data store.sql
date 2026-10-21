--// AG nodes with storage in the same data store.
--// Applies to : VMware
--// ConditionKey column breakdown as follows;
--// Data Store : {Data Store Name} | WSFC : {Windows Cluster Name} | AG : {AG Name} | {Replica:Disk}
select 
	'Device : '+quotename(d.HostName)+ 
	' | Data Store : ' + quotename(ds.name) + N' | WSFC : ' + 
	cr.ClusterName + ' | AG : ' + ag.name + ' | ' +
	stuff((
		select ', ' + ar2.nodename + '('
			+ case [Role] WHEN 1 THEN 'P' ELSE 'S' END 
			+'):{'+ right(vd.[filename],(charindex('/',reverse(vd.[FileName]))-1)) +'}'
		from 
			vm.virtualMachineVirtualDisk as vd
			join vm.datastore as ds2 on replace(replace(left(vd.filename,charindex(']', vd.filename)),'[',''),']','') = ds2.name
			join vm.virtualMachine as vm2 on vd.virtualMachineId = vm2.id
			join AlwaysOn.AvailabilityReplica as ar2 on vm2.name = ar2.NodeName
		where 
			ar2.GroupId = ag.GroupId
			and ds2.name = ds.name
		order by vm2.name
		for xml path(''), type).value(N'.[1]',N'nvarchar(max)'),1,2,N'') as conditionKey,
	count(vmdk.[filename]) as DiskOverlapCount
from 
	vm.datastore as ds
	join vm.virtualMachineVirtualDisk as vmdk on replace(replace(left(vmdk.[filename],charindex(']', vmdk.[filename])),'[',''),']','') = ds.name
	join vm.virtualmachine as vm on vmdk.virtualMachineId = vm.id
	join AlwaysOn.AvailabilityReplica as ar on ar.nodename = vm.name
	join AlwaysOn.AvailabilityGroup as ag on ar.GroupId = ag.GroupId
	join AlwaysOn.ClusterReference as cr on ar.EventSourceConnectionID = cr.EventSourceConnectionID
	join dbo.Device d ON vm.DeviceID = d.ID
--where 	d.HostName NOT IN ('SESTODS904', 'SESTODS907', 'SESTODS952','SESTODS970','SESTODS971')
group by d.HostName,cr.ClusterName, ag.Name, ds.Name, ag.GroupId
order by d.HostName,cr.ClusterName, ag.Name, ds.Name;


SELECT ag.[Name], ds.[Name], d.HostName--, vmdk.[FileName]
FROM 
	vm.datastore as ds
	join vm.virtualMachineVirtualDisk as vmdk on replace(replace(left(vmdk.[filename],charindex(']', vmdk.[filename])),'[',''),']','') = ds.name
	join vm.virtualmachine as vm on vmdk.virtualMachineId = vm.id
	join AlwaysOn.AvailabilityReplica as ar on ar.nodename = vm.name
	join AlwaysOn.AvailabilityGroup as ag on ar.GroupId = ag.GroupId
	--join AlwaysOn.ClusterReference as cr on ar.EventSourceConnectionID = cr.EventSourceConnectionID
	join dbo.Device d ON vm.DeviceID = d.ID







--// AG nodes with storage in the same data store.
--// Applies to : VMware
--// ConditionKey column breakdown as follows;
--// Data Store : {Data Store Name} | WSFC : {Windows Cluster Name} | AG : {AG Name} | {Replica:Disk}
select 'Data Store : ' + quotename(ds.name) + N' | WSFC : ' + cr.ClusterName 
		+ ' | AG : ' + ag.name + ' | ' +
	stuff((select ', ' + ar2.nodename + '('
					+ case [Role] WHEN 1 THEN 'P' ELSE 'S' END 
					+'):{'+ right(vd.[filename],(charindex('/',reverse(vd.[FileName]))-1)) +'}'
			from vm.virtualMachineVirtualDisk as vd
			join vm.datastore as ds2 
				on replace(replace(left(vd.filename,charindex(']', vd.filename)),'[',''),']','') = ds2.name
			join vm.virtualMachine as vm2 on vd.virtualMachineId = vm2.id
			join AlwaysOn.AvailabilityReplica as ar2 on vm2.name = ar2.NodeName
			where ar2.GroupId = ag.GroupId
				and ds2.name = ds.name
			order by vm2.name
			for xml path(''), type).value(N'.[1]',N'nvarchar(max)'),1,2,N'') as conditionKey,
			count(vmdk.[filename]) as DiskOverlapCount
from vm.datastore as ds
join vm.virtualMachineVirtualDisk as vmdk
	on replace(replace(left(vmdk.[filename],charindex(']', vmdk.[filename])),'[',''),']','') = ds.name
join vm.virtualmachine as vm on vmdk.virtualMachineId = vm.id
join AlwaysOn.AvailabilityReplica as ar on ar.nodename = vm.name
join AlwaysOn.AvailabilityGroup as ag on ar.GroupId = ag.GroupId
join AlwaysOn.ClusterReference as cr on ar.EventSourceConnectionID = cr.EventSourceConnectionID
group by cr.ClusterName, ag.Name, ds.Name, ag.GroupId
order by cr.ClusterName, ag.Name, ds.Name
;

select * from vm.VirtualMachineVirtualDisk

select ds.[Name], VmPath
from 
	vm.datastore as ds
	join vm.virtualmachine as vm on replace(replace(left(vm.VmPath,charindex(']', vm.VmPath)),'[',''),']','') = ds.name


SELECT 
	'Data Store : ' + quotename(ds.name) + N' | WSFC : ' + cr.ClusterName 
		+ ' | AG : ' + ag.name + ' | ' +
	stuff((
		select 
			', ' + ar2.nodename + '('
			+ case [Role] WHEN 1 THEN 'P' ELSE 'S' END  
					+')'
		from 
			vm.virtualMachine as vm2 
			join vm.datastore as ds2 on replace(replace(left(vm2.VmPath,charindex(']', vm2.VmPath)),'[',''),']','') = ds2.name
			join AlwaysOn.AvailabilityReplica as ar2 on vm2.name = ar2.NodeName
		where 
			ar2.GroupId = ag.GroupId
			and ds2.name = ds.name
		order by vm2.name
		for xml path(''), type).value(N'.[1]',N'nvarchar(max)'),1,2,N'') as conditionKey,
	count(ar.[NodeName]) as NodeOverlapCount
FROM
	vm.datastore as ds
	join vm.virtualmachine as vm on replace(replace(left(vm.VmPath,charindex(']', vm.VmPath)),'[',''),']','') = ds.name
	join AlwaysOn.AvailabilityReplica as ar on ar.nodename = vm.name
	join AlwaysOn.AvailabilityGroup as ag on ar.GroupId = ag.GroupId
	join AlwaysOn.ClusterReference as cr on ar.EventSourceConnectionID = cr.EventSourceConnectionID
GROUP BY ds.[Name], cr.ClusterName, ag.[Name], ag.GroupID
ORDER BY ds.[Name], cr.ClusterName, ag.[Name]
