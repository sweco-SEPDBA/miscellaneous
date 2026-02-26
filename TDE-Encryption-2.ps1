####################################################################
# Do it all
$masterkeypass = (Get-Credential justneedpassword).Password
$certbackuppass = (Get-Credential justneedpassword).Password
$params = @{
    SqlInstance             = "$SqlInstance"
    AllUserDatabases        = $true
    MasterKeySecurePassword = $masterkeypass
    BackupSecurePassword    = $certbackuppass
    BackupPath              = "C:\temp"
    EnableException         = $true
}
Start-DbaDbEncryption @params


####################################################################
# Step by step

$masterkeypass = (Get-Credential justneedpassword).Password
$certbackuppass = (Get-Credential justneedpassword).Password
$SqlInstance = "SESTODS065.sweco.se\SESQL19T"
$Database = "AdventureWorks2019"
$BackupPath = "\\sweco.se\sw\IT\Backup\SQL\SqlBackup"

# Get Servername and instance name from SqlInstance
$ServerName = $SqlInstance -replace "\..*\\.*",""
$ServerName = $ServerName-replace "\\.*",""
$InstanceName = $SqlInstance -replace ".*\\",""
$CertificateName = "$($Database)Cert"
$FullBackupPath = "$($BackupPath)\$($ServerName)`$$($InstanceName)"
$FullBackupPathCert = "$($FullBackupPath)\$($Database)\$($CertificateName).cer"

# service master key (This can be skipped)
# New-DbaServiceMasterKey -SqlInstance $SqlInstance -Password $masterkeypass 
# Backup-DbaServiceMasterKey -SqlInstance $SqlInstance -Path $FullBackupPath #Filename?
# Get-DbaServiceMasterKey -SqlInstance $SqlInstance

# master key (Creates the service master key as well. Verify this!!!!!!!)
New-DbaDbMasterKey -SqlInstance $SqlInstance -Database master -Password $masterkeypass
Backup-DbaDbMasterKey -SqlInstance $SqlInstance -Database master -Path $FullBackupPath #Filename?
Get-DbaDbMasterKey -SqlInstance $SqlInstance -Database master

# certificate
New-DbaDbCertificate -SqlInstance $SqlInstance -Database master -Name $CertificateName -Subject "Encrypt certificate for $($Database)"
Backup-DbaDbCertificate -SqlInstance $SqlInstance -Database master -Certificate $CertificateName -Path $FullBackupPath -EncryptionPassword $certbackuppass 
Get-DbaDbCertificate -SqlInstance $SqlInstance -Database master -Certificate $CertificateName | select-object -ExpandProperty Thumbprint

# enable encryption on database
Enable-DbaDbEncryption -SqlInstance $SqlInstance -Database $Database -EncryptorName $CertificateName
Get-DbaDbEncryption -SqlInstance $SqlInstance -Database $Database
Get-DbaDbEncryptionKey -SqlInstance $SqlInstance -Database $Database



# Move database to another server

New-DbaDbMasterKey -SqlInstance $SqlInstance -Database master -Password $masterkeypass
Backup-DbaDbMasterKey -SqlInstance $SqlInstance -Database master -Path $FullBackupPath #Filename?
Get-DbaDbMasterKey -SqlInstance $SqlInstance -Database master

Restore-DbaDbCertificate -SqlInstance   SESTODS061.sweco.se\SESQL23T -Path "\\sweco.se\sw\IT\Backup\SQL\SqlBackup\SESTODS065`$SESQL19T\SESTODS065.sweco.se`$SESQL19T-master-AdventureWorks2019Cert.cer" -Password $certbackuppass -Database master
Copy-DbaDatabase -Source $SqlInstance -Destination SESTODS061.sweco.se\SESQL23T -Database $Database -BackupRestore -UseLastBackup

