###########################################################################
#---------------------------------------------------------------------------
# SQL Server 2012 and earlier versions uses this Algorithm:
#---------------------------------------------------------------------------
#
# Log growth <= 64 MB, then 4 VLFs are created
# Log growth between 64 MB and <= 1 GB, 8 VLFs
# 1 GB & above = 16 VLFs
#
#---------------------------------------------------------------------------
# SQL Server 2014 and above uses this Algorithm:
#---------------------------------------------------------------------------
#
# If the growth size is less than 1/8 the size of the current log size?
# Yes: create 1 new VLF equal to the growth size
# No: use the above algorithm
#
###########################################################################

$SqlInstance = "SEDCXDS010.sweco.se\SWSCOM03P"

#Which databases have a lot of VLf files.
Measure-DbaDbVirtualLogFile -SqlInstance $SqlInstance | Where-Object {$psitem.Total -gt 100}
##################### 

Measure-DbaDbVirtualLogFile -SqlInstance $SqlInstance -Database $Database
#Make a list of databases with high vlf:s
$Database = "OperationsManager"#, "projectmember", "swecoaccess", "SwecoApi", "tre", "webbeko"

##################### 
#Get file sizes and autogrowth settings
Get-DbaDbFile -SqlInstance $SqlInstance -Database $Database | Where-Object {$psitem.TypeDescription -eq 'LOG'} | 
Select-Object SqlInstance, LogicalName, Database, Growth, GrowthType, Size, UsedSpace 

######################
#Shrink the file
#This steps might need to be repeated a number of times

Invoke-DbaDbShrink -SqlInstance $SqlInstance -Database $Database -FileType Log -ExcludeIndexStats
Measure-DbaDbVirtualLogFile -SqlInstance $SqlInstance -Database $Database

Start-DbaAgentJob -SqlInstance $SqlInstance -Job "DatabaseBackup - USER_DATABASES - LOG"

######################

#####################  Settings
#Set growth settings for log

#Example for growth rate 512MB
#First growth
$TargetSize = 16514 #Size in Mb
$IncrementSize = 16384 
#Continous growth
$TargetSize = 32768 #Size in Mb
$IncrementSize = 1024 

#Example for growth rate 1024MB
#First growth
$TargetSize = 16384 #Size in Mb
$IncrementSize = 131072
 
#Continous growth
$TargetSize = 16384 #Size in Mb
$IncrementSize = 1024 

$TargetSize = 49152 #Size in Mb
$IncrementSize = 1024 

#Set database name again. The databases for which the growth settings above is applicable.
#$Database = "MyDatabase1", "MyDatabase2", "MyDatabase3"

#Expand the log in shunks.
Expand-DbaDbLogFile -SqlInstance $SqlInstance -Database $Database -TargetLogSize $TargetSize -IncrementSize $IncrementSize
######################


Database    : ProjectMember
Growth      : 65536

Database    : swecocoreexpo
Growth      : 65536

Database    : SwecoApi
Growth      : 131072

Database    : SwecoIntranetStaging_Copy
Growth      : 131072

Database    : BudgetTool
Growth      : 524288

Database    : tre
Growth      : 524288

Database    : tre_sandbox
Growth      : 524288

Database    : webbeko
Growth      : 524288

Database    : swecocore
Growth      : 1048576

Database    : TravelExpense
Growth      : 1048576

Database    : travelexpense_prodtest
Growth      : 1048576

Database    : Staging
Growth      : 1048576
