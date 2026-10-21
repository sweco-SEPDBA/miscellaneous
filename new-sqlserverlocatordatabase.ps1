####################################################################################################
# Name..............: Index new SQL Server Locator Database                                         #
# Author............: Ayfie Group AS, Copyright 2021-2023
# Purpose...........: Create a MS SQL Server Locator DB                                            #
####################################################################################################

<#
.Synopsis
   Creates a database on SQL Server for Locator
.DESCRIPTION
   This script can be used to create a database for Locator on a local or remote SQL Server. Requires the T-SQL script 'new-sqlserverlocatordatabase.sql' in the same directory as this PowerShell script.
.EXAMPLE
   .\new-sqlserverlocatordatabase.ps1 -AdServiceAccount 'domain\login_name$'
   Creates a Locator database using the local server with a database named Locator using the default locations for the data and log file and give access to the serviceaccount 'domain\login_name$'.
.EXAMPLE
   .\new-sqlserverlocatordatabase.ps1 -Server SQL1\SQLExpress -Database LocatorDev -DataFileName 'F:\Data\LocatorDev.mdf' -LogFileName 'F:\Log\LocatorDev_log.ldf' -AdServiceAccount 'domain\login_name$'
   Creates a Locator database using the server 'SQL1\SQLExpress' with a database named 'LocatorDev' with the data file 'F:\Data\LocatorDev.mdf' and log file 'F:\Log\LocatorDev_log.ldf' and give access to the serviceaccount 'domainName\login_name$'
.NOTES
    Version 1.2
.PARAMETER Server
    The SQL server where the database will be created. Defaults to the default instance on the local server (or the first named instance if no default instance exists)
.PARAMETER Database
    The name of the database that will be created. Defaults to 'Locator'
.PARAMETER DataFileName
    The fully qualified filename of the data file. Defaults to the name of the database with an .mdf extension in the default data directory of the SQL server.
.PARAMETER LogFileName
    The fully qualified filename of the log file. Defaults to the name of the database plus '_log.ldf' extension in the default log directory of the SQL server.
.PARAMETER AdServiceAccount
    The Active Directory Service account to get access to the database. Format: Must use the pre-Windows 2000 user logon name in the format [<domain>\<login_name>], where <login_name> is the SAM account name.
.PARAMETER TrustServerCertificate
    Whether the SQL server's SSL certificate should be trusted by default or not. If $true, Invoke-Sqlcmd runs with -TrustServerCertificate. Default $true.
#>
#Requires -Version 3.0
Param
(
    [Parameter(Mandatory=$false)]
    [string] $Server,

    [Parameter(Mandatory=$false)]
    [string] $Database="Locator",

    [Parameter(Mandatory=$false)]
    [string] $DataFileName,

    [Parameter(Mandatory=$false)]
    [string] $LogFileName,

    [Parameter(Mandatory=$true)]
    [string] $AdServiceAccount,

    [Parameter(Mandatory=$false)]
    [boolean] $TrustServerCertificate = $true
)

$ScriptFolder = Split-Path -parent $MyInvocation.MyCommand.Definition
$SQLScript = Join-Path $ScriptFolder "new-sqlserverlocatordatabase.sql"

