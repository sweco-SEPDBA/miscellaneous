$FQDN = 'SESTODS068.sweco.se' 
$SqlInstance = 'SESTODS068\SESQL28T'
$FQDN = 'SESTODS065.sweco.se' 
$SqlInstance = 'SESTODS065\SESQL20T'
$FQDN = 'SESTODS059.sweco.se' 
$SqlInstance = 'SESTODS059\SWSQL14T'
$SqlInstance = 'SESTODS059\SWSQL34P'
$FQDN = 'IPSQ.mlmips.com' 
$SqlInstance = 'IPSQ.mlmips.com\mssql02'
$FQDN = 'NLAMSDS029.sweco.se' 
$SqlInstance = 'NLAMSDS029.sweco.se\SWSQL32T'
$FQDN = 'NLAMSDS001.sweco.se' 
$SqlInstance = 'NLAMSDS001.sweco.se\SWECO01'
$FQDN = 'NLAMSAS086.sweco.se' 
$SqlInstance = 'NLAMSAS086\SQLEXPRESS'
$FQDN = 'NLAMSPS014.sweco.se' 
$SqlInstance = 'NLAMSPS014\SAFECOMEXPRESS'
$FQDN = 'NLAMSDS010.sweco.se' 
$SqlInstance = 'NLAMSDS010\SWECO01'
$FQDN = 'NLAMSAS001.sweco.se' 
$SqlInstance = 'NLAMSAS001\NLSQL34P'

Set-SwRedgateUserRights -FQDN $FQDN -SqlInstance $SqlInstance -MonitoringAccount 'SWECO\svc_SqlMonitor' -RestartWinRM
Add-SwMonitorInstance -FQDN $FQDN 

MTp6clhudDdZV3hVYlZMNmVSTTRuZUxxSlkvZmhodU9JcXg0dVZIci9WQ1JjPQ==
Set-DbatoolsInsecureConnection -SessionOnly

NLAMSAS001.sweco.se\NLSQL34P