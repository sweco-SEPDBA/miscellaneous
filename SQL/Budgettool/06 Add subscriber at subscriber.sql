USE SwecoAccess
go
exec sp_addpullsubscription @publisher = 'SESTODS072\SWSQL06PC', @publication = 'SwecoAccessPublication', @publisher_db = 'SwecoAccess', @subscription_type = 'pull';
--exec sp_addpullsubscription @publisher = 'SESTODS073\SWSQL06PC', @publication = 'SwecoAccessPublication', @publisher_db = 'SwecoAccess', @subscription_type = 'pull';
--exec sp_addpullsubscription @publisher = 'SWSQL06PL.sweco.se', @publication = 'SwecoAccessPublication', @publisher_db = 'SwecoAccess', @subscription_type = 'pull';
go
exec sp_addpullsubscription_agent @publisher = 'SESTODS072\SWSQL06PC', @publisher_db = 'SwecoAccess', @publication = 'SwecoAccessPublication', @distributor = N'SESTOVH110\SWSQL54P', @distribution_db = N'distribution', @frequency_type = 64
--exec sp_addpullsubscription_agent @publisher = 'SESTODS073\SWSQL06PC', @publisher_db = 'SwecoAccess', @publication = 'SwecoAccessPublication', @distributor = N'SESTOVH110\SWSQL54P', @distribution_db = N'distribution'
--exec sp_addpullsubscription_agent @publisher = 'SWSQL06PL.sweco.se', @publisher_db = 'SwecoAccess', @publication = 'SwecoAccessPublication', @distributor = N'SESTOVH110\SWSQL54P', @distribution_db = N'distribution'
go

USE SwecoCore
go
--exec sp_addpullsubscription @publisher = 'SWSQL06PL.sweco.se', @publication = 'SwecoCorePublication', @publisher_db = 'SwecoCore', @subscription_type = 'pull';
--exec sp_addpullsubscription @publisher = 'SESTODS073\SWSQL06PC', @publication = 'SwecoCorePublication', @publisher_db = 'SwecoCore', @subscription_type = 'pull';
exec sp_addpullsubscription @publisher = 'SESTODS072\SWSQL06PC', @publication = 'SwecoCorePublication', @publisher_db = 'SwecoCore', @subscription_type = 'pull';
go
--exec sp_addpullsubscription_agent @publisher = 'SWSQL06PL.sweco.se', @publisher_db = 'SwecoCore', @publication = 'SwecoCorePublication', @distributor = N'SESTOVH110\SWSQL54P', @distribution_db = N'distribution'
--exec sp_addpullsubscription_agent @publisher = 'SESTODS073\SWSQL06PC', @publisher_db = 'SwecoCore', @publication = 'SwecoCorePublication', @distributor = N'SESTOVH110\SWSQL54P', @distribution_db = N'distribution'
exec sp_addpullsubscription_agent @publisher = 'SESTODS072\SWSQL06PC', @publisher_db = 'SwecoCore', @publication = 'SwecoCorePublication', @distributor = N'SESTOVH110\SWSQL54P', @distribution_db = N'distribution', @frequency_type = 64
go

