# Test-SwRestoreDatabase -DestInstance SESTODS076.sweco.se\SESQL37T -LogDir C:\Temp -DBMinSizeMB 5120 -DBMaxSizeMB 512000 -MinLogLevel DEBUG -LogName Test-SwRestoreDatabase-Medium
$GetSwNextDatabaseForRestoreParams = @{
    CMDBInstance      = "SESTODS039.sweco.se\SWSQL16P"
    CMDBDatabase      = "CMDB"
    DestInstance      = "SESTODS076.sweco.se\SESQL37T"
    SqlInstance       = "SESTODS075.sweco.se\SWSQL48P"
    CountryCode       = "%"
    DatabaseName      = "%"
    DBMinSizeMB       = "5120"
    DBMaxSizeMB       = "512000"
    LogDir            = "C:\Temp"
    LogName           = "Test-SwRestoreDatabase-Medium"
    Minloglevel       = "DEBUG"
    BackupPathPattern = "\\sweco.se\sw\IT\Backup"
}

Write-SwLog - "Before: Get-SwNextDatabaseForRestore" 
$RestoreTestDBs = Get-SwNextDatabaseForRestore @GetSwNextDatabaseForRestoreParams

$BackupPathRegex = [regex]::new('(?i)^' + [regex]::Escape($BackupPathPattern))
# Log the result of the backup path check
Write-Host "DEBUG REGEX USED: $BackupPathRegex" 

$AllBackups = Get-DbaDbBackupHistory -SqlInstance SESTODS075.sweco.se\SWSQL48P -LastFull |
        Where-Object { $_.Database -in $RestoreTestDBs.dbName }

$BackupPathPattern = "\\sweco.se\sw\IT\Backup"
$BackupPathRegex = [regex]::new('(?i)^' + [regex]::Escape($BackupPathPattern))
foreach ($b in $AllBackups) {
    $cleanPath = $b.FullName -replace '^[{}]+|[{}]+$', ''
    $match = [regex]::IsMatch($cleanPath, $BackupPathRegex)
    Write-Host "Path: $cleanPath, TestPattern: $BackupPathRegex, Result: $Match"
}

$IsNotNetworkBackups = $AllBackups |
    Where-Object {
        $cleanPath = $_.FullName -replace '^[{}]+|[{}]+$', ''
        $match = [regex]::IsMatch($cleanPath, $BackupPathRegex)

        # Log the result of the backup path check
        Write-Host -Message "TEST MATCH [$($_.Database)] Path: '$cleanPath' - REGEX: $BackupPathRegex - MATCH: $match" 

        -not $match
    } |
    Select-Object -Property SqlInstance, Database -Unique

    $BackupPathPattern = "\\sweco.se\\sw\\IT\\Backup"
    $AllBackups |     Select-Object {$_.Fullname.Replace('{','').Replace('}','') }

    $AllBackups |     Where-Object {$_.Fullname.Replace('{','').Replace('}','') -notlike "$BackupPathPattern*"} | Select-Object {$_.Fullname.Replace('{','').Replace('}','') }

