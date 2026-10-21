            
        [string]$FQDN = 'SEDCXDS010.sweco.se'
        [string]$Instance = 'SWSCOM02P'
        [string]$Aliases = $null
        [switch]$UseInstanceAsAlias = $false
        [switch]$DbHotel = $false
        [string]$AliasDomain = "sql.sweco.net"
        [switch]$RestartInstance = $false
        [switch]$EnableForceEncryption = $false

    
        #Region add certificate
        $server = $FQDN.split(".")[0]

        IF($UseInstanceAsAlias){
            $SubjectName = "$Instance.sql.sweco.se"
            $InstallationServer = $FQDN
            IF($DbHotel) {
                $DnsName = "$Instance.sql.sweco.se,$Instance.sql.sweco.net,$server,$FQDN,*.sql.sweco.se,*.sql.sweco.net"
            } else { if($Aliases) {
                    $DnsName = "$Instance.sql.sweco.se,$Instance.sql.sweco.net,$Aliases,$server,$FQDN"  
                } else {
                    $DnsName = "$Instance.sql.sweco.se,$Instance.sql.sweco.net,$server,$FQDN"  
                }      
            }
        } ELSE {
            $SubjectName = $FQDN
            $InstallationServer = $FQDN
            IF($DbHotel) {
                $DnsName = "$server,$FQDN,*.sql.sweco.se,*.sql.sweco.net"
            } else { if($Aliases) {
                    $DnsName = "$Aliases,$server,$FQDN"  
                } else {
                    $DnsName = "$server,$FQDN"  
                }      
            }
        }
        
       

        $InformationPreference = "Continue"

        $sSubjectName = $SubjectName.Trim().ToLower()
        $sTemplate = "SwecoWebServerV4"
        $Expiry = (Get-date).AddYears(2) | Get-Date -Format "ddMMyyyy"

        if (-not $DnsName) {
            $sDnsName = $sSubjectName
        }
        else {
            $sDnsName = $DnsName.Split(",")
        }

        # Create certificate request
        $oCertReq = Get-Certificate -Template $sTemplate -DnsName $sDnsName -SubjectName "CN=$($sSubjectName)" -CertStoreLocation "Cert:\LocalMachine\My" #-FriendlyName "$sSubjectName $Expiry"

        # Add Friendly Name to Certificate
        (Get-ChildItem -Path Cert:LocalMachine\MY | Where-Object {$_.Subject -eq "CN=$($sSubjectName)" -and $_.NotBefore.ToString("ddMMyyyy") -eq (Get-date).ToString("ddMMyyyy")}).FriendlyName = "$FQDN $Instance $Expiry"
        Start-Sleep -Seconds 2
        #EndRegion add certificate

        #Region use certificate

        if ($UseInstanceAsAlias) {
            $alias = "$instance.$AliasDomain"
        } else {
            $alias = $FQDN
        }
        if ($Instance -eq 'mssqlserver') {
            $SqlInstance = $FQDN
        } else {
            $SqlInstance = "$FQDN\$instance"
        }

    
        Get-ChildItem -Path Cert:LocalMachine\MY | Where-Object {$_.Subject -eq "CN=$($sSubjectName)" -and $_.NotBefore.ToString("ddMMyyyy") -eq (Get-date).ToString("ddMMyyyy")} | 
        Add-DbaComputerCertificate -ComputerName $FQDN -Confirm:$false | 
        Set-DbaNetworkCertificate -SqlInstance $SqlInstance

        if ($EnableForceEncryption) {
            Enable-DbaForceNetworkEncryption -SqlInstance $SqlInstance
        } else {
            Disable-DbaForceNetworkEncryption -SqlInstance $SqlInstance
        }
        
        if ($Instance -eq 'MSSQLSERVER') {
            $Name = 'MSSQLSERVER'
        } else {
            $Name = 'MSSQL$'+$Instance
        }
        if($RestartInstance){
            Invoke-Command -ComputerName "sestods061.sweco.se" -ScriptBlock {

                Restart-Service -Name $Using:Name -Force
            }
        } 


        #EndRegion use certificate

        #Remove the local cert from the cert store
        Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=$($sSubjectName)" } | Remove-Item


        Write-Host "Certificate created and installed on $SqlInstance this is what it looks like:"
        $Certinfo = Get-DbaNetworkCertificate -SqlInstance  $SqlInstance | ForEach-Object {
            [pscustomobject]@{
                ComputerName = $_.ComputerName
                InstanceName = $_.InstanceName
                SqlInstance = $_.SqlInstance
                ServiceAccount = $_.ServiceAccount
                ForceEncryption = $_.ForceEncryption
                FriendlyName = $_.FriendlyName
                DnsNameList = ($_.DnsNameList -join ', ')  
                Thumbprint = $_.Thumbprint
                Generated = $_.Generated
                Expires = $_.Expires
                IssuedTo = $_.IssuedTo
                IssuedBy = $_.IssuedBy
            }
        }
        Write-Host ($Certinfo | Format-List | Out-String) -ForegroundColor DarkGreen
        
