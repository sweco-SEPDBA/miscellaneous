# Copy-SwDbToTest [[-OldServer] <String>] [[-OldInstance] <String>] [-DestServer] <String>
#  [[-Destinstance] <String>] [-Databases] <String[]> [[-Database_ToStay] <String[]>]
#  [[-TempFilePath] <String>] [[-BackupRootPath] <String>] [[-IgnoreLogBackup] <Boolean>] [[-Suffix] <String>]
#  [[-SkipOrphanFix] <Boolean>] [[-CopyOnlyBackup] <Boolean>]


$CopyCommands= @{
        OldServer       = "SESTOCL023"
        OldInstance     = "SWSQL06PA"
        DestServer      = "SESTODS085.sweco.se"
        Destinstance    = "SWSQL28T"
        Databases       = @( "metroeko", "swecoaccess", "swecocoreexpo", "webbeko" )
        Database_ToStay = @("swecocoreexpo")
        TempFilePath    = "C:\Temp\Reneval_261005_1"
        BackupRootPath  = "\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\CoreTest2"
        Suffix          = "_20261005"
        IgnoreLogBackup = $false
    }
    Copy-SwDbToTest @CopyCommands


Copy-DbaDatabase -Source SEDCXAS906\SWERP27T -Destination SEDCXDS910\SWERP20T -Database conv6 -BackupRestore -UseLastBackup -NewName mactst26 
Copy-DbaDatabase -Source SEDCXAS906\SWERP27T -Destination SEDCXDS920\SWERP20T -Database conv6 -BackupRestore -UseLastBackup -NewName mactst26 

    $CopyCommands= @{
        OldServer       = "SESTOCL023"
        OldInstance     = "SWSQL06PA"
        DestServer      = "SESTODS085.sweco.se"
        Destinstance    = "SWSQL28T"
        Databases       = @("staging", "swecocore", "TravelExpense")
        Database_ToStay = @("staging", "swecocore")
        TempFilePath    = "C:\Temp\Reneval_261005_2"
        BackupRootPath  = "\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\PlayGround"
        Suffix          = "_20261005"
        IgnoreLogBackup = $false
    }
    Copy-SwDbToTest @CopyCommands

Restore-DbaDatabase -SqlInstance SESTODS085\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\Coretest2\SESTOCL023$SWSQL06PA\staging' -MaintenanceSolutionBackup 
Restore-DbaDatabase -SqlInstance SESTODS085\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\Coretest2\SESTOCL023$SWSQL06PA\swecocore' -MaintenanceSolutionBackup 
Restore-DbaDatabase -SqlInstance SESTODS085\SWSQL28T -Path '\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\Coretest2\SESTOCL023$SWSQL06PA\TravelExpense' -MaintenanceSolutionBackup 


#" SEDCXAS906\SWERP27T och skriva över mactst26 på SEDCXDS910\SWERP20T