$Database = "TravelExpense"
$Path = "\\sweco.se\sw\IT\Backup\SQL\SqlBackup"
$SqlInstance = "SESTODS073.sweco.se\SWSQL06PC"
$ExcelPath = "C:\Temp\Backuplog.xlsx"

$Files = 1
$BufferCount = 150,200,250
$MaxTransferSize = 1048576

Remove-Item -Path $Excelpath -ErrorAction SilentlyContinue

$BackupSettings = foreach ($File in $Files) {
    foreach ($Buffer in $BufferCount) {
        foreach ($Transfer in $MaxTransferSize) {
            $BackupSettingsObject = @{
                BufferCount     = $Buffer
                MaxTransferSize = $Transfer
                FileCount       = $File
            }
            New-Object psobject -Property $BackupSettingsObject
        }
    }
}

$Cmd = "DBCC TRACEON (3213, 3604, -1); EXEC sp_cycle_Errorlog;"
Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Cmd;

$BackupLog = foreach ($RunOption in $BackupSettings) {
    $BufferCount = $RunOption.BufferCount
    $MaxTransferSize = $RunOption.MaxTransferSize
    $NumberOfFiles = $RunOption.FileCount
    $cmd = @"
    EXECUTE [dbo].[DatabaseBackup] 
        @Databases = '$Database', 
        @Directory = N'$Path', 
        @BackupType = 'DIFF', 
        @Verify = 'N', 
        @CleanupTime = 65, 
        @CheckSum = 'Y', 
        @Compress = 'Y', 
        @LogToTable = 'Y'
        ,@NumberOfFiles = $NumberOfFiles
        ,@BufferCount = $BufferCount 
        ,@MaxTransferSize = $MaxTransferSize
"@
    $RestoreResult = Invoke-DbaQuery -SqlInstance $SqlInstance -Query $cmd -Database maintenance -MessagesToOutput
    $BackupLogFileData = [string]::Join([Environment]::NewLine,($RestoreResult));
    $BackupLogFileData|
    Select-Object @{Name="BufferCount"; Expression={[int]([regex]::Match($_, "BufferCount:(\s*\d+)").Groups[1].Value)}},
    @{Name="SetsOfBuffers"; Expression={[int]([regex]::Match($_, "Sets Of Buffers:(\s*\d+)").Groups[1].Value)}},
    @{Name="MaxTransferSize"; Expression={[int] ([regex]::Match($_, "MaxTransferSize:(\s*\d+)").Groups[1].Value)}},
    @{Name="BackupTimeInSeconds"; Expression={[double] ([regex]::Match($_, "pages in (\s*\d+.\d+)").Groups[1].Value)}},
    @{Name="BackupSpeedInMBsec"; Expression={[double] ([regex]::Match($_, "pages in (\s*\d+.\d+) seconds \((\d+.\d+) MB/sec").Groups[2].Value)}},
    @{Name="TotalBufferSpace"; Expression={[double] ([regex]::Match($_, "Total buffer space:(\s*\d+) MB").Groups[1].Value)}},
    @{Name="BackupFileCount"; Expression={[int] ([regex]::Match($_, "NumberOfFiles = (\d+)").Groups[1].Value)}}, 
    @{Name="Caption"; Expression={"Buffers:$BufferCount MaxTransfer:$MaxTransferSize Files:$NumberOfFiles"}} 
}

