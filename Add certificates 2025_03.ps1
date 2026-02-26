
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

# Update-Certificate -FQDN SESTODS072.sweco.se -Instance SWSQL06PC -EnableForceEncryption -Aliases "SWSQL06PL.sweco.se,coreprod.sql.sweco.se"
# Update-Certificate -FQDN SESTODS073.sweco.se -Instance SWSQL06PC -EnableForceEncryption -Aliases "SWSQL06PL.sweco.se,coreprod.sql.sweco.se"

# Run below if you want to suppress the progress bar
#$ProgressPreference = 'SilentlyContinue'



# NLAMSDS010.sweco.se	SWECO01	FALSKT	nlamsds010.sweco.se 18042025	nlamsds010.sweco.se	2025-04-17 20:29	CN=nlamsds010.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "NLAMSDS010.sweco.se" -Instance "SWECO01"
# NLAMSDS026.Sweco.se	NLSQL20P	FALSKT	nlamsds026.sweco.se 18042025	nlamsds026.sweco.se	2025-04-17 20:30	CN=nlamsds026.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "NLAMSDS026.Sweco.se" -Instance "NLSQL20P"
# FIHELPS007.sweco.se	SAFECOMEXPRESS	FALSKT	fihelps007.sweco.se 18042025	fihelps007.sweco.se	2025-04-17 21:32	CN=fihelps007.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "FIHELPS007.sweco.se" -Instance "SAFECOMEXPRESS"
# GBLDSPS003.sweco.se	SAFECOMEXPRESS	FALSKT	gbldsps003.sweco.se 18042025	gbldsps003.sweco.se	2025-04-17 21:33	CN=gbldsps003.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "GBLDSPS003.sweco.se" -Instance "SAFECOMEXPRESS"

# NLAMSPS008.sweco.se	SAFECOMEXPRESS	FALSKT	nlamsps008.sweco.se 18042025	nlamsps008.sweco.se	2025-04-17 21:33	CN=nlamsps008.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "NLAMSPS008.sweco.se" -Instance "SAFECOMEXPRESS"
# NLAMSPS009.sweco.se	SAFECOMEXPRESS	FALSKT	nlamsps009.sweco.se 18042025	nlamsps009.sweco.se	2025-04-17 21:34	CN=nlamsps009.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "NLAMSPS009.sweco.se" -Instance "SAFECOMEXPRESS"
# DKCPHPS006.sweco.se	SAFECOMEXPRESS	FALSKT	dkcphps006.sweco.se 18042025	dkcphps006.sweco.se	2025-04-17 21:34	CN=dkcphps006.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "DKCPHPS006.sweco.se" -Instance "SAFECOMEXPRESS"
# DEFRAPS003.sweco.se	SAFECOMEXPRESS	FALSKT	defraps003.sweco.se 18042025	defraps003.sweco.se	2025-04-17 21:39	CN=defraps003.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "DEFRAPS003.sweco.se" -Instance "SAFECOMEXPRESS"
# DEFRADS002.sweco.se	KOBOLD	FALSKT	defrads002.sweco.se 18042025	defrads002.sweco.se	2025-04-17 21:42	CN=defrads002.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "DEFRADS002.sweco.se" -Instance "KOBOLD"
# DEFRADS008.sweco.se	CPRO	FALSKT	defrads008.sweco.se 18042025	defrads008.sweco.se	2025-04-17 21:42	CN=defrads008.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "DEFRADS008.sweco.se" -Instance "CPRO"
# gbmahas002.sweco.se	PLANASSESSOR6	FALSKT	gbmahas002.sweco.se 18042025	gbmahas002.sweco.se	2025-04-17 21:44	CN=gbmahas002.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "gbmahas002.sweco.se" -Instance "PLANASSESSOR6"
# NLAMSAS023.sweco.se	SWECO01	FALSKT	nlamsas023.sweco.se 18042025	nlamsas023.sweco.se	2025-04-17 21:46	CN=nlamsas023.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "NLAMSAS023.sweco.se" -Instance "SWECO01"


#For Jesper


