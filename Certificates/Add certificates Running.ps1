
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
# EETLLDS003.sweco.se	EESQL33P	FALSKT	eetllds003.sweco.se 24012025	eetllds003.sweco.se
# SESTODS964.sweco.se	SWERP15T	SANT	swerp15t.sql.sweco.se 30012026	SWERP15T.sql.sweco.se, reports.sandbox.sql.sweco.se, SESTODS964, SESTODS964.sweco.se

Set-DbatoolsInsecureConnection -SessionOnly

# UPDATE-Certificate -FQDN "SESTOAS762.sweco.se" -Instance "SESQL48P" -UseInstanceAsAlias -EnableForceEncryption
# Update-Certificate -FQDN "DEFRADS009.sweco.se" -Instance "DESQL15P" -UseInstanceAsAlias -EnableForceEncryption
# UPDATE-Certificate -FQDN "DEFRADS012.sweco.se" -Instance "CAL" -UseInstanceAsAlias -EnableForceEncryption


#Update-Certificate -FQDN "NLDCXDS005.sweco.se" -Instance "NLSQL15T" -EnableForceEncryption 
#Update-Certificate -FQDN "SEDCXDS011.sweco.se" -Instance "SWERP04PC" -EnableForceEncryption -Aliases "maconomyreports.sql.sweco.net" 
# Update-Certificate -FQDN "VSQL-IMPAR1.sweco.se" -Instance "VSQLIMPAR1" 

# Update-Certificate -FQDN "SESTODS964.sweco.se" -Instance "SWERP15T" -UseInstanceAsAlias -Aliases "reports.sandbox.sql.sweco.se" -EnableForceEncryption

# UPDATE-CERTIFICATE -FQDN SESTODS951.sweco.se -Instance SWERP04PC -Aliases swerp02pl.sweco.se
# update-certificate -FQDN DEFRAAS017.sweco.se -Instance SQLEXPRESS
# Update-Certificate -FQDN FIHELAS099.sweco.se -Instance SQLEXPRESS
# Update-Certificate -FQDN SESTOAS888.sweco.se -Instance SQLEXPRESS
# update-certificate -FQDN PLPOZAS003.sweco.se -Instance SMART2
# update-certificate -FQDN GBLDSAS004.sweco.se -Instance NET2
# Update-Certificate -FQDN PLPOZAS002.sweco.se -Instance HRB
# Update-Certificate -FQDN GBLDSDS002.sweco.se -Instance GBSQL11P -UseInstanceAsAlias
# Update-Certificate -FQDN SEMMADS002.sweco.se -Instance SESQL39P -UseInstanceAsAlias
# Update-Certificate -FQDN DEHANAS003.sweco.se -Instance BASYS
# Update-Certificate -FQDN SESTOAS077.sweco.se -Instance SESQL45P -UseInstanceAsAlias
# Update-Certificate -FQDN SESTODS017.sweco.se -Instance SWSQL48P -EnableForceEncryption -dbhotel
# Update-Certificate -FQDN SESTODS075.sweco.se -Instance SWSQL48P -EnableForceEncryption -DbHotel


# SESTODS951.sweco.se	SWERP04PC	False	sestods951.sweco.se 17092026	swerp02pl.sweco.se, SESTODS951, SESTODS951.Sweco.se	2026-09-17 11:40:02	CN=sestods951.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# DEFRAAS017.sweco.se	SQLEXPRESS	False	defraas017.sweco.se 17092026	DEFRAAS017, DEFRAAS017.sweco.se	2026-09-17 18:27:46	CN=defraas017.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# FIHELAS099.sweco.se	SQLEXPRESS	False	fihelas099.sweco.se 17092026	FIHELAS099, FIHELAS099.Sweco.se	2026-09-17 18:29:48	CN=fihelas099.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# SESTOAS888.sweco.se	SQLEXPRESS	False	sestoas888.sweco.se 17092026	SESTOAS888, SESTOAS888.Sweco.se	2026-09-17 18:30:52	CN=sestoas888.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# PLPOZAS003.sweco.se	SMART2	False	plpozas003.sweco.se 17092026	PLPOZAS003, PLPOZAS003.Sweco.se	2026-09-17 18:53:06	CN=plpozas003.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# GBLDSAS004.sweco.se	NET2	False	gbldsas004.sweco.se 17092026	GBLDSAS004, GBLDSAS004.Sweco.se	2026-09-17 19:38:48	CN=gbldsas004.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# PLPOZAS002.sweco.se	HRB	False	plpozas002.sweco.se 17092026	PLPOZAS002, PLPOZAS002.Sweco.se	2026-09-17 19:39:57	CN=plpozas002.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# GBLDSDS002.sweco.se	GBSQL11P	False	gbsql11p.sql.sweco.se 17092026	GBSQL11P.sql.sweco.se, GBSQL11P.sql.sweco.net, GBLDSDS002, GBLDSDS002.Sweco.se	2026-09-17 20:02:30	CN=gbsql11p.sql.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# SEMMADS002.sweco.se	SESQL39P	False	sesql39p.sql.sweco.se 17092026	SESQL39P.sql.sweco.se, SESQL39P.sql.sweco.net, SEMMADS002, SEMMADS002.sweco.se	2026-09-17 20:48:47	CN=sesql39p.sql.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# DEHANAS003.sweco.se	BASYS	False	dehanas003.sweco.se 17092026	DEHANAS003, DEHANAS003.Sweco.se	2026-09-17 20:55:48	CN=dehanas003.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# SESTOAS077.sweco.se	SESQL45P	False	sesql45p.sql.sweco.se 17092026	SESQL45P.sql.sweco.se, SESQL45P.sql.sweco.net, SESTOAS077, SESTOAS077.Sweco.se	2026-09-17 20:56:52	CN=sesql45p.sql.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# SESTODS017.sweco.se	SWSQL48P	True	sestods017.sweco.se 26092026	*.sweco.se, SESTODS017, SESTODS017.sweco.se	2026-09-26 15:29:12	CN=sestods017.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# SESTODS075.sweco.se	SWSQL48P	True	sestods075.sweco.se 26092026	*.sweco.se, SESTODS075, SESTODS075.sweco.se	2026-09-26 16:14:29	CN=sestods075.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	

