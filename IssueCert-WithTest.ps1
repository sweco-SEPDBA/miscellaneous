
#$x = Get-Content .\CertsToIssue_230321_norestart.json  | ConvertFrom-Json
$x = Get-Content "Documents\cert test.json"  | ConvertFrom-Json
$x = Get-Content "Documents\certMaconomy.json"  | ConvertFrom-Json
$x = Get-Content "Documents\certSESTODS017.json"  | ConvertFrom-Json

# Check existing certificates
foreach($cert in $x.CertsToIssue){
    "$($cert.FQDN)\$($cert.Instance)"
    Get-DbaNetworkCertificate -SqlInstance "$($cert.FQDN)\$($cert.Instance)"
}

# Issue certificates
foreach($cert in $x.CertsToIssue){

    try
    {
        $Params = @{
            "FQDN" = $cert.FQDN
            "Aliases" = $cert.Aliases
            "Instance" = $cert.Instance
            "UseInstanceAsAlias" = $cert.UseInstanceAsAlias
            "DbHotel" = $cert.DbHotel
        }
        New-SwServerCertificate @Params -ErrorAction Continue -Force
    
   } 
   catch [System.Management.Automation.RuntimeException]
   {
        Write-Host "Error occured: $($Error[0].Exception)"
   }

   #Install certificate
    $Params1 = @{
        "FQDN" = $cert.FQDN
        "Instance" = $cert.Instance
        "UseInstanceAsAlias" = $cert.UseInstanceAsAlias
        "RestartInstance" = $cert.RestartInstance
        "EnableForceEncryption" = $cert.ForceEncryption 
        "AliasDomain" = $cert.AliasDomain
    }
    Set-SwConnectEncryption @Params1 
    
}


# foreach($cert in $x.CertsToIssue){
#     Restart-DbaService -ComputerName $cert.FQDN -InstanceName $cert.Instance
# }

#Set dbatools to use encrypted connections as default
Set-DbatoolsConfig -FullName 'sql.connection.encrypt' -Value $true
Set-DbatoolsConfig -FullName  'sql.connection.trustcert' -Value $false
Get-DbatoolsConfigValue -FullName 'sql.connection.encrypt' #Verify
Get-DbatoolsConfigValue -FullName 'sql.connection.trustcert' #Verify

# Loop through updated servers and test connection
#$x = Get-Content '.\CertsToIssue - 20230418.json'  | ConvertFrom-Json
$connected = foreach($cert in $x.CertsToIssue){
    Test-DbaConnection -SqlInstance "$($cert.FQDN)\$($cert.Instance)"
}
Test-DbaConnection -SqlInstance "$($x.certsToIssue[2].FQDN)\$($x.certsToIssue[2].Instance)"
#Clean up existing connections
$connected | Format-Table SqlInstance, AuthType, AuthScheme, ConnectSuccess
Get-DbaConnectedInstance | Disconnect-DbaInstance 

#Set dbatools to not use encrypted connections as default
Set-DbatoolsConfig -FullName 'sql.connection.encrypt' -Value $false
Set-DbatoolsConfig -FullName  'sql.connection.trustcert' -Value $true
Get-DbatoolsConfigValue -FullName 'sql.connection.trustcert' #Verify

Test-DbaConnection -SqlInstance "GBLDSAS004.sweco.se\NET2" 
Connect-DbaInstance -SqlInstance "SESTOAS572.sweco.se\SQLEXPRESS" -EncryptConnection
Get-DbaNetworkCertificate -SqlInstance plpozas003.sweco.se\sqlexpress
Test-DbaComputerCertificateExpiration -ComputerName sestods951
 
$SqlInstance = "SESTODS951.sweco.se\SWERP04PC"
Get-DbaUptime -SqlInstance $SqlInstance
$netConf = Get-DbaNetworkConfiguration -SqlInstance $SqlInstance 
$TcpIpProperties = $netConf | Select-Object -ExpandProperty TcpIpProperties
$TcpIpAddresses = $netConf | Select-Object -ExpandProperty TcpIpAddresses
$Certificate = $netConf | Select-Object -ExpandProperty Certificate
write-host -ForegroundColor Magenta "************ TcpIp Properties *************************"
write-host -ForegroundColor Magenta ($TcpIpProperties | out-string)
write-host -ForegroundColor Magenta "************ TcpIp Addresses  *************************"
write-host -ForegroundColor Magenta ($TcpIpAddresses | out-string)
write-host -ForegroundColor Magenta "************ Certificate info *************************"
write-host -ForegroundColor Magenta ($Certificate | out-string)

5B1B61D20DF82AE480CAF566F0E964FED1C16ABA
Remove-DbaNetworkCertificate -SqlInstance $SqlInstance 
Set-DbaNetworkCertificate -SqlInstance PLPOZAS003.sweco.se\SQLEXPRESS -Thumbprint 5B1B61D20DF82AE480CAF566F0E964FED1C16ABA


$Params = @{
    "FQDN" = "EETLLBS005.sweco.se"
    "Instance" = "EESQL32P"
    "UseInstanceAsAlias" = $false
    "DbHotel" = $false
}
New-SwServerCertificate @Params -ErrorAction Continue -Force


#Install certificate
$Params1 = @{
    "FQDN" = "EETLLBS005.sweco.se"
    "Instance" = "EESQL32P"
"UseInstanceAsAlias" = $false
"RestartInstance" = $true
"EnableForceEncryption" = $false 
"AliasDomain" = "sql.sweco.se"
}
Set-SwConnectEncryption @Params1 
