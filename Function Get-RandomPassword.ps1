
$SqlInstance = "SESTODS950.sweco.se\SWERP04PC"

##################### 
#Which databases have a lot of VLf files.
Measure-DbaDbVirtualLogFile -SqlInstance $SqlInstance | Where-Object {$psitem.Total -gt 100}


#Make a list of databases with high vlf:s
$Database = "MonitoringDatabase"

##################### 
#Get file sizes and autogrowth settings
Get-DbaDbFile -SqlInstance $SqlInstance -Database $Database | Where-Object {$psitem.TypeDescription -eq 'LOG'} | 
Select-Object SqlInstance, LogicalName, Database, Growth, GrowthType, Size, UsedSpace 


######################
#Shrink the file
#This steps might need to be repeated a number of times

Invoke-DbaDbShrink -SqlInstance $SqlInstance -Database $Database -FileType Log  -ExcludeIndexStats
Measure-DbaDbVirtualLogFile -SqlInstance $SqlInstance -Database $Database

Start-DbaAgentJob -SqlInstance $SqlInstance -Job "DatabaseBackup - USER_DATABASES - LOG"

######################


#####################  Settings
#Set growth settings for log

#Each vlf 2048MB
#Each growth 16 vlfs
First growth Target 16384 

$TargetSize = 98304 #Size in Mb
$TargetSize = 32768 #Size in Mb
$IncrementSize = 32768 

#Set database name again. The databases for which the growth settings above is applicable.
$Database = "MyDatabase1", "MyDatabase2", "MyDatabase3"

######################

#Expand the log in shunks.
Expand-DbaDbLogFile -SqlInstance $SqlInstance -Database $Database -TargetLogSize $TargetSize -IncrementSize $IncrementSize
######################

