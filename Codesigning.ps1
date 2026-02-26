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
