
#Install-SwServerInstance -FQDN SESTODS061.sweco.se 

# 
#Set-SwConnectEncryption -FQDN SESTODS057.sweco.se -Instance SESQL12T -UseInstanceAsAlias

#SESQL12T.sql.sweco.se.pfx
get-command -module dbatools

dbhotel 
subject: sesql23t.sql.sweco.se 
dnsname: sesql23t.sql.sweco.se,sestods061.sweco.se,*.sql.sweco.se

not dbhotel
subject: sesql23t.sql.sweco.se 
dnsname: sesql23t.sql.sweco.se,p-test.sql.sweco.se,sestods061.sweco.se

$AssemblyPath = "C:\Program Files\WindowsPowerShell\Modules\DbaTools\1.1.143\bin\netcoreapp3.1\DbaTools.dll"

$AssemblyPath = "DbaTools.dll"

$byteValues = [System.IO.File]::ReadAllBytes($AssemblyPath)
[System.Reflection.Assembly]::Load($byteValues)


get-dbatoolsconfig -force

Get-DbatoolsPath "path.servers"

$custobj = new-object sqlcollaborative.Dbatools.Parameter.DbaInstanceParameter($SqlInstance)
$custobj.ComputerName
$custobj.InstanceName

[DbaInstanceParameter]$Inst = $SqlInstance

$inst 


Name:    sestoas225.sweco.se
Address:  172.18.81.13

SESTODS061 172.18.80.106
SESQL21T 172.18.80.233
SESQL22T 172.18.80.234
SESQL23T 172.18.81.13

#get-dbanetworkconfiguration -SqlInstance SESTODS061.sweco.se\SESQL21T | Select-Object -ExpandProperty TcpIpAddresses
$FQDN = "SESTODS061.sweco.se"
$SqlInstance = "$FQDN\SESQL21T"


$MaxUsedPort = (Find-DbaInstance -ComputerName $FQDN  | measure-object -property Port -Maximum).Maximum  

[string]$IPv4 = "172.18.80.106"
[string]$AliasIp = "172.18.80.233"

$PossiblePorts = 1433, 1435, 1436, 1437, 1438, 1439
$Ports = Find-DbaInstance -ComputerName $FQDN | select-object Port
[string]$NewPort = ($PossiblePorts | Where-Object {$psitem -notin $Ports.port} | Measure-Object -Minimum).Minimum

$Params = @{
    "SqlInstance" = $SqlInstance
    "DynamicPortForIPAll" = $true
    "Confirm" = $false
}
Set-DbaNetworkConfiguration @Params


$netConf = Get-DbaNetworkConfiguration -SqlInstance $SqlInstance
$netConf.TcpIpProperties.ListenAll = $false
$netConf.NamedPipesEnabled = $false
$netConf.SharedMemoryEnabled = $true
$netConf.TcpIpEnabled = $true
#Reorder list
$TcpIpAddresses = $netConf.TcpIpAddresses
$IndexIpv4 = [array]::indexof($TcpIpAddresses.IpAddress,$IPv4)
$netConf.TcpIpAddresses[$IndexIpv4].IpAddress = $netConf.TcpIpAddresses[0].IpAddress
$netConf.TcpIpAddresses[0].IpAddress = $IPv4
$IndexAliasIp = [array]::indexof($TcpIpAddresses.IpAddress,$AliasIp)
$netConf.TcpIpAddresses[$IndexAliasIp].IpAddress = $netConf.TcpIpAddresses[1].IpAddress
$netConf.TcpIpAddresses[1].IpAddress = $AliasIp
$netConf.TcpIpAddresses[0].TcpDynamicPorts = ''
$netConf.TcpIpAddresses[0].Enabled = $true
$netConf.TcpIpAddresses[0].TcpPort = $NewPort
$netConf.TcpIpAddresses[1].TcpDynamicPorts = ''
$netConf.TcpIpAddresses[1].Enabled = $true
$netConf.TcpIpAddresses[1].TcpPort = "1433"
$netConf | Set-DbaNetworkConfiguration -RestartService -Confirm:$false 
Get-DbaNetworkConfiguration -SqlInstance $SqlInstance








      
$PossiblePorts = 1433, 1435, 1436, 1437, 1438, 1439
$Ports = Find-DbaInstance -ComputerName $FQDN | select-object Port
[string]$NewPort = ($PossiblePorts | Where-Object {$psitem -notin $Ports.port} | Measure-Object -Minimum).Minimum