if (-not (Test-Path $SQLScript))
{
    throw "$SQLScript does not exist!"
}
Push-Location
## We need to set TLS 1.2 explicitly
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
#Verify that the NuGet package provider is installed
$p = Get-PackageProvider | where { $_.Name -eq "NuGet" }
if ($p.Count -eq 0)
{
    Write-Host "NuGet package provider is not installed, installing..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Verbose -Force -SkipPublisherCheck
    Write-Host "NuGet package provider has been installed"
}
$r = Get-PSRepository | where { $_.Name -eq "PSGallery" }
if ($r.Count -eq 0)
{
    Write-Host "PSGallery repository is not configured, registering..."
    Register-PSRepository -Default
    Write-Host "Registered PSGallery. Setting Installation Policy to Trusted..."
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Write-Host "Installation Policy set to Trusted for PSGallery"
}
$m = Get-Module -ListAvailable | where { $_.Name -eq "SqlServer"}
if ($m.Count -eq 0)
{
    Write-Host "SQLServer module is not found on this machine, attempting install..."
    Install-Module -Name "SQLServer"
    Write-Host "SQLServer module installed"
}
## Import the SQL Server Module.
$m = Get-Module -ListAvailable | where { $_.Name -eq "SqlServer"}
if ($m.Count -eq 0)
{
    throw "SQLServer module was not found on the machine and could not be installed."
}
else
{
    try
    {
        Import-Module "SqlServer" -DisableNameChecking
    }
    catch
    {
        throw $_.Exception.Message
    }
}
if ($Server -eq "")
{
    # Server was not specified with a command line argument.
    $InstanceNames = @()
    foreach($m in Get-ChildItem SQLSERVER:\SQL) {
        foreach($s in $m.Servers) {
            foreach ($v in $s.Values) {
                foreach ($dr in $v.DomainRoot) {
                    $dr.Refresh()
                    # Add this the the array of instance names
                    $InstanceNames += $dr.DomainInstanceName
                }
            }
        }
    }

    switch ($InstanceNames.Count)
    {
        0
        {
            throw "Unable to locate local SQL instance. Try using the the -Server argument."
        }

        1
        {
            # There is only one instance of SQL locally use that one
            $Server = $InstanceNames[0]
        }

        default
        {
            # There is more than one instance, so prompt the user
            $title = "SQL Instance"
            $message = "Please select the local SQL Instance where the database will be created."
            $optionsArray = @()
            foreach ($i in $InstanceNames) {
                $optionsArray += New-Object System.Management.Automation.Host.ChoiceDescription $i, $i
            }
            $options = [System.Management.Automation.Host.ChoiceDescription[]] ($optionsArray)
            $result = $Host.UI.PromptForChoice($title, $message, $options, 0)
            $Server = $InstanceNames[$result]
        }
    }
}

if ($DataFileName -eq "" -or $LogFileName -eq "")
{
    [void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
    # Connect to the SQL instance to determine locations of default data and/or log directories
    $Srv = New-Object -TypeName Microsoft.SQLserver.management.Smo.server $Server

    if ($DataFileName -eq "")
    {
        $DataFileName = $Srv.DefaultFile + $Database + ".mdf"
    }

    if ($LogFileName -eq "")
    {
        $LogFileName = $Srv.DefaultLog + $Database + "_log.ldf"
    }
}

# Validate service account
if ($AdServiceAccount.Contains("\"))
{
    $AccountName =  $AdServiceAccount.Split("\")[1]
}
else {
    Write-Warning "Not a valid Windows NT name. Give the complete name: <domain\login_name>, where <login_name> is the SAM account name."
    exit 1057
}
$account = Get-ADServiceAccount -Filter {SAMAccountName -eq $AccountName} -Properties PrincipalsAllowedToRetrieveManagedPassword
if ($null -eq $account) {
    Write-Warning "Cannot find AD Service Account. Give the complete name: <domain\login_name>, where <login_name> is the SAM account name."
    exit 1057
}

# Create the array of variables for the T-SQL script
$SQLVars = @()
$SQLVars += "DATABASE_NAME=$Database"
$SQLVars += "DATA_FILENAME=$DataFileName"
$SQLVars += "LOG_FILENAME=$LogFileName"
$SQLVars += "AD_SERVICE_ACCOUNT=$AdServiceAccount"

Pop-Location

$title = "Create the database?"
$message = "The Locator database will be created using these parameters:`n"
$message += "    Server: $Server`n"
$message += "    Database: $Database`n"
$message += "    DataFileName: $DataFileName`n"
$message += "    LogFileName: $LogFileName`n"
$message += "    AdServiceAccount: $AdServiceAccount`n"
$message += "Are you sure you would like to create the database with these parameters?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Creates the database."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Stops the script."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$result = $host.ui.PromptForChoice($title, $message, $options, 1)
switch ($result)
    {
        0 {
            try {
                if ($TrustServerCertificate -eq $true) {
                    Invoke-Sqlcmd -ServerInstance $Server -InputFile $SQLScript -Variable $SQLVars -QueryTimeout 300 -ErrorAction Stop -TrustServerCertificate
                } else {
                    Invoke-Sqlcmd -ServerInstance $Server -InputFile $SQLScript -Variable $SQLVars -QueryTimeout 300 -ErrorAction Stop
                }
            } catch {
                throw $_.Exception
            }
            Write-Output "Successfully created the Locator database using these parameters:"
            Write-Output "          Server: $Server"
            Write-Output "        Database: $Database"
            Write-Output "    DataFileName: $DataFileName"
            Write-Output "     LogFileName: $LogFileName"
            Write-Output "AdServiceAccount: $AdServiceAccount"
        }
        1 {
            Write-Output "The script was cancelled and no changes were made."
        }
    }
