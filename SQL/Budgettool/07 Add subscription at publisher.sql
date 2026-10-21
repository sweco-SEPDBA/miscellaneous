

USE SwecoAccess
go

-- Create a new snapshot job for the publication, using the defaults.
EXEC sp_addpublication_snapshot @publication = 'SwecoAccessPublication'
GO
-- Start the Snapshot Agent job.
EXEC sp_startpublication_snapshot @publication = 'SwecoAccessPublication';
GO

sp_changepublication 'SwecoAccessPublication', 'status','active'
go
sp_addsubscription  @publication = 'SwecoAccessPublication', @subscriber = 'SESTOVH110\SWSQL54P', @destination_db = 'SwecoAccess', @subscription_type = 'pull'
go
sp_addsubscription  @publication = 'SwecoAccessPublication', @subscriber = 'SESTOVH111\SWSQL55P', @destination_db = 'SwecoAccess', @subscription_type = 'pull'
go
sp_addsubscription  @publication = 'SwecoAccessPublication', @subscriber = 'DEFRADS015\DESQL18P', @destination_db = 'SwecoAccess', @subscription_type = 'pull'
go

exec sp_refreshsubscriptions @publication = 'SwecoAccessPublication'

USE SwecoCore
go
EXEC sp_addpublication_snapshot @publication = 'SwecoCorePublication'

-- Start the Snapshot Agent job.
EXEC sp_startpublication_snapshot @publication = 'SwecoCorePublication';
GO

sp_changepublication 'SwecoCorePublication', 'status','active'
go
sp_addsubscription  @publication = 'SwecoCorePublication', @subscriber = 'SESTOVH110\SWSQL54P', @destination_db = 'SwecoCore', @subscription_type = 'pull'
go

sp_addsubscription  @publication = 'SwecoCorePublication', @subscriber = 'SESTOVH111\SWSQL55P', @destination_db = 'SwecoCore', @subscription_type = 'pull'
go

sp_addsubscription  @publication = 'SwecoCorePublication', @subscriber = 'DEFRADS015\DESQL18P', @destination_db = 'SwecoCore', @subscription_type = 'pull'
go

exec sp_refreshsubscriptions @publication = 'SwecoCorePublication'