$BackupLog += foreach ($File in $Files) {
    $BufferCount = "Default"
    $MaxTransferSize = "Default"
    $NumberOfFiles = $File
    $cmd = @"
    EXECUTE [dbo].[DatabaseBackup] 
        @Databases = '$Database', 
        @Directory = N'$Path', 
        @BackupType = 'DIFF', 
        @Verify = 'N', 
        @CleanupTime = 65, 
        @CheckSum = 'Y', 
        @Compress = 'Y', 
        @LogToTable = 'Y', 
        @NumberOfFiles = $File
"@
    $RestoreResult = Invoke-DbaQuery -SqlInstance $SqlInstance -Query $cmd -Database maintenance -MessagesToOutput
    $BackupLogFileData = [string]::Join([Environment]::NewLine,($RestoreResult));
    $BackupLogFileData|
    Select-Object @{Name="BufferCount"; Expression={[int]([regex]::Match($_, "BufferCount:(\s*\d+)").Groups[1].Value)}},
    @{Name="SetsOfBuffers"; Expression={[int]([regex]::Match($_, "Sets Of Buffers:(\s*\d+)").Groups[1].Value)}},
    @{Name="MaxTransferSize"; Expression={[int] ([regex]::Match($_, "MaxTransferSize:(\s*\d+)").Groups[1].Value)}},
    @{Name="BackupTimeInSeconds"; Expression={[double] ([regex]::Match($_, "pages in (\s*\d+.\d+)").Groups[1].Value)}},
    @{Name="BackupSpeedInMBsec"; Expression={[double] ([regex]::Match($_, "pages in (\s*\d+.\d+) seconds \((\d+.\d+) MB/sec").Groups[2].Value)}},
    @{Name="TotalBufferSpace"; Expression={[double] ([regex]::Match($_, "Total buffer space:(\s*\d+) MB").Groups[1].Value)}},
    @{Name="BackupFileCount"; Expression={[int] ([regex]::Match($_, "NumberOfFiles = (\d+)").Groups[1].Value)}}, 
    @{Name="Caption"; Expression={"Buffers:$BufferCount MaxTransfer:$MaxTransferSize Files:$NumberOfFiles"}} 
}

Remove-Item -Path $Excelpath -ErrorAction SilentlyContinue

# Create our various Excel parameters
$params = @{
    # Spreadsheet Properties
    Path                 = $ExcelPath
    AutoSize             = $true
    AutoFilter           = $true
    BoldTopRow           = $true
    FreezeTopRow         = $true
    WorksheetName        = 'BackupLog'
    PassThru             = $true

}        

# Create the Excel file
$ExcelPackage = $BackupLog | Select-Object Caption, BackupFileCount, BufferCount, SetsOfBuffers, MaxTransferSize, BackupTimeInSeconds, BackupSpeedInMBsec, TotalBufferSpace | 
sort-object -property BackupTimeInSeconds | Export-Excel @params
$WorkSheet = $ExcelPackage.BackupLog

# Apply some basic formatting
Set-ExcelRange -Worksheet $WorkSheet -Range "A1:H1" -BackgroundColor Black -FontColor White

# Create our chart parameters
$cd1 = @{
    YRange   = 'BackupTimeInSeconds' 
    XRange   = 'Caption'
    ChartType = 'ColumnClustered'
    Title    = 'BackupTimes'
    Column   = 9
    Row      = 1
    NoLegend = $true
    Height   = 300
}
$Chart1 = New-ExcelChartDefinition  @cd1 

$cd2 = @{
    YRange   = 'BackupspeedInMBsec' 
    XRange   = 'Caption'
    ChartType = 'ColumnClustered'
    Title    = 'BackupSpeed'
    Column   = 9
    Row      = 10
    NoLegend = $true
    Height   = 300
}
$Chart2 = New-ExcelChartDefinition  @cd2 

$cd3 = @{
    YRange   = 'TotalBufferSpace' 
    XRange   = 'Caption'
    ChartType = 'ColumnClustered'
    Title    = 'TotalBufferSpace'
    Column   = 9
    Row      = 20
    NoLegend = $true
    Height   = 300
}
$Chart3 = New-ExcelChartDefinition  @cd3 

$params = @{
    ExcelPackage         = $ExcelPackage
    ExcelChartDefinition = $chart1, $Chart2, $Chart3
    WorksheetName        = $WorkSheet
    AutoNameRange        = $true
    Show                 = $true 
}
Export-Excel @params


