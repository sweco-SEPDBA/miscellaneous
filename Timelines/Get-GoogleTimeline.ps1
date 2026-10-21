  
<# 
 .Synopsis
  Return the script part of a google timelinechart as a dashboard with a time slider.

 .Description
  Use the script part in a html docuemnt to view a timelinechart.

 .Parameter TimeObject
  JobName is the first value in an object, expected as input in the pipeline. The object consists of TimeObject, StartDateTime, EndDateTime.

 .Parameter ChartId
  Id of chart use the same id in html div tag. Defaults to TimeLineChart_Id
  
 .Parameter SliderId
  Id of slider use the same id in html div tag. Defaults to Slider_Id

 .Parameter DashboardId
  Id of Dashboard use the same id in html div tag. Defaults to DashBoard_Id
  
 .Example
  # $queryresult is an object i.e. a result from a tsql query.
  # $script is used in the html <header> tag.

   $script = $queresult | NewGoogleTimeLineChart

 .Example
   
 .Example
   

#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)] [string[]]$TimeObject,
    [Parameter()] [string]$chartId = "TimeLineChart_Id",
    [Parameter()] [string]$DashboardId = "DashBoard_Id",
    [Parameter()] [string]$SliderId = "Slider_Id",
    [Parameter()] [DateTime]$MinDateTime,
    [Parameter()] [DateTime]$MaxDateTime,
    #Output settings
    [string]$chartWidth = "1200",
    [string]$chartHeight = "6000",
    [string]$sliderWidth = "1100",
    [string]$sliderHeight = "40"

)

begin {
    Write-Verbose "$(Get-Date): New-GoogleTimelineChart function started"
    $Script = @"
    
<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript">
google.load('visualization', '1.1',{'packages':['controls']});
google.setOnLoadCallback(drawVisualization);
function drawVisualization() {

    // Create dashboard
    var dashboard = new google.visualization.Dashboard(
        document.getElementById('$DashboardId'));

    
    // Create a date range slider
    var control = new google.visualization.ControlWrapper({
        controlType: 'ChartRangeFilter',
        containerId: '$SliderId',
        options: {
            chartarea: {
                backgroundColor: 'transparent'},
            filterColumnIndex: 1,
            ui: {
                chartType: 'LineChart',
                chartOptions: {
                    backgroundColor: '#263238',
                    hAxis: {
                        format: 'MMM d hh:mm',
                        textStyle: { color: '#b0bec5', fontName: 'Roboto', fontSize: '12', bold: true}
                    }
                },
                chartView: {
                    columns: [1, {
                        type: 'number',
                        calc: function () {return 0;}            
                    }]
                }

            }
        }
    });


    // Time chart visualization
    var chart = new google.visualization.ChartWrapper({
        'chartType': 'Timeline',
        'containerId': '$chartId',
        options: {	
            colors: ["#3f51b5","#2196f3","#03a9f4","#00bcd4","#009688","#4caf50","#8bc34a","#cddc39"],
            fontName: 'Roboto', 
            fontSize: '12',
            backgroundColor: '#637077',
            hAxis: {
                titleTextStyle: {color: '#607d8b'}, 
                gridlines: { count:0}, 
                format: 'HH:mm',
                textStyle: {color: '#b0bec5', fontName: 'Roboto', fontSize: '12', bold: true}
            },
            vAxis: {
                minValue: 0, 
                gridlines: {color:'#434b4e', count:4}, 
                baselineColor: 'transparent'
            },
            chartArea: {
                backgroundColor: "transparent",
                width: '100%',
                height: '80%'
            },
            timeline: 	{
                barLabelStyle: {fontName: 'Roboto', fontSize: '9'},
                rowLabelStyle: {color: '#b0bec5', fontName: 'Roboto', fontSize: '9', bold: true},
                colorByRowLabel: true
            }
        }
    });
    
    
    var data = new google.visualization.DataTable();
    data.addColumn({ type: 'string', id: 'Position' });
    data.addColumn({ type: 'date', id: 'Start' });
    data.addColumn({ type: 'date', id: 'End' });
    data.addRows([

"@


        Write-Verbose "$(Get-Date): Building jscript..."
         $Grid = "`n"
        }


        process {

        [DateTime]$StartTime = $_.StartDateTime
        [DateTime]$EndTime = $_.EndDateTime
        $Job = $_.TimeObject
        

        if($StartTime -lt $MinDateTime) {$MinDateTime = $StartTime}
        if($EndTime -gt $MaxDateTime) {$MaxDateTime = $EndTime}
        
        [String]$StartTimeString = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
        [String]$EndTimeString = $EndTime.ToString("yyyy-MM-dd HH:mm:ss")
        write-Debug $_.StartDateTime
        Write-Debug $_.TimeObject
        Write-Debug "Start: $StartTime, $StartTimeString"

        $Grid += "[ '$Job', new Date('$StartTimeString'), new Date('$EndTimeString') ],`n"
        
    }


end {
[string]$MinDateTimeString = $MinDateTime.ToString("yyyy-MM-dd HH:00:00")
[string]$MaxDateTimeString =  $MaxDateTime.AddHours(1).ToString("yyyy-MM-dd HH:00:00")
        $Script += @"
`n[ 'DateRange', new Date('$MinDateTimeString'), new Date('$MaxDateTimeString') ],
$Grid
        ]);

    dashboard.bind(control, chart);

    dashboard.draw(data);

}
</script>
"@

#Assign javaskript to header
$Header = @"
<title>Sql Server Agent jobs timeline</title>
<link href='http://fonts.googleapis.com/css?family=Roboto:400,100,700,300' rel='stylesheet' type='text/css'>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.4.0/css/font-awesome.min.css">
<style>       
    html {
        background: #263238;
        color: #607d8b;
        font-size: 1.1em;
        line-height: 1.4;
        font-family: "Roboto";
        font-weight: 100;
    }
</style>
"@


#Create the body
$Body = @"
<div class="block">
  <div class="container">
    <div class="span4">
        <div id="$DashboardId">
            <table align="center">
            <tr valign="top">
                <td style="width: 14%;">
                </td>
                <td style="width: 86%;">
                <div id="$SliderId" class="chart" style="align: left; width: $sliderWidth; height: $sliderHeight"></div>
                </td>
            </tr>
            <tr style="height: 40"></tr>
            </tr>
            <tr>
                <td colSpan=2>
                    <div id="$ChartId" class="chart" style="align:left; width: $chartWidth; height: $chartHeight"></div>
                </td>
            </tr>
            </table>
        </div>
        </div>
    </div>
</div>
$script
"@

#Put the parts in html together
$html = @"
<html>
<head>
$Header
</head>
<Body>
$body
</body>
</html>
"@

#Create html file and show the file in browser 
# ConvertTo-Html -Head $header -body $body | Out-File "Test_SQLAGENT_JOBS.html" -Encoding ASCII
# Invoke-Item "Test_SQLAGENT_JOBS.html"

#$html > .\GoogleTimeLineDashboard.html 
$html | Out-File  .\GoogleTimeLineDashboard.html  -Encoding utf8
& .\GoogleTimeLineDashboard.html

}
    