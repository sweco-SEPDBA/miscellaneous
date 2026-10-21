USE distribution;
GO

EXECUTE sys.sp_redirect_publisher
    @original_publisher = 'SESTODS072\SWSQL06PC',
    @publisher_db = 'SwecoAccess',
    @redirected_publisher = 'SWSQL06PL.sweco.se';
    
EXECUTE sys.sp_redirect_publisher
    @original_publisher = 'SESTODS072\SWSQL06PC',
    @publisher_db = 'SwecoCore',
    @redirected_publisher = 'SWSQL06PL.sweco.se';

