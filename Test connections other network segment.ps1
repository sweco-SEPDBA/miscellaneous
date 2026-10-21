
$cred = Get-Credential

Connect-DbaInstance -SqlInstance SESTODS111.sweco.se\SESCCM02P -SqlCredential $cred
Connect-DbaInstance -SqlInstance 10.254.6.65\SESCCM02P

# Test the EXACT format that worked for you
$formats = @(
    "SESTODS111\SESCCM02P",                          # NetBIOS + instance
    "SESTODS111.sweco.se\SESCCM02P",                 # FQDN + instance  
    "SESTODS111",                                     # NetBIOS only
    "SESTODS111.sweco.se",                           # FQDN only
    "SESTODS111.sweco.se\SESCCM02P,1433"             # With port
    "SESCCM02P.sql.sweco.se"
)

foreach ($format in $formats) {
    Write-Host "`nTesting format: $format" -ForegroundColor Cyan
    
    # Test 1: Raw SqlConnection (your working method)
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection("Server=$format;Integrated Security=true")
        $conn.Open()
        Write-Host "  ✓ SqlConnection works" -ForegroundColor Green
        $conn.Close()
    } catch {
        Write-Host "  ✗ SqlConnection failed: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    
    # Test 2: dbatools
    try {
        $server = Connect-DbaInstance -SqlInstance $format -EncryptConnection:$false
        Write-Host "  ✓ dbatools works" -ForegroundColor Green
        $server.ConnectionContext.Disconnect()
    } catch {
        Write-Host "  ✗ dbatools failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
}

# Test your EXACT working scenario
Write-Host "Testing exact working format..." -ForegroundColor Yellow
$conn = New-Object System.Data.SqlClient.SqlConnection("Server=SESTODS111.sweco.se\SESCCM02P;Integrated Security=true")
$conn.Open()
Write-Host "Connection String: $($conn.ConnectionString)" -ForegroundColor Green
Write-Host "Server Version: $($conn.ServerVersion)" -ForegroundColor Green
Write-Host "Database: $($conn.Database)" -ForegroundColor Green

# Query to see what auth was used
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT auth_scheme, net_transport, local_tcp_port FROM sys.dm_exec_connections WHERE session_id = @@SPID"
$reader = $cmd.ExecuteReader()
if ($reader.Read()) {
    Write-Host "Auth Scheme: $($reader['auth_scheme'])" -ForegroundColor Green
    Write-Host "Transport: $($reader['net_transport'])" -ForegroundColor Green
    Write-Host "Port: $($reader['local_tcp_port'])" -ForegroundColor Green
}
$reader.Close()
$conn.Close()


# Load SMO assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

# Test 1: SMO with default settings (what dbatools likely does)
Write-Host "`n=== Test 1: SMO Default ===" -ForegroundColor Yellow
try {
    $smo = New-Object Microsoft.SqlServer.Management.Smo.Server("SESTODS111.sweco.se\SESCCM02P")
    $smo.ConnectionContext.LoginSecure = $true
    $smo.ConnectionContext.Connect()
    Write-Host "✓ SMO Default works!" -ForegroundColor Green
    Write-Host "Connection String: $($smo.ConnectionContext.ConnectionString)"
    $smo.ConnectionContext.Disconnect()
} catch {
    Write-Host "✗ SMO Default failed: $($_.Exception.InnerException.Message)" -ForegroundColor Red
}

# Test 2: SMO with explicit connection string
Write-Host "`n=== Test 2: SMO with SqlConnectionInfo ===" -ForegroundColor Yellow
try {
    $connInfo = New-Object Microsoft.SqlServer.Management.Common.SqlConnectionInfo("SESTODS111.sweco.se\SESCCM02P")
    $connInfo.UseIntegratedSecurity = $true
    $serverConn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($connInfo)
    $serverConn.Connect()
    Write-Host "✓ SMO SqlConnectionInfo works!" -ForegroundColor Green
    Write-Host "Connection String: $($serverConn.ConnectionString)"
    $smo2 = New-Object Microsoft.SqlServer.Management.Smo.Server($serverConn)
    Write-Host "Databases: $($smo2.Databases.Count)"
    $serverConn.Disconnect()
} catch {
    Write-Host "✗ SMO SqlConnectionInfo failed: $($_.Exception.InnerException.Message)" -ForegroundColor Red
}

# Test 3: SMO using the working SqlConnection
Write-Host "`n=== Test 3: SMO from working SqlConnection ===" -ForegroundColor Yellow
try {
    $conn = New-Object System.Data.SqlClient.SqlConnection("Server=SESTODS111.sweco.se\SESCCM02P;Integrated Security=true")
    $conn.Open()
    $serverConn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($conn)
    $smo3 = New-Object Microsoft.SqlServer.Management.Smo.Server($serverConn)
    Write-Host "✓ SMO from SqlConnection works!" -ForegroundColor Green
    Write-Host "Databases: $($smo3.Databases.Count)"
    $conn.Close()
} catch {
    Write-Host "✗ SMO from SqlConnection failed: $($_.Exception.InnerException.Message)" -ForegroundColor Red
}

# Load SMO assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

# Before loading dbatools
Write-Host "`n=== Assemblies BEFORE dbatools ===" -ForegroundColor Yellow
[AppDomain]::CurrentDomain.GetAssemblies() | 
    Where-Object { $_.FullName -like "*SqlClient*" -or $_.FullName -like "*SqlServer*" } | 
    Select-Object @{N='Name';E={$_.GetName().Name}}, @{N='Version';E={$_.GetName().Version}}, Location

# Load dbatools
Import-Module dbatools -Force

# After loading dbatools
Write-Host "`n=== Assemblies AFTER dbatools ===" -ForegroundColor Yellow
[AppDomain]::CurrentDomain.GetAssemblies() | 
    Where-Object { $_.FullName -like "*SqlClient*" -or $_.FullName -like "*SqlServer*" } | 
    Select-Object @{N='Name';E={$_.GetName().Name}}, @{N='Version';E={$_.GetName().Version}}, Location

# Create connection string using the legacy (working) provider
$connString = New-DbaConnectionString -SqlInstance "SESTODS111.sweco.se\SESCCM02P" -ClientName "SwDbaTools" 

# Then connect using that connection string
Connect-DbaInstance -SqlInstance $connString 

# Set to use System.Data.SqlClient globally
Set-DbatoolsConfig -FullName sql.connection.legacy -Value $true -PassThru
Register-DbatoolsConfig -FullName sql.connection.legacy

# Then try connecting normally
Connect-DbaInstance -SqlInstance "SESTODS111.sweco.se\SESCCM02P" -SqlConnectionOnly

################################################
function Invoke-DbaQueryFixed {
    param(
        [Parameter(Mandatory)]
        [string]$SqlInstance,
        
        [Parameter(Mandatory)]
        [string]$Query,
        
        [string]$Database = "master"
    )
    
    # Use System.Data.SqlClient that works
    $connString = "Server=$SqlInstance;Database=$Database;Integrated Security=true"
    $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
    $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $conn)
    
    try {
        $conn.Open()
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
        $dataset = New-Object System.Data.DataSet
        $null = $adapter.Fill($dataset)
        
        # Return as objects like dbatools would
        $dataset.Tables[0] | Select-Object *
        
    } finally {
        if ($conn.State -eq 'Open') { $conn.Close() }
        $conn.Dispose()
    }
}