# update-certificate -FQDN NLAMSAS243 -Instance NET2 
# UPDATE-CERTIFICATE -FQDN SESTOAS635 -Instance SESQL11P
# UPDATE-CERTIFICATE -FQDN SESTOAS635 -Instance SESQL51P 
# UPDATE-CERTIFICATE -FQDN SESTOAS592 -Instance SQLEXPRESS

# Update-Certificate -FQDN GBMAHAS002.sweco.se -Instance DESIGNSAP
# UPDATE-CERTIFICATE -FQDN SESTODS079.sweco.se -Instance SWSQL49P -DbHotel
# Update-Certificate -FQDN SESTODS080.sweco.se -Instance SWSQL27T -DbHotel

# update-certificate -FQDN SESTODS054.sweco.se -Instance SWSQL30P -UseInstanceAsAlias
# UPDATE-CERTIFICATE -FQDN DEAGBAS003.sweco.se -Instance ITWO_CIVIL
# UPDATE-CERTIFICATE -FQDN DEAGBAS003.sweco.se -Instance ITWO_CIVIL2020
# UPDATE-CERTIFICATE -FQDN NLAMSAS075.sweco.se -Instance SQL_MONITOR
# Update-Certificate -FQDN NLDCXDS007.sweco.se -Instance NLSQL16T -UseInstanceAsAlias

# Update-Certificate -FQDN SESTOAS021.sweco.se -Instance AUTODESKVAULT
# Update-Certificate -FQDN SESTOAS021.sweco.se -Instance PLANT3D
# Update-Certificate -FQDN SESTODS082.sweco.se -Instance SWSQL50P -Aliases '*.sweco.se, *.sweco.net'
# Update-Certificate -FQDN SESTODS081.sweco.se -Instance SWSQL50P -Aliases '*.sweco.se, *.sweco.net'
# Update-Certificate -FQDN SESTODS083.sweco.se -Instance SESQL49P -UseInstanceAsAlias

# SESTOAS021.sweco.se	AUTODESKVAULT	True	sestoas021.sweco.se 11112026	SESTOAS021, SESTOAS021.sweco.se	2026-11-11 11:15:56	CN=sestoas021.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# SESTOAS021.sweco.se	PLANT3D	True	sestoas021.sweco.se 11112026	SESTOAS021, SESTOAS021.sweco.se	2026-11-11 11:15:56	CN=sestoas021.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# SESTODS082.sweco.se	SWSQL50P	True	sestods082.sweco.se 12112026	*.sweco.net, *.sweco.se, SESTODS082, SESTODS082.sweco.se	2026-11-12 12:23:03	CN=sestods082.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# SESTODS081.sweco.se	SWSQL50P	True	sestods081.sweco.se 12112026	*.sweco.net, *.sweco.se, SESTODS081, SESTODS081.sweco.se	2026-11-12 12:26:02	CN=sestods081.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
# SESTODS083.sweco.se	SESQL49P	True	sesql49p.sql.sweco.se 21112026	SESQL49P.sql.sweco.se, SESQL49P.sql.sweco.net, SESTODS083, SESTODS083.sweco.se	2026-11-21 14:26:15	CN=sesql49p.sql.sweco.se	CN=Sweco SubCA 06, O=Sweco AB, C=SE	
