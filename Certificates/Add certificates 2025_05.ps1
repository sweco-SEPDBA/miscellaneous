
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


# SESTODS068.sweco.se	SESQL28T	SANT	sesql28t.sql.sweco.se 09062025	SESQL28T.sql.sweco.se, SwecoAppsDev.sql.sweco.se, SESTODS068.sweco.se	2025-06-08 15:11	CN=sesql28t.sql.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "SESTODS068.sweco.se" -Instance "SESQL28T" -UseInstanceAsAlias -Aliases "SwecoAppsDev.sql.sweco.se" -EnableForceEncryption

# sestods069.sweco.se	SWSQL40P	SANT	swsql40p.sql.sweco.se 19062025	SWSQL40P.sql.sweco.se, sestods069.sweco.se	2025-06-18 15:54	CN=swsql40p.sql.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
update-Certificate -FQDN "sestods069.sweco.se" -Instance "SWSQL40P" -UseInstanceAsAlias -EnableForceEncryption

# sestods069.sweco.se	SWSQL41P	SANT	swsql41p.sql.sweco.se 19062025	SWSQL41P.sql.sweco.se, sestods069.sweco.se	2025-06-18 16:49	CN=swsql41p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
update-Certificate -FQDN "sestods069.sweco.se" -Instance "SWSQL41P" -UseInstanceAsAlias -EnableForceEncryption

# SESTODS070.sweco.se	SWSQL42P	SANT	swsql42p.sql.sweco.se 21062025	SWSQL42P.sql.sweco.se, SESTODS070.sweco.se, *.sql.sweco.se	2025-06-20 16:02	CN=swsql42p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
update-Certificate -FQDN "SESTODS070.sweco.se" -Instance "SWSQL42P" -UseInstanceAsAlias -DbHotel -EnableForceEncryption

# SESTODS070.sweco.se	SWSQL43P	FALSKT	swsql43p.sql.sweco.se 26062025	SWSQL43P.sql.sweco.se, SwecoAppsProd.sql.sweco.se, SESTODS070.sweco.se	2025-06-25 16:11	CN=swsql43p.sql.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
update-Certificate -FQDN "SESTODS070.sweco.se" -Instance "SWSQL43P" -UseInstanceAsAlias -Aliases "SwecoAppsProd.sql.sweco.se"

# SESTODS070.sweco.se	SWSQL44P	SANT	swsql44p.sql.sweco.se 27062025	SWSQL44P.sql.sweco.se, SESTODS070.sweco.se, *.sql.sweco.se	2025-06-26 15:36	CN=swsql44p.sql.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
update-Certificate -FQDN "SESTODS070.sweco.se" -Instance "SWSQL44P" -UseInstanceAsAlias -DbHotel -EnableForceEncryption

# GBLDSDS005.sweco.se	GBSQL14P	FALSKT	gbsql14p.sql.sweco.se 17012026	GBSQL14P.sql.sweco.se, GBLDSDS005, GBLDSDS005.sweco.se	2025-07-15 13:55	CN=gbsql14p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "GBLDSDS005.sweco.se" -Instance "GBSQL14P" -UseInstanceAsAlias

# NLAMSDS016.sweco.se	AUTODESKVAULT	SANT	autodeskvault.sql.sweco.se 23022026	AUTODESKVAULT.sql.sweco.se, NLAMSDS016, NLAMSDS016.sweco.se	2025-07-15 13:55	CN=autodeskvault.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
update-Certificate -FQDN "NLAMSDS016.sweco.se" -Instance "AUTODESKVAULT" -EnableForceEncryption

# NLAMSDS028.sweco.se	NLSQL35P	SANT	nlsql35p.sql.sweco.se 30042026	NLSQL35P.sql.sweco.se, NLSQL35P.sql.sweco.net, NLAMSDS028, NLAMSDS028.sweco.se	2025-07-15 13:55	CN=nlsql35p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
update-Certificate -FQDN "NLAMSDS028.sweco.se" -Instance "NLSQL35P" -UseInstanceAsAlias -EnableForceEncryption

# SESTODS065.sweco.se	SESQL20T	FALSKT	sesql20t.sql.sweco.se 26012026	SESQL20T.sql.sweco.se, SESTODS065, SESTODS065.sweco.se, *.sql.sweco.se	2025-07-15 13:55	CN=sesql20t.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
update-Certificate -FQDN "SESTODS065.sweco.se" -Instance "SESQL20T" -UseInstanceAsAlias -DbHotel

# SESTOAS018.sweco.se	autodeskvault	SANT	sestoas018.sweco.se 30082025	sestoas018.sweco.se	2025-08-29 13:09	CN=sestoas018.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
update-Certificate -FQDN "SESTOAS018.sweco.se" -Instance "autodeskvault" -EnableForceEncryption

# SESTOAS018.sweco.se	PLANT3D	SANT	sestoas018.sweco.se 30082025	sestoas018.sweco.se	2025-08-29 13:09	CN=sestoas018.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
update-Certificate -FQDN "SESTOAS018.sweco.se" -Instance "PLANT3D" -EnableForceEncryption


# Not in mw 
# SESTODS111.sweco.se	SESCCM02P	SANT	sesccm02p.sql.sweco.se 24042026	SESCCM02P.sql.sweco.se, SESCCM02P.sql.sweco.net, SESTODS111, SESTODS111.sweco.se	2025-07-15 13:55	CN=sesccm02p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
update-Certificate -FQDN "SESTODS111.sweco.se" -Instance "SESCCM02P" -UseInstanceAsAlias -EnableForceEncryption

Update-Certificate -FQDN LTVNODS003.sweco.se -Instance LTSQL13P -Aliases "LTSQL12P.sql.sweco.se" -EnableForceEncryption -UseInstanceAsAlias
