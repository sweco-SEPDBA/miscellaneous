###########################################################################
#Test
###########################################################################
#Create roles
$Params = @{
    "SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
    "Database" = "BudgetTool" 
    "Role" = "db_datareader_general", "db_datareader_finance", "db_datareader_HR", "db_datawriter_general", "db_datawriter_finance", "db_datawriter_HR"
}
New-DbaDbRole  @Params

###########################################################################
#Create logins Test
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"Login" = "SWECO\SW-RoleAnalytics-TEST-SQL-Read", "SWECO\SW-Role-Analytics-TEST-SQL-Read-Finance", "SWECO\SW-Role-Analytics-TEST-SQL-Read-HR", "SWECO\SW-Role-Analytics-TEST-SQL-Write", "SWECO\SW-Role-Analytics-TEST-SQL-Write-Finance", "SWECO\SW-Role-Analytics-TEST-SQL-Write-HR", "SWECO\SW-Role-Analytics-TEST-SQL-Dev"
}
New-DbaLogin @Params

###########################################################################
#Create Users in DB Test
#Sql-Read
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-TEST-SQL-Read"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Read-Finance
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-TEST-SQL-Read-Finance"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-ReadHR
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-TEST-SQL-Read-HR"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Write
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"Login" = "SWECO\SWECO\SW-Role-Analytics-TEST-SQL-Write"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Write-Finance
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-TEST-SQL-Write-Finance"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Write-HR
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-TEST-SQL-Write-HR"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Dev
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-TEST-SQL-Dev"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

###########################################################################
#Add Role members Test

#Sql-Read
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-TEST-SQL-Read"
"Database" = "BudgetTool"
"Role" = "db_datareader_general"
}
Add-DbaDbRoleMember @Params

#Sql-Read-Finance
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-TEST-SQL-Read-Finance"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datareader_finance"
}
Add-DbaDbRoleMember @Params

#Sql-Read-HR
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-TEST-SQL-Read-HR"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datareader_HR"
}
Add-DbaDbRoleMember @Params

#Sql-Write
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-TEST-SQL-Write"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datawriter_general"
}
Add-DbaDbRoleMember @Params

#Sql-Write-Finance
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-TEST-SQL-Write-Finance"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datareader_finance", "db_datawriter_general", "db_datawriter_finance"
}
Add-DbaDbRoleMember @Params

#Sql-Write-HR
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-TEST-SQL-Write-HR"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datareader_HR", "db_datawriter_general", "db_datawriter_HR"
}
Add-DbaDbRoleMember @Params

#Sql-Dev
$Params = @{
"SqlInstance" = "coretest1.sql.sweco.se", "coredev.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-TEST-SQL-Dev"
"Database" = "BudgetTool"
"Role" = "db_owner"
}
Add-DbaDbRoleMember @Params

###########################################################################
#Prod
###########################################################################

#Create roles
$Params = @{
    "SqlInstance" = "coreprod.sql.sweco.se"
    "Database" = "BudgetTool" 
    "Role" = "db_datareader_general", "db_datareader_finance", "db_datareader_HR", "db_datawriter_general", "db_datawriter_finance", "db_datawriter_HR"
}
New-DbaDbRole  @Params

###########################################################################
#Create logins PROD
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-PROD-SQL-Read", "SWECO\SW-Role-Analytics-PROD-SQL-Read-Finance", "SWECO\SW-Role-Analytics-PROD-SQL-Read-HR", "SWECO\SW-Role-Analytics-PROD-SQL-Write", "SWECO\SW-Role-Analytics-PROD-SQL-Write-Finance", "SWECO\SW-Role-Analytics-PROD-SQL-Write-HR", "SWECO\SW-Role-Analytics-PROD-SQL-Dev"
}
New-DbaLogin @Params

###########################################################################
#Create Users in DB PROD
#Sql-Read
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-PROD-SQL-Read"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Read-Finance
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-PROD-SQL-Read-Finance"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-ReadHR
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-PROD-SQL-Read-HR"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Write
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"Login" = "SWECO\SWECO\SW-Role-Analytics-PROD-SQL-Write"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Write-Finance
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-PROD-SQL-Write-Finance"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Write-HR
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-PROD-SQL-Write-HR"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

#Sql-Dev
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"Login" = "SWECO\SW-Role-Analytics-PROD-SQL-Dev"
"Database" = "BudgetTool"
}
New-DbaDbUser @Params

###########################################################################
#Add Role members PROD

#Sql-Read
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-PROD-SQL-Read"
"Database" = "BudgetTool"
"Role" = "db_datareader_general"
}
Add-DbaDbRoleMember @Params

#Sql-Read-Finance
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-PROD-SQL-Read-Finance"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datareader_finance"
}
Add-DbaDbRoleMember @Params

#Sql-Read-HR
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-PROD-SQL-Read-HR"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datareader_HR"
}
Add-DbaDbRoleMember @Params

#Sql-Write
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-PROD-SQL-Write"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datawriter_general"
}
Add-DbaDbRoleMember @Params

#Sql-Write-Finance
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-PROD-SQL-Write-Finance"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datareader_finance", "db_datawriter_general", "db_datawriter_finance"
}
Add-DbaDbRoleMember @Params

#Sql-Write-HR
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-PROD-SQL-Write-HR"
"Database" = "BudgetTool"
"Role" = "db_datareader_general", "db_datareader_HR", "db_datawriter_general", "db_datawriter_HR"
}
Add-DbaDbRoleMember @Params

#Sql-Dev
$Params = @{
"SqlInstance" = "coreprod.sql.sweco.se"
"User" = "SWECO\SW-Role-Analytics-PROD-SQL-Dev"
"Database" = "BudgetTool"
"Role" = "db_owner"
}
Add-DbaDbRoleMember @Params






