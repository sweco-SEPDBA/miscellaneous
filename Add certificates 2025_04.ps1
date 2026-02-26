
Function Update-Certificate {
    param (
        [Parameter(Mandatory)] [string]$FQDN,
        [Parameter(Mandatory)] [string]$Instance,
        [Parameter()] [string]$Aliases,
        [Parameter()] [switch]$UseInstanceAsAlias,
        [Parameter()] [switch]$DbHotel,
        [Parameter()] [switch]$EnableForceEncryption
    )
    # Creates and adds a certificate to the SQL Server instance
    Add-SwNetworkCertificate -FQDN $FQDN -Instance $Instance -Aliases $Aliases -UseInstanceAsAlias:$UseInstanceAsAlias -DbHotel:$DbHotel  -EnableForceEncryption:$EnableForceEncryption -RestartInstance

    #Try connection
    $SqlInstance = "$FQDN\$Instance"
    Write-Host "Try connection to: $SqlInstance" -ForegroundColor Cyan
    function test-connectsql {
        param (
            [Parameter(Mandatory)] [string]$SqlInstance,
            [Parameter(Mandatory)] [switch]$ConnecEncrypted 
        )
        try {
            Write-host "Trying to connect to: $SqlInstance" -ForegroundColor Yellow
            $ServerConnection = Connect-DbaInstance -SqlInstance $SqlInstance -EncryptConnection:$connecEncrypted
            [int]$spid = Invoke-DbaQuery -SqlInstance $ServerConnection -Query "SELECT @@SPID as spid" | select-object -expandproperty spid
            $dbaprocesses = get-dbaprocess -SqlInstance $ServerConnection -ExcludeSystemSpids -Spid $spid | Select-Object SqlInstance, Spid, Login, NetTransport, EncryptOption, AuthScheme 
            Write-Host ($dbaprocesses | Format-List | Out-String)
            $ServerConnection = Disconnect-DbaInstance
            return $true  
        }
        catch {
            Write-Host "Error when trying to connect to: $SqlInstance if you get stuck in this loop, use CTRL+C to kill session. But be aware, this might take a while." -ForegroundColor Red
            return $false
        }
    }

    while (-not (test-connectsql -SqlInstance $SqlInstance -ConnecEncrypted:$true)) {
        Write-Host "No connection yet. Waiting 5 seconds" -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
}


# Run below if you want to suppress the progress bar
#$ProgressPreference = 'SilentlyContinue'



# FIHELDS011.sweco.se	FISQL17P	FALSKT	fisql17p.sql.sweco.se 17052025	FISQL17P.sql.sweco.se, FISQL17P, FIHELDS011.sweco.se	2025-05-16 12:03	CN=fisql17p.sql.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "FIHELDS011.sweco.se" -Instance "FISQL17P" -UseInstanceAsAlias
# NOOSLDS005.sweco.se	NOSQL24P	FALSKT	nosql24p.sql.sweco.se 17052025	NOSQL24P.sql.sweco.se, NOSQL24P, NOOSLDS005.sweco.se	2025-05-16 13:44	CN=nosql24p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "NOOSLDS005.sweco.se" -Instance "NOSQL24P" -UseInstanceAsAlias 
