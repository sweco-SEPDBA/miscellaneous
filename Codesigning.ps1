<#
Prepare code signing

# Install the PS modules
Install-Module Microsoft.PowerShell.SecretManagement -Scope CurrentUser
Install-Module Microsoft.PowerShell.SecretStore -Scope CurrentUser

# Create the local vault
Register-SecretVault -Name SecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# Set a password for vault access (This is the users own password which will be used when the script is run to access the local vault)
Get-SecretStoreConfiguration

# Store the client secret in the vault:
Set-Secret -Name "SwecoIT-Codesign-SwecoCA" -Secret "[Secret]"


#>

param (
    [Parameter(Mandatory = $true,HelpMessage="Enter full filename of file to sign")]
    $File
)

$tenant = "b7872ef0-9a00-4c18-8a4a-c7d25c778a9e"

# Key Vault URL
$kvu = "https://swecoit-codesign-swecoca.vault.azure.net/"

# Key Vault ID (Really the APP ID)
$kvi = "bce892b6-1913-46fd-8ab7-615a958b61a7"

# Key Vault Certificate Name
$kvc = "SwecoIT-Codesign-SwecoCA"

# Client Secret
$kvs = Get-Secret -Name "SwecoIT-Codesign-SwecoCA" -AsPlainText

azuresigntool sign -kvu $kvu -kvc $kvc -kvi $kvi -kvs $kvs --azure-key-vault-tenant-id $tenant -tr http://timestamp.globalsign.com/tsa/advanced -td sha256 $File