$Params = @{
    "SqlInstance" = $SqlInstance
    "DynamicPortForIPAll" = $true
    "Confirm" = $false
}
Set-DbaNetworkConfiguration @Params


$netConf = Get-DbaNetworkConfiguration -SqlInstance $SqlInstance
$netConf.TcpIpProperties.ListenAll = $false
$netConf.NamedPipesEnabled = $false
$netConf.SharedMemoryEnabled = $true
$netConf.TcpIpEnabled = $true
#Reorder list
$TcpIpAddresses = $netConf.TcpIpAddresses
$IndexIpv4 = [array]::indexof($TcpIpAddresses.IpAddress,$IPv4)
$netConf.TcpIpAddresses[$IndexIpv4].IpAddress = $netConf.TcpIpAddresses[0].IpAddress
$netConf.TcpIpAddresses[0].IpAddress = $IPv4
$IndexAliasIp = [array]::indexof($TcpIpAddresses.IpAddress,$AliasIp)
$netConf.TcpIpAddresses[$IndexAliasIp].IpAddress = $netConf.TcpIpAddresses[1].IpAddress
#Do remaining ip changes
$netConf.TcpIpAddresses[0].TcpDynamicPorts = ''
$netConf.TcpIpAddresses[0].Enabled = $true
$netConf.TcpIpAddresses[0].TcpPort = $NewPort
$netConf.TcpIpAddresses[1].TcpDynamicPorts = ''
$netConf.TcpIpAddresses[1].Enabled = $true
$netConf.TcpIpAddresses[1].TcpPort = "1433"
$netConf | Set-DbaNetworkConfiguration -Confirm:$false 
Get-DbaNetworkConfiguration -SqlInstance $SqlInstance














$FQDN = "SESTODS061.sweco.se"
$SqlInstance = "$FQDN\SESQL23T"
[string]$IPv4 = "172.18.80.106"
[string]$AliasIp = "172.18.81.13"
$netConf = Get-DbaNetworkConfiguration -SqlInstance $SqlInstance
$TcpIpAddresses = $netConf.TcpIpAddresses
$IndexIpv4 = [array]::indexof($TcpIpAddresses.IpAddress,$IPv4)
$IndexIpv4
$netConf.TcpIpAddresses[$IndexIpv4].IpAddress = $netConf.TcpIpAddresses[0].IpAddress
$netConf.TcpIpAddresses[0].IpAddress = $IPv4
$IndexAliasIp = [array]::indexof($TcpIpAddresses.IpAddress,$AliasIp)
$IndexAliasIp
$netConf.TcpIpAddresses[$IndexAliasIp].IpAddress = $netConf.TcpIpAddresses[1].IpAddress
$netConf.TcpIpAddresses[1].IpAddress = $AliasIp
$netConf.TcpIpAddresses



$NumberInList = $TcpIpAddresses | Measure-Object | select-object -ExpandProperty Count

for($i=0;$i)
$TcpIpAddresses.length 
[array]::indexof($TcpIpAddresses.IpAddress,'127.0.0.1')






$IPv4 = "172.18.80.106"
$AliasIp = "172.18.80.234"

$PossiblePorts = 1433, 1435, 1436, 1437, 1438, 1439
$Ports = Find-DbaInstance -ComputerName $FQDN | select-object Port
$NewPort = ($PossiblePorts | Where-Object {$psitem -notin $Ports.port} | Measure-Object -Minimum).Minimum

