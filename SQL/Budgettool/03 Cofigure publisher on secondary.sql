USE master
GO

EXECUTE sp_adddistributor  @distributor = 'SESTOVH110\SWSQL54P', @password = '0RzmieQoO1E7EBJ5MrlA';

--EXECUTE sys.sp_addlinkedserver @server = 'SWSQL06PL.sweco.se';
EXECUTE sys.sp_addlinkedserver @server = 'SESTOVH110\SWSQL54P';

