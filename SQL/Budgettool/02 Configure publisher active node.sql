

USE master;
GO

EXECUTE sys.sp_adddistributor     @distributor = N'SESTOVH110\SWSQL54P', @password = '0RzmieQoO1E7EBJ5MrlA';

EXECUTE sys.sp_replicationdboption
    @dbname = 'SwecoAccess',
    @optname = 'publish',
    @value = 'true';
    
EXECUTE sys.sp_replicationdboption
    @dbname = 'SwecoCore',
    @optname = 'publish',
    @value = 'true';
