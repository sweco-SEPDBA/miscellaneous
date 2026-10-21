<#
    .SYNOPSIS
        This script check sql server agent history and displays the runtimes as a timeline chart on a web page, using google charts.

    .DESCRIPTION

    .PARAMETER StartDateTime

        Lower time range.

    .PARAMETER EndDateTime

        Higer time range.

    .PARAMETER MinRuntime

        The minimum execution time in seconds for Agent job. Defaults to 0.

    .PARAMETER JobDescription

        A LIKE search for jobdescription. Defaults to wildcard %

    .PARAMETER negJobDescription

        A NOT LIKE search for jobdescription. Defaults to empty string.

    .PARAMETER jobName

        A LIKE search for agent job name. Defaults to wildcard %.

    .PARAMETER negJobName

        A NOT LIKE search for job name. Defaults to empty string.

    .PARAMETER jobCategory

        A LIKE search for job category. Defaults to wildcard %.

    .PARAMETER negJobCategory

        A NOT LIKE search for job category. Defaults to empty string.

    .PARAMETER ServerInstances

        Can be a single instance: myserver\myinstance.
        Or it can be a list of instances: @("MyServer1\MyInstance1","MyServer1\MysInstance2","MyServer2\MyInstance").
        Or it can be $null. If it is $null then cms host parameters are used to find instance list: $null.


    .PARAMETER CmsHost

        Instance name of the Cms host. This parameter are not used

    
    .PARAMETER SqlInstance

        This is for search pattern at cms host.

        !!NOT INJECTION SAFE!! this parameter simply gets inserted into a wildcard query on the list of available instances on the CMS. This parameter accepts a pipe delimeted list of patterns, allowing you to match instance names on multiple conditions. If this parameter is a file path, the instance list will be read from the file. 
        Empty returns all instances. That's the default.

    .PARAMETER chartWidth

        Width for chart, defaults to 1200.

    .PARAMETER chartHeight

        Height for chart, defaults to 6000.

    .PARAMETER sliderWidth

        Width of time slider, defaults to 1100

    .PARAMETER sliderHeight

        Height of time slider, defaults to 70

    .EXAMPLE

        .\CreateAgenJobTimeLine.ps1 -StartDateTime "2018-05-20" -EndDateTime "2018-05-28" -ServerInstances "MyServer\MyInstance"
        
    .EXAMPLE

        Write a chart for all instances registered in MyCmsHost and where the instance names starts with MyServer3 or MyServer2. The job description should include hallengren.
        .\CreateAgenJobTimeLine.ps1 -StartDateTime "2018-05-20 07:00:00" -EndDateTime "2018-05-28 03:00:00" -ServerInstances $null -CmsHost "MyCmsHost" -SqlInstance "MyServer3|MyServer2" -jobDescription "%hallengren%"

    .NOTES
    
    This script have as prerequisites that CMSHost module and DBATools powershell scripts must be installed.

    .LINK
#>
[cmdletbinding()]
param(
    #Job settings
    [string]$StartDateTime, 
    [string]$EndDateTime, 
    [int]$MinRuntime = 1,
    [string]$jobDescription = "%",
    [string]$negJobDescription = "",
    [string]$jobName = "%",
    [string]$negJobName = "",
    [string]$jobCategory = "%",
    [string]$negJobCategory = "",
    #Server settings
    [string[]]$ServerInstances, 
    [string]$CmsHost,
    [string]$CmsGroup,
    [string]$SqlInstance = "",
    #Output settings
    [string]$chartWidth = "1200",
    [string]$chartHeight = "6000",
    [string]$sliderWidth = "1100",
    [string]$sliderHeight = "70"
)

###########################################################################################################

IF(!$StartDateTime){
    Write-Verbose "Setting start time to default"
    $StartDateTime = (Get-Date).AddDays(-7)
}

IF(!$EndDateTime){
    Write-Verbose "Setting end time to default"
    $EndDateTime = Get-Date
}

Write-Verbose "StartDate: $StartDateTime"
Write-Verbose "EndDate: $EndDateTime"

#Get server name from direct input or from cms host.
if (!$ServerInstances) {
    $ServerInstances = Get-DbaRegServer -SqlInstance  $CmsHost -Group $CmsGroup | Select-Object -ExpandProperty ServerName
}




#Sql query to collect agent job history
$sql = @"
        declare @StartDT datetime = '$StartDatetime'
        declare @EndDT datetime = '$EndDateTime'
        declare @MinRuntimeInSec int = $MinRuntime

       
        ;WITH JobRunTime AS (
        SELECT  
                j.name as JobName
		        ,CONVERT(DATETIME, CONVERT(CHAR(8), run_date, 112) + ' ' + STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), run_time), 6), 5, 0, ':'), 3, 0, ':'), 120) as SDT
		        ,dateadd(	s,
					        ((run_duration/10000)%100 * 3600) + ((run_duration/100)%100 * 60) + run_duration%100 ,
					        CONVERT(DATETIME, CONVERT(CHAR(8), run_date, 112) + ' ' + STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), run_time), 6), 5, 0, ':'), 3, 0, ':'), 120) 
				        ) as EDT
        FROM 
	        msdb.dbo.sysjobhistory h 
	        INNER JOIN msdb.dbo.sysjobs j ON j.job_id = h.job_id
			INNER JOIN msdb.dbo.syscategories c ON c.category_id = j.category_id 
        where	CONVERT(DATETIME, CONVERT(CHAR(8), run_date, 112) + ' ' + STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(8), run_time), 6), 5, 0, ':'), 3, 0, ':'), 120) between convert(nvarchar(52), @StartDT, 120) and convert(nvarchar(20), @EndDT, 120)
        and		((run_duration/10000)%100 * 3600) + ((run_duration/100)%100 * 60) + run_duration%100 >= cast(@MinRuntimeInSec as nvarchar(50))  -- Ignore trivial runtimes
        and		h.step_id > 0 
        and		j.description LIKE '$jobDescription'
        and     j.description NOT LIKE '$negJobDescription'
        and     j.[name] LIKE '$jobName' 
        and     j.[name] NOT LIKE '$negJobName' 
		and		c.[name] LIKE '$jobCategory'
		and		c.[name] NOT LIKE '$negJobCategory'
        )

        SELECT  
	        @@SERVERNAME + ' - ' + JobName AS TimeObject
	        ,SDT AS StartDateTime
	        ,EDT AS EndDateTime
        from	
            JobRunTime 
        ORDER BY 
            JobName

"@
Write-Verbose $sql

#Get the data to print in chart
    $ChartData = $ServerInstances | ForEach-Object {
            Write-Verbose "Collecting from SqlInstance: $_"
            Invoke-DbaQuery -Query $sql -SqlInstance $_ 
            }

#Creates the javascript for html with the data provided
    $ChartData | .\Get-GoogleTimeline.ps1 -chartId "AgentJobsId" -DashboardId "DashboardId" -SliderId "SliderId" -MinDateTime $StartDateTime -MaxDateTime $EndDateTime
   
