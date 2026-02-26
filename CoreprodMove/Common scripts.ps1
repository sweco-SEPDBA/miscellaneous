
#####################################################################################
# Copy Logins
Get-DbaLogin -SqlInstance coreprod.sql.sweco.se  | Out-GridView -Passthru |
Copy-DbaLogin -Destination SESTODS072.sweco.se\SWSQL06PC 




#####################################################################################
# Copy XE sessions

#View existing XE sessions
Get-DbaXESession -SqlInstance coreprod.sql.sweco.se | Out-GridView 

#Copy XE sessions
Copy-DbaXESession -Source coreprod.sql.sweco.se -Destination SESTODS072.sweco.se\SWSQL06PC -XeSession Object-Changes-BiAnalytics
Copy-DbaXESession -Source SESTODS072.sweco.se\SWSQL06PC -Destination SESTODS073.sweco.se\SWSQL06PC -XeSession Object-Changes-BiAnalytics


#####################################################################################
# Copy Agent Jobs
Get-DbaAgentJob -SqlInstance coreprod.sql.sweco.se | Out-GridView -PassThru |
Copy-DbaAgentJob -Destination SESTODS072.sweco.se\SWSQL06PC

#####################################################################################
# Copy Mail settings
Get-DbaDbMail -SqlInstance coreprod.sql.sweco.se 
Get-DbaDbMailAccount -SqlInstance coreprod.sql.sweco.se 
Get-DbaDbMailProfile -SqlInstance coreprod.sql.sweco.se

Copy-DbaDbMail -Source coreprod.sql.sweco.se -Destination SESTODS072.sweco.se\SWSQL06PC
Copy-DbaDbMail -Source coreprod.sql.sweco.se -Destination SESTODS073.sweco.se\SWSQL06PC

Get-DbaDbMail -SqlInstance sestods072.sweco.se\swsql06pc 
Get-DbaDbMailAccount -SqlInstance sestods072.sweco.se\swsql06pc 
Get-DbaDbMailProfile -SqlInstance sestods072.sweco.se\swsql06pc

Get-DbaDbMail -SqlInstance sestods073.sweco.se\swsql06pc 
Get-DbaDbMailAccount -SqlInstance sestods073.sweco.se\swsql06pc 
Get-DbaDbMailProfile -SqlInstance sestods073.sweco.se\swsql06pc

#####################################################################################
# Deny login for accounts on coreprod

#Deny logins
get-dbalogin -SqlInstance coreprod.sql.sweco.se -ExcludeFilter '##*','NT *', 'SWECO\msvc*' -ExcludeSystemLogin -ExcludeLogin 'SWECO\sepdba_da'  | Out-GridView   -Passthru |
Set-DbaLogin -DenyLogin

#Set back to grant
get-dbalogin -SqlInstance coreprod.sql.sweco.se -ExcludeFilter '##*','NT *', 'SWECO\msvc*' -ExcludeSystemLogin -ExcludeLogin 'SWECO\sepdba_da'  | Out-GridView   -Passthru |
Set-DbaLogin -GrantLogin

#####################################################################################
# Kill active spids coreprod

Get-DbaProcess -SqlInstance coreprod.sql.sweco.se -ExcludeSystemSpids  | Out-GridView -PassThru |
Stop-DbaProcess 

#####################################################################################
# Deny logins on primvary
Get-DbaLogin -SqlInstance SESTODS072.sweco.se\SWSQL06PC -ExcludeLogin SWECO\sepdba_da -ExcludeSystemLogin  | Out-GridView -Passthru |
Set-DbaLogin -DenyLogin

# Grant logins on primary
Get-DbaLogin -SqlInstance SESTODS072.sweco.se\SWSQL06PC -ExcludeLogin SWECO\sepdba_da -ExcludeSystemLogin  | Out-GridView -Passthru |
Set-DbaLogin -GrantLogin

Get-DbaLogin -SqlInstance SESTODS072.sweco.se\SWSQL06PC -ExcludeLogin SWECO\sepdba_da -ExcludeSystemLogin  | get-member
#####################################################################################

Get-DbaDatabase -SqlInstance coreprod.sql.sweco.se | Out-GridView -PassThru | 
Set-DbaDbCompatibility -Compatibility Version160