# $Params = @{
#     "SqlInstance" = $SqlInstance
#     "DynamicPortForIPAll" = $true
#     "Confirm" = $false
# }
# Set-DbaNetworkConfiguration @Params


$netConf = Get-DbaNetworkConfiguration -SqlInstance $SqlInstance
$netConf.TcpIpProperties.ListenAll = $false
$netConf.NamedPipesEnabled = $false
$netConf.SharedMemoryEnabled = $true
$netConf.TcpIpEnabled = $true
$netConf.TcpIpAddresses[0].IpAddress = $IPv4
$netConf.TcpIpAddresses[0].TcpDynamicPorts = $null
$netConf.TcpIpAddresses[0].Enabled = $true
$netConf.TcpIpAddresses[0].TcpPort = $NewPort
$netConf.TcpIpAddresses[1].IpAddress = $AliasIp
$netConf.TcpIpAddresses[1].TcpDynamicPorts = $null
$netConf.TcpIpAddresses[1].Enabled = $true
$netConf.TcpIpAddresses[1].TcpPort = "1433"
$netConf | Set-DbaNetworkConfiguration -RestartService -Confirm:$false -Verbose
Get-DbaNetworkConfiguration -SqlInstance $SqlInstance

$Params = @{
    "SqlInstance" = $SqlInstance
    "Restart" = $true
    "DynamicPortForIPAll" = $false
    "Confirm" = $false
}
Set-DbaNetworkConfiguration @Params









$Params = @{
    "SqlInstance" = $SqlInstance
    "DynamicPortForIPAll" = 0
    "Restart" = $true
    "Confirm" = $false
}
Set-DbaNetworkConfiguration @Params


$Params = @{
    "SqlInstance" = $SqlInstance
    "StaticPortForIpAll" = 1444
    #"Restart" = $true
    "Confirm" = $false
}
Set-DbaNetworkConfiguration @Params

Set-DbaTcpPort -SqlInstance $SqlInstance -Port 



$Params = @{
    "SqlInstance" = $SqlInstance
    "DynamicPortForIPAll" = 0
    "Restart" = $true
    "Confirm" = $false
}
Set-DbaNetworkConfiguration @Params



$MaxUsedPort = (Find-DbaInstance -ComputerName $FQDN  | measure-object -property Port -Maximum).Maximum  
$IPv4 = "172.18.80.106"
$AliasIp = "172.18.80.233"
$NewPort = $MaxUsedPort + 1
IF($NewPort -eq 1434) {
    $NewPort = 1435
}


$Params = @{
    "SqlInstance" = $SqlInstance
     "DynamicPortForIPAll" = $null
    "StaticPortForIpAll" = $null
    "IpAddress" = "$($IPv4):$NewPort", "$($AliasIP):1433" #Port och ip 
    "Restart" = $true
    "Confirm" = $false
}
Set-DbaNetworkConfiguration @Params

# $Params = @{
#     "SqlInstance" = $SqlInstance
#     "DynamicPortForIPAll" = $null
# }
# Set-DbaNetworkConfiguration @Params

# $Params = @{
#     "SqlInstance" = $SqlInstance
#     "StaticPortForIpAll" = $null
# }
# Set-DbaNetworkConfiguration @Params

$Params = @{
    "SqlInstance" = $SqlInstance
    "IpAddress" = "$($IPv4):$NewPort"#, "$($AliasIP):1433" #Port och ip 
    #"Restart" = $true
    "Confirm" = $false
}
Set-DbaNetworkConfiguration @Params

Set-DbaNetworkConfiguration -SqlInstance SESTODS061.sweco.se\SESQL21T -IpAddress 172.18.80.106:1433 -RestartService -Confirm:$false 

Get-DbaNetworkConfiguration -SqlInstance sestods016.Sweco.se | Select-Object -ExpandProperty Certificate 
Get-DbaNetworkConfiguration -SqlInstance SESTODS061.sweco.se\SESQL22T | Select-Object -ExpandProperty Certificate 
Get-DbaNetworkConfiguration -SqlInstance dksql01p.sql.sweco.se | Select-Object -ExpandProperty Certificate 



