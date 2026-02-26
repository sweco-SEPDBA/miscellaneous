
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

# SESTODS071.sweco.se	SWSQL45P	SANT	sestods071.sweco.se 31102025	SESTODS071, SESTODS071.sweco.se	2025-10-30 13:04	CN=sestods071.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "SESTODS071.sweco.se" -Instance "SWSQL45P" -EnableForceEncryption
# SESTODS071.sweco.se	SWSQL46P	SANT	sestods071.sweco.se 31102025	SESTODS071, SESTODS071.sweco.se	2025-10-30 13:04	CN=sestods071.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "SESTODS071.sweco.se" -Instance "SWSQL46P" -EnableForceEncryption
# SESTODS071.sweco.se	SWSQL47P	SANT	sestods071.sweco.se 31102025	SESTODS071, SESTODS071.sweco.se	2025-10-30 13:04	CN=sestods071.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "SESTODS071.sweco.se" -Instance "SWSQL47P" -EnableForceEncryption
# gmdkinst01d.sql.sweco.se what is this? SESTODS021\GMDKINST01D We are sysadmins. Fix cert.
Update-Certificate -FQDN "SESTODS021.sweco.se" -Instance "GMDKINST01D" -UseInstanceAsAlias 
# SWSQL11T.sql.sweco.se This is SESTODS021\SWSQL11T We are sysadmins. Fix cert.
Update-Certificate -FQDN "SESTODS021.sweco.se" -Instance "SWSQL11T" -UseInstanceAsAlias
# PLKRKAS033.sweco.se\OPTIMA 
Update-Certificate -FQDN "PLKRKAS033.sweco.se" -Instance "OPTIMA"
# SESTODS965.sweco.se\SWERP23T
Update-Certificate -FQDN "SESTODS965.sweco.se" -Instance "SWERP23T" -UseInstanceAsAlias