# CZPRGDS002.sweco.se	CZSQL11P	FALSKT	czsql11p.sql.sweco.se 18042025	CZSQL11P.sql.sweco.se, CZPRGDS002.Sweco.se	2025-04-17 14:56	CN=czsql11p.sql.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "CZPRGDS002.sweco.se" -Instance "CZSQL11P" -UseInstanceAsAlias
# DEFRADS003.sweco.se	DESQL11P	FALSKT	desql11p.sql.sweco.se 18042025	DESQL11P.sql.sweco.se, DEFRADS003.Sweco.se	2025-04-17 14:57	CN=desql11p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "DEFRADS003.sweco.se" -Instance "DESQL11P" -UseInstanceAsAlias
# DEFRADS005.Sweco.se	DESQL13P	FALSKT	desql13p.sql.sweco.se 18042025	DESQL13P.sql.sweco.se, DEFRADS005.Sweco.se	2025-04-17 14:58	CN=desql13p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "DEFRADS005.Sweco.se" -Instance "DESQL13P" -UseInstanceAsAlias
# DKCPHDS004.Sweco.se	DKSQL12P	FALSKT	dksql12p.sql.sweco.se 18042025	DKSQL12P.sql.sweco.se, DKCPHDS004.Sweco.se	2025-04-17 14:59	CN=dksql12p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "DKCPHDS004.Sweco.se" -Instance "DKSQL12P" -UseInstanceAsAlias
# NLAMSDS021.sweco.se	NLSQL15P	FALSKT	nlsql15p.sql.sweco.se 18042025	NLSQL15P.sql.sweco.se, NLAMSDS021.Sweco.se	2025-04-17 15:04	CN=nlsql15p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "NLAMSDS021.sweco.se" -Instance "NLSQL15P" -UseInstanceAsAlias
# NLAMSDS026.Sweco.se	NLSQL21P	FALSKT	nlsql21p.sql.sweco.se 18042025	NLSQL21P.sql.sweco.se, NLAMSDS026.Sweco.se	2025-04-17 15:06	CN=nlsql21p.sql.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "NLAMSDS026.Sweco.se" -Instance "NLSQL21P" -UseInstanceAsAlias
# NLAMSDS027.Sweco.se	NLSQL22P	FALSKT	nlsql22p.sql.sweco.se 18042025	NLSQL22P.sql.sweco.se, NLAMSDS027.Sweco.se	2025-04-17 15:06	CN=nlsql22p.sql.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se  
Update-Certificate -FQDN "NLAMSDS027.Sweco.se" -Instance "NLSQL22P" -UseInstanceAsAlias
# SESTODS043.sweco.se	SWSCOM02P	FALSKT	swscom02p.sql.sweco.se 18042025	SWSCOM02P.sql.sweco.se, SESTODS043.Sweco.se	2025-04-17 15:06	CN=swscom02p.sql.sweco.se	CN=Sweco SubCA 02, DC=sweco, DC=se
Update-Certificate -FQDN "SESTODS043.sweco.se" -Instance "SWSCOM02P" -UseInstanceAsAlias
# NLAMSDS003.sweco.se	SWECO01	FALSKT	nlamsds003.sweco.se 18042025	nlamsds003.sweco.se	2025-04-17 19:57	CN=nlamsds003.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "NLAMSDS003.sweco.se" -Instance "SWECO01"
# DEWIKOSQL02.sweco.se	MSSQLSERVER	FALSKT	dewikosql02.sweco.se 18042025	dewikosql02.sweco.se	2025-04-17 20:13	CN=dewikosql02.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "DEWIKOSQL02.sweco.se" -Instance "MSSQLSERVER"
# FIHELDS014.sweco.se	MSSQLSERVER	FALSKT	fihelds014.sweco.se 18042025	fihelds014.sweco.se	2025-04-17 20:13	CN=fihelds014.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "FIHELDS014.sweco.se" -Instance "MSSQLSERVER"
# NLAMSAS116.sweco.se	SQLEXPRESS	FALSKT	nlamsas116.sweco.se 18042025	nlamsas116.sweco.se	2025-04-17 20:29	CN=nlamsas116.sweco.se	CN=Sweco SubCA 01, DC=sweco, DC=se
Update-Certificate -FQDN "NLAMSAS116.sweco.se" -Instance "SQLEXPRESS"
