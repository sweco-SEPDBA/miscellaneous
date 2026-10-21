USE master;
GO
EXEC sp_adddistributor @distributor = N'SESTOVH110\SWSQL54P', @password = '0RzmieQoO1E7EBJ5MrlA';
GO

EXEC sp_adddistributiondb @database = N'distribution';
GO

EXEC sp_adddistpublisher @publisher = N'SESTODS072\SWSQL06PC', @distribution_db = N'distribution', @working_directory = N'\\sweco.se\sw\IT\Backup\SQL\ReplicationShare\Budgettool', @trusted = N'false'
GO
--EXEC sp_adddistpublisher @publisher = N'SESTODS073\SWSQL06PC', @distribution_db = N'distribution', @working_directory = N'\\sweco.se\sw\IT\Backup\SQL\ReplicationShare\Budgettool', @trusted = N'false'
