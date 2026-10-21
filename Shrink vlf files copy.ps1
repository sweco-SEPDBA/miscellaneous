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

$SqlInstance = "SESTODS960\SWERP24T"

#Which databases have a lot of VLf files.
Measure-DbaDbVirtualLogFile -SqlInstance $SqlInstance  | Where-Object {$psitem.Total -gt 300}
##################### 

#Make a list of databases with high vlf:s
$Database =   "MyDatabase1", "MyDatabase2", "MyDatabase3"
Measure-DbaDbVirtualLogFile -SqlInstance $SqlInstance -Database $Database

##################### 
#Get file sizes and autogrowth settings
#Check for a relevant target size.
#Make sure the growth is at size you want the VLF:s to be. If you want 512 MB VLF:s, set the growth to 512 MB.
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

# Example sizes
# $TargetSize = 512 #Size in Mb
# $TargetSize = 1024 #Size in Mb
# $TargetSize = 2048 #Size in Mb
# $TargetSize = 8192 #Size in Mb
# $TargetSize = 16384 #Size in Mb
# $TargetSize = 32768 #Size in Mb
# $TargetSize = 65536 #Size in Mb
# $TargetSize = 131072 #Size in Mb
# $TargetSize = 262144 #Size in Mb
# $TargetSize = 524288 #Size in Mb

#List the vlf:s and their sizes
Get-DbaDbVirtualLogFile -SqlInstance $SqlInstance -Database $database | Select-Object SqlInstance, Database, FileId, FileSize, StartOffset | Format-Table -AutoSize

######################
# Do the actual growth of the log file to the target size. This will create new VLF:s with the correct size.
foreach ($db in $Database) {
    Write-Host "Processing database: $db" -ForegroundColor Cyan
    . .\Expand-LogFile.ps1 -SqlInstance $SqlInstance -Database $db -TargetSizeMB $TargetSize #-WhatIf
    Get-DbaDbVirtualLogFile -SqlInstance $SqlInstance -Database $db | Select-Object SqlInstance, Database, FileId, FileSize, StartOffset | Format-Table -AutoSize
}
