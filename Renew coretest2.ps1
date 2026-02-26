# Copy-SwDbToTest [[-OldServer] <String>] [[-OldInstance] <String>] [-DestServer] <String>
#  [[-Destinstance] <String>] [-Databases] <String[]> [[-Database_ToStay] <String[]>]
#  [[-TempFilePath] <String>] [[-BackupRootPath] <String>] [[-IgnoreLogBackup] <Boolean>] [[-Suffix] <String>]
#  [[-SkipOrphanFix] <Boolean>] [[-CopyOnlyBackup] <Boolean>]


$CopyCommands= @{
        OldServer       = "SESTOCL023"
        OldInstance     = "SWSQL06PA"
        DestServer      = "SESTODS085.sweco.se"
        Destinstance    = "SWSQL28T"
        Databases       = @( "staging", "TravelExpense" )
        TempFilePath    = "C:\Temp\Reneval_250409_2"
        BackupRootPath  = "\\sweco.se\sw\IT\Backup\SQL\TemporaryBackups\TestRenewal_DoNotDelete"
        Suffix          = "_Copy"
    }
    Copy-SwDbToTest @CopyCommands

