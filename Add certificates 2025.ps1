
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


# This is for Jesper
# ComputerName	InstanceName	ForceEncryption	FriendlyName	DnsNameList
# DEBREDS001.sweco.se	MSSQLSERVER	FALSKT	debreds001.sweco.se 24012025	debreds001.sweco.se
Update-Certificate -FQDN "DEBREDS001.sweco.se" -Instance "MSSQLSERVER" 
# DEBREDS001.sweco.se	IT0607	FALSKT	debreds001.sweco.se 24012025	debreds001.sweco.se
Update-Certificate -FQDN "DEBREDS001.sweco.se" -Instance "IT0607"
# NOOSLDS004.sweco.se	AUTODESKVAULT	FALSKT	nooslds004.sweco.se 21032025	nooslds004.sweco.se
Update-Certificate -FQDN "NOOSLDS004.sweco.se" -Instance "AUTODESKVAULT"
# SESTOAS875.sweco.se	SWSQL37P	FALSKT	sestoas875.sweco.se 21032025	sestoas875.sweco.se
Update-Certificate -FQDN "SESTOAS875.sweco.se" -Instance "SWSQL37P"
# SESTODS039.sweco.se	SWSQL15P	FALSKT	swsql15p.sql.sweco.se 21032025	swsql15p.sql.sweco.se, safecom_db.sql.sweco.se, sestods039.Sweco.se
Update-Certificate -FQDN "SESTODS039.sweco.se" -Instance "SWSQL15P" -Aliases "safecom_db.sql.sweco.se" -UseInstanceAsAlias
# SESTODS051.sweco.se	SWSQL27P	FALSKT	swsql27p.sql.sweco.se 21032025	swsql27p.sql.sweco.se, ssisprod2.sql.sweco.se, sestods051.Sweco.se
Update-Certificate -FQDN "SESTODS051.sweco.se" -Instance "SWSQL27P" -Aliases "ssisprod2.sql.sweco.se" -UseInstanceAsAlias
# SESTODS952.sweco.se	SWERP06PC	FALSKT	swerp06pc.sql.sweco.se 21032025	swerp06pc.sql.sweco.se, reports.maconomy.sql.sweco.se, sestods952.Sweco.se
Update-Certificate -FQDN "SESTODS952.sweco.se" -Instance "SWERP06PC" -Aliases "reports.maconomy.sql.sweco.se" -UseInstanceAsAlias
# SESTODS950.sweco.se	SWERP04PC	FALSKT	swerp04pc.sql.sweco.se 21032025	swerp04pc.sql.sweco.se, swerp02pl.sweco.se, sestods950.Sweco.se
Update-Certificate -FQDN "SESTODS950.sweco.se" -Instance "SWERP04PC" -Aliases "swerp02pl.sweco.se" 
# SESTODS961.sweco.se	SWERP13T	SANT	swerp13t.sql.sweco.se 21032025	swerp13t.sql.sweco.se, reports.macotest.sql.sweco.se, sestods961.sweco.se
Update-Certificate -FQDN "SESTODS961.sweco.se" -Instance "SWERP13T" -Aliases "reports.macotest.sql.sweco.se" -UseInstanceAsAlias -EnableForceEncryption





#This is for Pär
# PLKRKAS015.sweco.se	UNIRCP	FALSKT	plkrkas015.sweco.se 21032025	plkrkas015.sweco.se
Update-Certificate -FQDN "PLKRKAS015.sweco.se" -Instance "UNIRCP"
# PLKRKPS004.sweco.se	SAFECOMEXPRESS	FALSKT	plkrkps004.sweco.se 21032025	plkrkps004.sweco.se
Update-Certificate -FQDN "PLKRKPS004.sweco.se" -Instance "SAFECOMEXPRESS"
# SEGOTPS001.sweco.se	SAFECOMEXPRESS	FALSKT	segotps001.sweco.se 21032025	segotps001.sweco.se
Update-Certificate -FQDN "SEGOTPS001.sweco.se" -Instance "SAFECOMEXPRESS"
# SESTOAS017.sweco.se	SESQL44P	FALSKT	sestoas017.sweco.se 21032025	sestoas017.sweco.se
Update-Certificate -FQDN "SESTOAS017.sweco.se" -Instance "SESQL44P"
# SESTOAS122.sweco.se	AUTODESK	FALSKT	sestoas122.sweco.se 21032025	sestoas122.sweco.se
Update-Certificate -FQDN "SESTOAS122.sweco.se" -Instance "AUTODESK"
# SESTODS040.sweco.se	SWSQL19P	FALSKT	swsql19p.sql.sweco.se 21032025	swsql19p.sql.sweco.se, reports.sql.sweco.se, sestods040.Sweco.se
Update-Certificate -FQDN "SESTODS040.sweco.se" -Instance "SWSQL19P" -Aliases "reports.sql.sweco.se" -UseInstanceAsAlias
# SESTODS041.sweco.se	SWSQL20P	FALSKT	swsql20p.sql.sweco.se 21032025	swsql20p.sql.sweco.se, imc_db, sql.sweco.se, sestods041.Sweco.se
Update-Certificate -FQDN "SESTODS041.sweco.se" -Instance "SWSQL20P" -Aliases "imc_db.sql.sweco.se" -UseInstanceAsAlias
# SESTODS059.sweco.se	SWSQL34P	FALSKT	swsql34p.sql.sweco.se 21032025	swsql34p.sql.sweco.se, sestods059.Sweco.se, *.sql.sweco.se
Update-Certificate -FQDN "SESTODS059.sweco.se" -Instance "SWSQL34P"  -DbHotel  
# SESTOPS008.sweco.se	SAFECOMEXPRESS	FALSKT	sestops008.sweco.se 21032025	sestops008.sweco.se
Update-Certificate -FQDN "SESTOPS008.sweco.se" -Instance "SAFECOMEXPRESS"





Update-Certificate -FQDN "NLAMSDS022.sweco.se" -Instance "NLSQL16P" -UseInstanceAsAlias

$SqlInstance = "NLAMSDS022.sweco.se\NLSQL16P"
Get-DbaNetworkCertificate -SqlInstance  $SqlInstance | ForEach-Object {
    [pscustomobject]@{
		ComputerName = $_.ComputerName
		InstanceName = $_.InstanceName
		ForceEncryption = $_.ForceEncryption
		FriendlyName = $_.FriendlyName
		DnsNameList = ($_.DnsNameList -join ', ')  # Join ArrayList to a comma-separated string
		Expires = $_.Expires
		IssuedTo = $_.IssuedTo
		IssuedBy = $_.IssuedBy
    }
}

#Tests
Update-Certificate -FQDN "SESTODS061.sweco.se" -Instance "SWSQL21T" -UseInstanceAsAlias  -DbHotel


Update-Certificate -FQDN SESTODS054.sweco.se -Instance SWSQL36P -DbHotel


get-dbaprocess -SqlInstance "SESTODS061.sweco.se\SWSQL21T" -ExcludeSystemSpids 

GET-DBAUPTIME -SqlInstance "SESTODS061.sweco.se\SWSQL21T"

$Instance = 'SWSQL21T'

if ($Instance -eq 'MSSQLSERVER') {
    $Name = 'MSSQLSERVER'
} else {
    $Name = 'MSSQL$'+$Instance
}
Invoke-Command -ComputerName "sestods061.sweco.se" -ScriptBlock {

    Restart-Service -Name $Using:Name -Force
}

Install-SwServerInstance -FQDN DEFRADS013.sweco.se

