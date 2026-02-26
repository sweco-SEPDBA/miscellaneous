$Database = "Swecoarkiv"
$Path = "\\sweco.se\sw\IT\Backup\SQL\SqlBackup"
$SqlInstance = "SESTODS073.sweco.se\SWSQL06PC"
$ExcelPath = "C:\Temp\Backuplog.xlsx"

$Files = 1,4
$BufferCount = 50,100
$MaxTransferSize = 262144,524288,1048576 #131072 65536

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

$BackupLog = foreach ($RunOption in $BackupSettings) {
    $BufferCount = $RunOption.BufferCount
    $MaxTransferSize = $RunOption.MaxTransferSize
    $NumberOfFiles = $RunOption.FileCount
    $StartTime = Get-Date
    $cmd = @"
    EXECUTE [dbo].[DatabaseBackup] 
        @Databases = '$Database', 
        @Directory = N'$Path', 
        @BackupType = 'FULL', 
        @Verify = 'N', 
        @CleanupTime = 65, 
        @CheckSum = 'Y', 
        @Compress = 'Y', 
        @LogToTable = 'Y', 
        @NumberOfFiles = $NumberOfFiles,
        @BufferCount = $BufferCount, 
        @MaxTransferSize = $MaxTransferSize
"@
    Invoke-DbaQuery -SqlInstance $SqlInstance -Query $cmd -Database maintenance 
    $EndTime = Get-Date
    $BackupTimeInSeconds = ($EndTime - $StartTime).TotalSeconds

    # Define the properties that the object should have in a hashtable
    $BackupProperties = @{
        # Assuming you've assigned something to $Propriedad, $Users and $ErrorState above
        BufferCount     = $BufferCount
        MaxTransferSize = $MaxTransferSize
        FileCount       = $NumberOfFiles
        BackupTime      = $BackupTimeInSeconds
        Caption         = "Buffers:$BufferCount MaxTransfer:$MaxTransferSize Files:$NumberOfFiles"
    }
    New-Object psobject -Property $BackupProperties
}

$BackupLog += foreach ($File in $Files) {
    $StartTime = Get-Date
    $cmd = @"
    EXECUTE [dbo].[DatabaseBackup] 
        @Databases = '$Database', 
        @Directory = N'$Path', 
        @BackupType = 'FULL', 
        @Verify = 'N', 
        @CleanupTime = 65, 
        @CheckSum = 'Y', 
        @Compress = 'Y', 
        @LogToTable = 'Y', 
        @NumberOfFiles = $File
"@
    Invoke-DbaQuery -SqlInstance $SqlInstance -Query $cmd -Database maintenance 
    $EndTime = Get-Date
    $BackupTimeInSeconds = ($EndTime - $StartTime).TotalSeconds

    # Define the properties that the object should have in a hashtable
    $BackupProperties = @{
        # Assuming you've assigned something to $Propriedad, $Users and $ErrorState above
        BufferCount     = 0
        MaxTransferSize = 0
        FileCount       = $File
        BackupTime      = $BackupTimeInSeconds
        Caption         = "Buffers:Default MaxTransfer:Default Files:$File"
    }
    New-Object psobject -Property $BackupProperties
}


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
$ExcelPackage = $BackupLog | Select-Object Caption, FileCount, BufferCount, MaxTransferSize, BackupTime | Export-Excel @params
$WorkSheet = $ExcelPackage.BackupLog

# Apply some basic formatting
Set-ExcelRange -Worksheet $WorkSheet -Range "A1:E1" -BackgroundColor Black -FontColor White


# Create our chart parameters
$chartDefinition = @{
    YRange   = 'BackupTime'
    XRange   = 'Caption'
    Title    = 'BackupTimes'
    Column   = 8
    Row      = 1
    NoLegend = $true
    Height   = 800
}
$Chart = New-ExcelChartDefinition  @chartDefinition 

$params = @{
    ExcelPackage         = $ExcelPackage
    ExcelChartDefinition = $chart
    WorksheetName        = $WorkSheet
    AutoNameRange        = $true
    Show                 = $true 
}
Export-Excel @params


# $names = Get-ExcelSheetInfo C:\Temp\Backuplog.xlsx | Where-Object {$_.Name -ne 'BackupLog'}
# foreach ($name in $names) { Remove-Worksheet -WorksheetName $name.Name -Path C:\Temp\Backuplog.xlsx }

# ForEach-Object { Remove-WorkSheet C:\Temp\testDelete.xlsx $_.Name}

