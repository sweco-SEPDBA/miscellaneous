# ── Configuration ──────────────────────────────────────────────────────────────
$sqlDirectory = "C:\Temp\Renewal_261005_run"   # Folder containing your .sql files
$sqlServer    = "SESTODS085\SWSQL28T"              # SQL Server instance
$database     = "TravelExpense"           # Target database
# ───────────────────────────────────────────────────────────────────────────────

# Get all .sql files in the directory (sorted by creation time, oldest first)
$sqlFiles = Get-ChildItem -Path $sqlDirectory -Filter "*.sql" | Sort-Object LastWriteTime

if ($sqlFiles.Count -eq 0) {
    Write-Warning "No .sql files found in: $sqlDirectory"
    exit
}

Write-Host "Found $($sqlFiles.Count) SQL file(s). Starting execution..." -ForegroundColor Cyan

foreach ($file in $sqlFiles) {
    Write-Host "`nExecuting: $($file.Name) (Created: $($file.CreationTime))" -ForegroundColor Yellow

    try {
        $query = Get-Content -Path $file.FullName -Raw

        Invoke-DbaQuery `
            -SqlInstance $sqlServer `
            -Database    $database `
            -Query       $query `
            -EnableException

        Write-Host "  ✔ Success: $($file.Name)" -ForegroundColor Green
    }
    catch {
        Write-Warning "  ✘ Failed: $($file.Name)"
        Write-Warning "  Error: $($_.Exception.Message)"

        # Uncomment the line below to stop execution on first failure
        # break
    }
}

Write-Host "`nDone! Processed $($sqlFiles.Count) file(s)." -ForegroundColor Cyan