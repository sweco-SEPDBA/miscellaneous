

$x = Get-Content .\CertsToIssu.json  | ConvertFrom-Json

foreach($cert in $x.CertsToIssue){
           
    $Params = @{
        "FQDN" = $cert.FQDN
        "Aliases" = $cert.Aliases
        "Instance" = $cert.Instance
        "UseInstanceAsAlias" = $cert.UseInstanceAsAlias
        "DbHotel" = $cert.DbHotel
    }
    New-SwServerCertificate @Params

    #Install certificate
    $Params1 = @{
        "FQDN" = $cert.FQDN
        "Instance" = $cert.Instance
        "UseInstanceAsAlias" = $cert.UseInstanceAsAlias
        "RestartInstance" = $cert.RestartInstance
        "EnableForceEncryption" = $cert.ForceEncryption 
    }
    Set-SwConnectEncryption @Params1 
}


