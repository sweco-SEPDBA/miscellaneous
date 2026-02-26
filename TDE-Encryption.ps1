[cmdletbinding()]
Param (
    [Parameter(mandatory)] [string]$SqlInstance = "sestods907\sesql18t",
    [Parameter(mandatory)] [string]$Database = "MyCryptoTest1",
    [Parameter(mandatory)] [string]$Path = "\\sweco.se\sw\IT\Backup\SQL\Encryption\"
)

#Get the passwords needed
$masterkeypassword = (Get-Credential -Message "justneedpassword" masterkey).Password
$ServiceMasterkeyBackupPassword = (Get-Credential -Message "justneedpassword" ServiceMasterKeyBackup).Password
$MasterkeyBackupPassword = (Get-Credential -Message "justneedpassword" MasterKeyBackup).Password
$certbackuppassword = (Get-Credential -Message "justneedpassword" certbackup).Password


$BackupPath = "Path$($SqlInstance.Replace('\','$'))"


$mastermatch = "$($SqlInstance.Replace('\', '\$'))-master"
$servicemastermatch = "$($SqlInstance.Replace('\', '\$'))-SMK"

# Create system master key
# Creates master key as well. Verify this!!!!!!!
New-DbaServiceMasterKey -SqlInstance $SqlInstance -SecurePassword $masterkeypassword 

# Backup service master key if backup doesn't exist
$servicemasterkeytest = Get-DbaFile -SqlInstance $sqlInstance -Path $BackupPath | Where-Object FileName -match $servicemastermatch 
if (-not $servicemasterkeytest) {
    Backup-DbaServiceMasterKey -SqlInstance $SqlInstance -SecurePassword $ServiceMasterkeyBackupPassword -Path $BackupPath
}

# Backup master key if backup doesn't exist
$dbmasterkeytest = Get-DbaFile -SqlInstance $sqlInstance -Path $BackupPath | Where-Object FileName -match $mastermatch 
if (-not $dbmasterkeytest) {
    Backup-DbaDbMasterKey -SqlInstance $SqlInstance -Database master -SecurePassword $MasterkeyBackupPassword -Path $BackupPath 
}

# Create certificate for db encryption
$params = @{
    SqlInstance             = $SqlInstance
    Database                = "master"
    SecurePassword          = $masterkeypassword
    Name                    = "$Database-Cert"
    Subject                 = "Certificate to handle encryption of $Database database"
}
New-DbaDbCertificate @params

#Verify existance
Get-DbaDbCertificate -SqlInstance $SqlInstance -Database master -Certificate "$Database-Cert"

# Backup certificate with private key file
$params = @{
    SqlInstance        = $SqlInstance
    Certificate        = "$Database-Cert"
    Database           = "master"
    Path               = $BackupPath
    EncryptionPassword = $certbackuppassword #PrivateKey
    DecryptionPassword = $masterkeypassword
}
Backup-DbaDbCertificate @params

#Encrypt the database
$params = @{
    SqlInstance = $SqlInstance
    Database = $Database
    Confirm = $false
}
Enable-DbaDbEncryption @params

