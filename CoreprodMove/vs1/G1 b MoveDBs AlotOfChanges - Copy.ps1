############################################################################################################
# Set and read this parameters before each execution of a block.
$Databases = "Staging"
############################################################################################################
# First restore before mw
$startTime = Get-Date
$credSecondary = Get-Credential -Message "Enter the sa password for the secondary target" -UserName sa
$startTime = Get-Date

# Secondary node
Get-ChildItem '\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTOCL016$SWSQL01PA' |
Where-Object {$psitem.Name -in ($Databases)} |
Restore-DbaDatabase -SqlInstance SESTODS073.sweco.se\SWSQL06PC -MaintenanceSolutionBackup -IgnoreLogBackup -NoRecovery -SqlCredential $credSecondary 

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "Total Elapsed Time: $($elapsedTime.TotalMinutes) minutes" -ForegroundColor Cyan