# Usage
Invoke-DbaQueryFixed -SqlInstance "SESTODS111.sweco.se\SESCCM02P" -Query "SELECT name FROM sys.databases"


##########################################
# Run this and paste output in the GitHub issue
[PSCustomObject]@{
    'Issue' = 'Connect-DbaInstance fails with untrusted domain error in PS7'
    'PowerShell Version' = $PSVersionTable.PSVersion.ToString()
    'PowerShell Edition' = $PSVersionTable.PSEdition
    'OS' = $PSVersionTable.OS
    'dbatools Version' = (Get-Module dbatools).Version.ToString()
    'dbatools.library Version' = (Get-Module dbatools.library).Version.ToString()
    'Microsoft.Data.SqlClient Version' = ([AppDomain]::CurrentDomain.GetAssemblies() | 
        Where-Object { $_.FullName -like "Microsoft.Data.SqlClient,*" }).GetName().Version.ToString()
    'System.Data.SqlClient Works' = 'YES - Kerberos auth successful'
    'Connect-DbaInstance Works PS5.1' = 'YES'
    'Connect-DbaInstance Works PS7.5' = 'NO - untrusted domain error'
    'Server Type' = 'Named instance with FQDN'
    'Auth Method' = 'Windows Integrated (Kerberos)'
    'Network' = 'Cross-domain/forest scenario'
} | Format-List | Out-String

# Also include
Write-Host "`nWorking connection test:"
@"
`$conn = New-Object System.Data.SqlClient.SqlConnection("Server=FQDN\Instance;Integrated Security=true")
`$conn.Open()  # Works perfectly
`$conn.Close()
"@

Write-Host "`nFailing dbatools test:"
@"
Connect-DbaInstance -SqlInstance "FQDN\Instance"
# Error: Login failed. The login is from an untrusted domain and cannot be used with Integrated authentication.
"@

Connect-DbaInstance -SqlInstance  "SESTODS111\SESCCM02P" -Debug -TrustServerCertificate

Set-DbatoolsConfig -FullName 'sql.connection.encrypt' -Value $true
Set-DbatoolsConfig -FullName 'sql.connection.encrypt' -Value $false
Connect-DbaInstance -SqlInstance "SESTODS111\SESCCM02P"

Connect-DbaInstance -SqlInstance "SESTODS111\SESCCM02P" -AppendConnectionString "Authentication=Active Directory Windows"