Get-DbaEndpoint -SqlInstance SESTODS061\SESQL22T


Test-DbaConnection -SqlInstance sestods061.sweco.se\sesql21t
Test-DbaConnection -SqlInstance dksql01p.sql.sweco.se


Connect-DbaInstance -SqlInstance sesql21t.sql.sweco.se -EncryptConnection


Get-DbaConnectedInstance | Disconnect-DbaInstance 

Disconnect-DbaInstance -


#Set dbatools to use encrypted connections as default
Set-DbatoolsConfig -FullName 'sql.connection.encrypt' -Value $true
Get-DbatoolsConfigValue -FullName 'sql.connection.encrypt' #Verify

# Loop through updated servers and test connection
$x = Get-Content '.\CertsToIssu.json'  | ConvertFrom-Json
$connected = foreach($cert in $x.CertsToIssue){
    Test-DbaConnection -SqlInstance "$($cert.FQDN)\$($cert.Instance)"
}

#Clean up existing connections
$connected | Format-Table SqlInstance, AuthType, AuthScheme, ConnectSuccess
Get-DbaConnectedInstance | Disconnect-DbaInstance 

#Set dbatools to not use encrypted connections as default
Set-DbatoolsConfig -FullName 'sql.connection.encrypt' -Value $false
Get-DbatoolsConfigValue -FullName 'sql.connection.encrypt' #Verify


get-dbaconnection 
Get-DbaNetworkConfiguration -SqlInstance dksql01p.sql.sweco.se | Select-Object -ExpandProperty Certificate 


Test-DbaConnection -SqlInstance coretest2.sql.sweco.se

$netConf = Get-DbaNetworkConfiguration -SqlInstance SESTODS061\SESQL21T 
$netConf | Select-Object -ExpandProperty TcpIpProperties
$netConf | Select-Object -ExpandProperty TcpIpAddresses
$netConf | Select-Object -ExpandProperty Certificate
$netConf = Get-DbaNetworkConfiguration -SqlInstance SESTODS061\SESQL22T 
$netConf | Select-Object -ExpandProperty TcpIpProperties
$netConf | Select-Object -ExpandProperty TcpIpAddresses
$netConf | Select-Object -ExpandProperty Certificate

Get-DbaUptime -SqlInstance SESTODS961.sweco.se\SWERP13T

$netConf = Get-DbaNetworkConfiguration -SqlInstance DEHANAS003.Sweco.se\BASYS
$TcpIpProperties = $netConf | Select-Object -ExpandProperty TcpIpProperties
$TcpIpAddresses = $netConf | Select-Object -ExpandProperty TcpIpAddresses
$Certificate = $netConf | Select-Object -ExpandProperty Certificate
write-host -ForegroundColor Magenta "************ TcpIp Properties *************************"
write-host -ForegroundColor Magenta ($TcpIpProperties | out-string)
write-host -ForegroundColor Magenta "************ TcpIp Addresses  *************************"
write-host -ForegroundColor Magenta ($TcpIpAddresses | out-string)
write-host -ForegroundColor Magenta "************ Certificate info *************************"
write-host -ForegroundColor Magenta ($Certificate | out-string)


$netConf = Get-DbaNetworkConfiguration -SqlInstance SESTODS037.sweco.se\SWSQL91PC 
$netConf | Select-Object -ExpandProperty TcpIpProperties
$netConf | Select-Object -ExpandProperty TcpIpAddresses
$netConf | Select-Object -ExpandProperty Certificate



$netConf = Get-DbaNetworkConfiguration -SqlInstance DEBREPS001.Sweco.se\SAFECOMEXPRESS
$Certificate = $netConf | Select-Object -ExpandProperty Certificate
write-host -ForegroundColor Magenta "************ Certificate info *************************"
write-host -ForegroundColor Magenta ($Certificate | out-string)
