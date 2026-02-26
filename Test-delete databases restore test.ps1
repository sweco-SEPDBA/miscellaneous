

# [string]$CMDBInstance,
# [string]$CMDBDatabase,
[string]$DestInstance = "SESTODS076.sweco.se\SESQL37T"
[string]$LogDir = "C:\Temp"
[int]$MaxAgeInDays = 3
[string]$MinLogLevel = "INFO"
[string]$LogName = "Remove-swFailrestoretest"

function Remove-LeftoverDatabases {
    param (
        [Parameter(Mandatory)] [string]$DestInstance,
        [Parameter()] [int]$MaxAgeInDays
        )


    Write-Host "Checking for old test databases to remove on $DestInstance"
    
    $Prefix = "dbatools"
    # Calculate threshold date for filtering old databases
$ThresholdDate = (Get-Date).AddDays(-1 * $MaxAgeInDays)  # 

    
    # Fetch databases matching test prefix and older than threshold
$DatabasesToRemove = Get-DbaDatabase -SqlInstance $DestInstance | Where-Object { 
        $_.Name -like "$Prefix*" -and $_.CreateDate -lt $ThresholdDate 
    }
    # Proceed if there are old databases to remove
if ($DatabasesToRemove.Count -gt 0) {
        Write-Host "Found $($DatabasesToRemove.Count) databases older than 3 days to remove on $DestInstance."

        # Iterate through each outdated test database
foreach ($Database in $DatabasesToRemove) {
            # try {
            #     Remove-DbaDatabase -SqlInstance $DestInstance -Database $Database.Name -Confirm:$false -ErrorAction Stop
            #     Write-SwLog -Message "Successfully removed database: $($Database.Name) (Created: $($Database.CreateDate))" -LogDir $LogDir -LogName $LogName -LogLevel "INFO" -MinLogLevel $MinLogLevel
            # }
            # catch {
            #     Write-SwLog -Message "ERROR: Failed to remove database $($Database.Name) on $DestInstance. Error: $($_.Exception.Message)" -LogDir $LogDir -LogName $LogName -LogLevel "ERROR" -MinLogLevel $MinLogLevel
            # }
        }
    } else {
        Write-Host "No databases found matching criteria for removal on $DestInstance."
    }
}

# Example usage
Remove-LeftoverDatabases -DestInstance $DestInstance -MaxAgeInDays $MaxAgeInDays

Get-DbaDatabase -SqlInstance $DestInstance | Where-Object { $_.Name -like "dbatools*" } | Select-Object Name, CreateDate, LastBackupDate, LastLogBackupDate, RecoveryModel, SizeMB | Out-GridView -PassThru




        # Get next db in list
        $sql = @"
        ;WITH LastRestoreTest AS (
        SELECT 
            SourceServer,
            [Database],
            MAX(RestoreEnd) LastRestore
        FROM
            RestoreLogs 
        GROUP BY
            SourceServer, [Database]),

        OldestRestoreTest AS (
        SELECT TOP (1) 
            i.SqlInstance,
            d.[Name],
            d.SizeMb,
            COALESCE(lrt.LastREstore,'2000-01-01 00:00:00') [Last-Restore] 
        FROM 
            [Server] s
            INNER JOIN Instance i ON s.ServerId = i.ServerId
            INNER JOIN [Database] d ON i.InstanceId = d.InstanceId
            LEFT JOIN LastRestoreTest lrt ON i.SqlInstance = lrt.SourceServer AND d.[Name] = lrt.[Database]
            LEFT JOIN RunningRestoreTest rrt ON i.SqlInstance = rrt.SqlInstance --AND d.[Name] = rrt.[DBName]
        WHERE
            s.IsServer = 1
            and i.IsActive = 1
            and d.DatabaseStatusId = 2 --2 = Database in normal state
            and i.EnvironmentId = 1 --1 = Production
            and rrt.SqlInstance IS NULL
            AND (d.SizeMb IS NULL
                OR d.SizeMb BETWEEN 5120 AND 512000)
            and i.CountryCode LIKE '%'
            and i.SqlInstance LIKE 'SESTODS036.sweco.se\SWSQL01PC'
            and d.[Name] LIKE '%'
            and d.[Name] NOT IN ('tempdb')
        ORDER BY
            [Last-Restore], i.SqlInstance, d.[Name])

        SELECT
            i.SqlInstance,
            d.[Name] dbName,
            'DestIncstance' DestInstance,
            getdate() RestoreStart,
            d.SizeMb
        FROM
            Instance i
            INNER JOIN [Database] d ON i.InstanceId = d.InstanceId
            INNER JOIN OldestRestoreTest ort ON i.SqlInstance = ort.SqlInstance
        WHERE
            d.DatabaseStatusId = 2 --2 = Database in normal state
            and i.EnvironmentId = 1 --1 = Production
            AND (d.SizeMb IS NULL
                OR d.SizeMb BETWEEN 5120 AND 512000)
            and i.CountryCode LIKE '%'
            and i.SqlInstance LIKE 'SESTODS036.sweco.se\SWSQL01PC'
            and d.[Name] LIKE '%'
            and d.[Name] NOT IN ('tempdb')
"@
        
        # Run a Quegianst the CMDB database to get databases to test #
        Write-Host "$sql" 
        $databases = Invoke-DbaQuery -SqlInstance 'sestods039.sweco.se\swsql16p' -Database CMDB -Query $sql #-As PSObjectArray

        if (!$databases -or $databases.Count -eq 0) {
            Write-Host "No databases found in CMDB for restore." 
            return $null
        } else {
            Write-Host "Found $($databases.Count) databases in CMDB for restore. From: $($databases[0].SqlInstance)" #-Logdir $Logdir -LogLevel "INFO" -LogName $LogName -MinLogLevel $MinLogLevel
        }
    
# $databases | get-member

$DestInstance = 'SESTODS065.sweco.se\SESQL20T'
$OrphanedFiles = Find-DbaOrphanedFile -SqlInstance $DestInstance
$OrphanedFiles | get-Member

if ($OrphanedFiles.Count -gt 0) {
    Write-Host -Message "Found $($OrphanedFiles.Count) orphaned files on $DestInstance. Attempting removal..." 

    foreach ($File in $OrphanedFiles) {
        try {
            # Remove-Item -Path $File.RemoteFilename -Force -ErrorAction Stop
            Write-Host -Message "Removed orphaned file: $($File.RemoteFilename)" 
        }
        catch {
            Write-Host -Message "ERROR: Failed to remove orphaned file $($File.RemoteFilename). Error: $($_.Exception.Message)" 
        }
    }
} else {
    Write-Host -Message "No orphaned files found on $DestInstance." 
}


