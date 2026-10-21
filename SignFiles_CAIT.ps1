param (
    [Parameter(Mandatory = $true)]
    [string[]]$FilesToSign,

    [Parameter(Mandatory = $false)]
    [string]$KeyVaultUrl = "https://swecoit-codesign-swecoca.vault.azure.net/",

    [Parameter(Mandatory = $false)]
    [string]$CertificateName= "SwecoIT-Codesign-SwecoCA",

    [Parameter(Mandatory = $false)]
    [string]$TimestampUrl = "http://timestamp.digicert.com",

    [Parameter(Mandatory = $false)]
    [string]$AzureSignToolPath = "AzureSignTool"
)

# ── REQUIRED TENANT ──────────────────────────────────────────────────────────
$RequiredTenantId = "b7872ef0-9a00-4c18-8a4a-c7d25c778a9e"

# ── Check Az module is available ──────────────────────────────────────────────
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Error "Az PowerShell module not found. Install it with: Install-Module -Name Az.Accounts -Scope CurrentUser"
    exit 1
}

# ── Check Azure login & tenant ───────────────────────────────────────────────
Write-Host "Checking Azure login context..."

$context = Get-AzContext -ErrorAction SilentlyContinue

if ($context -and $context.Tenant.Id -eq $RequiredTenantId) {
    Write-Host "✅ Already logged in to correct tenant: $RequiredTenantId"
    Write-Host "Signed in as: $($context.Account)"
}
else {
    if ($context) {
        Write-Warning "Logged into wrong tenant ($($context.Tenant.Id)). Expected $RequiredTenantId."
    }
    else {
        Write-Host "No Azure login detected."
    }

    Write-Host "Resetting Azure context and logging into required tenant..."

    Disconnect-AzAccount -ErrorAction SilentlyContinue | Out-Null
    Clear-AzContext -Force -ErrorAction SilentlyContinue | Out-Null

    try {
        Connect-AzAccount -Tenant $RequiredTenantId -Subscription "da17b869-a6e8-4cc0-b8b5-85eb6ec822ee" -ErrorAction Stop
    }
    catch {
        Write-Error "Azure login failed: $_"
        exit 1
    }

    $context = Get-AzContext
    if (-not $context -or $context.Tenant.Id -ne $RequiredTenantId) {
        Write-Error "Azure login did not result in the required tenant. Expected $RequiredTenantId, got $($context.Tenant.Id)"
        exit 1
    }

    Write-Host "✅ Successfully logged in to tenant: $RequiredTenantId"
    Write-Host "Signed in as: $($context.Account)"
}

# ── Fetch access token for Key Vault ─────────────────────────────────────────
Write-Host "Fetching access token for Key Vault..."

try {
    $tokenObj = Get-AzAccessToken `
        -ResourceUrl "https://vault.azure.net" `
        -TenantId $RequiredTenantId

    # Handle both plain string (older Az) and SecureString (newer Az)
    if ($tokenObj.Token -is [System.Security.SecureString]) {
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenObj.Token)
        )
    }
    else {
        $token = $tokenObj.Token
    }
}
catch {
    Write-Error "Failed to retrieve access token: $_"
    exit 1
}

# ── Resolve AzureSignTool ─────────────────────────────────────────────────────
$toolPath = Get-Command $AzureSignToolPath -ErrorAction SilentlyContinue
if (-not $toolPath) {
    Write-Error "AzureSignTool not found. Install it with: dotnet tool install --global AzureSignTool"
    exit 1
}

# ── Resolve files (expand wildcards) ──────────────────────────────────────────
$resolvedFiles = @()
foreach ($pattern in $FilesToSign) {
    $matches = Resolve-Path $pattern -ErrorAction SilentlyContinue
    if ($matches) {
        $resolvedFiles += $matches.Path
    }
    else {
        Write-Warning "No files matched pattern: $pattern"
    }
}

if ($resolvedFiles.Count -eq 0) {
    Write-Error "No files found to sign."
    exit 1
}

Write-Host "Files to sign ($($resolvedFiles.Count)):"
$resolvedFiles | ForEach-Object { Write-Host "  $_" }

# ── Build AzureSignTool arguments ─────────────────────────────────────────────
$signArgs = @(
    "sign",
    "--azure-key-vault-url",          $KeyVaultUrl,
    "--azure-key-vault-certificate",  $CertificateName,
    "--azure-key-vault-accesstoken",  $token,
    "--timestamp-rfc3161",            $TimestampUrl,
    "--timestamp-digest",             "sha256",
    "--file-digest",                  "sha256",
    "--verbose"
) + $resolvedFiles

# ── Execute signing ───────────────────────────────────────────────────────────
Write-Host "`nStarting signing process..."
& $AzureSignToolPath @signArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Signing completed successfully." -ForegroundColor Green
}
else {
    Write-Error "❌ Signing failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
# SIG # Begin signature block
# MIIrxQYJKoZIhvcNAQcCoIIrtjCCK7ICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDIvtXaDFcVU8R4
# u7z7KWxULtbcPC3XWhWE43ub6+4uB6CCEZ8wggUFMIIC7aADAgECAhAw4ul2420w
# k0WkX3MN6aDGMA0GCSqGSIb3DQEBCwUAMBUxEzARBgNVBAMTClN3ZWNvIFJvb3Qw
# HhcNMTUwNzE1MDgzNjEyWhcNMzUwNzE1MDg0NjExWjAVMRMwEQYDVQQDEwpTd2Vj
# byBSb290MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzoEEXVgm4rHC
# kAgZ0Z0Q2nUU/EKft2ZqR5a65/Jv48yy6tqp+50NdNtT3BBsko4s9yUa7F0oUSlk
# e9nLx1S+P/9GD6c6ezNskvm2IL3TW+Hp2gxbWZBQN5dsSTtC6QcRSVo2xT8qqdPf
# sUJbr3psktyyNx9PVqGAWa1wqdKIgMZrijdYXaKMh25NG/gpoQJCpfwZwSwSenBl
# M7X/dA0bbW+ccNkwSu+Xwes53AeYjV+c4Rm6f1Lr2+L9ueOliN5RM7Cqt7s+Bw5j
# 9Z+SUfAXAdbtidsyEe0CUwfWssixQvx44kxgpjZEE8Uidh2tfy/R6zJp5UCDpwTl
# 6Vc8BqKoyy8VAfZtol8Kjxk5+9El6Vv29nob/gUq+/1bDBaTGnMnuTZOuP6G6pT1
# TNLYkmGHhwlBr2FliGeDZf+N+JP+hs0P6WvGT0JAoMlIF2zRl/5xlKTfUHvcqqek
# e0eQ6wsyWvo0hFyD/VqK+d5/faZAunVvhZAI3Ko16kCtu4WlO3c720i/IqjvLORC
# vYoeuMchb0qUIEJJ8BRHBDIFEuAwKLShRiNrhF4dQ/vp5bOXtwf4LDiPfEzS3kZb
# GjhSpIYE9r+GEAjEkLotJs3lqZdZ1YzPfKEgudBQWKwnwL+Xh1eO/bYwNLggu+uC
# Mzh9XSavU30WyKK78k9iD9dJ9SJFdSECAwEAAaNRME8wCwYDVR0PBAQDAgGGMA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFHvmIZY0Arx/j03pqqkVHnHkEEpgMBAG
# CSsGAQQBgjcVAQQDAgEAMA0GCSqGSIb3DQEBCwUAA4ICAQBd2t0IyJRc8SdlQXkL
# vddFVQ7rSujNGBK4CSHCA3D1rkrrY4W8t+f6T40DOJgOppW5OOMqlBY92yWryHE1
# GpDuOGPsZwCnqyfJqgz8GqOhC8RQyXz0m1uQzwyj1L6R6Ze/bLzTFBQrGx8M0v5O
# x9Tc1J6ca1/ObXNQehBqYVTJh6faFZQzazpphw8Yhjoynyl1dBdHF0kDPcE2nZ5i
# nxEy1ltpCD4izXiCpX33SV6YIEvlGaHjci5rQqVr1r0tsfo6tqvOHMzRSNELQYzd
# DnD7ycxzWJmgmsWbgPNl4L2KYJsVatmIZIkWJ3XV0cpGImKuSfE9os+VkeADprIy
# 3Ay7KGZaegBEPzUik+x2unt5W0waPVk0RRbPmXf1IGu3mw0EEQizAXF6oEAN6Qua
# KRHVgs6lx30WLdfhAtIFhRI3OK+YyxPnq+OEC3UEAE12WhtDjU5S5zbm8fuzQT0q
# zTHf/GD4uc0hZFekhh/F08I1mgL9ylhqstDwbWSdRjqHkawtJgswXvbgZmnRpRTd
# 9n/a9kMM/OhUsPgYI1qmLHZ7pRReARrXy3DgkGPnuJqx1EhytpiKPygU/OK8oHW6
# +tS3+tAooZEgxhQ3nPY/WKL+r1WrVl6LKvV3QrWMT16F+yw4vu0KeKJjMXrqcJjE
# bCLkT0wxjbuVLITiQTxLUei5/TCCBeUwggPNoAMCAQICE2QAAAAIywa8kgWnc6UA
# AAAAAAgwDQYJKoZIhvcNAQELBQAwFTETMBEGA1UEAxMKU3dlY28gUm9vdDAeFw0y
# NDA1MjQxMTU4MDVaFw0zNDA1MjQxMjA4MDVaMDkxCzAJBgNVBAYTAlNFMREwDwYD
# VQQKEwhTd2VjbyBBQjEXMBUGA1UEAxMOU3dlY28gU3ViQ0EgMDYwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQDa7C7QslY6/2eKsyX2Xe69LQ0qomJh0Mp4
# toOj+c1KSZsIJqUDYGjDDrAzZ+fqutRd90rYTZxDKFSN2Wr5k/Yt/qBNA24pNUqx
# 8KJMQ5OjFKt19fTC5Sl88t01YUE0VAhjozBt1qQi8rqvk0VdfyEuy4blkXi77r6d
# TqPxsCpbqeNBY4JR1msX5xM049cA3/3GctesEcEgMPS7gNlb9srQKTyFV9D8SMEK
# S9oTG1szGFA0HQAh1dE51S/3xgbr6Al514Og0mmoWx7BAZUp3YyK9zVrLqS2XBuj
# ZnIuNU0mC/k/gpmFTJyFrY2cQwW+yfcC3asT6Nm2LKbcmSVtbT6cdCGNplr6D0Wn
# zpHjcRXK1ByHXQWADdgCM1YYtx8ncNvlmc361PK9YOhnR41tQZZs7URtd3JPY/Bt
# NSJ+1vOYoFz0kjoXtMA1dtSaVc1wHNf6v7KDgcDXgK4KXf7lnlShPDbSRoGGOuLJ
# cgS1RkmjoMvPkmbY5UUDP3w31z7Ya6XZSKkxS7tOF/V/7aINraXqHvy0W4r/6kK1
# Hs+zQLg5FLUrlTCBqs8pEVkak7ESj5sS3YjUwB5nkvrdcFZTf/ferQNZtC1S2iQU
# NdEX9S6/2pMb88p5M5tJXmyXRJdW9CftBNCAROohUXSe04LW5SS2n4q64pNqOrNc
# +gQh72IKwQIDAQABo4IBCDCCAQQwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYE
# FD7UA4b0Va+E5P3wcsz7MHlEQGdBMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBB
# MAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHvmIZY0
# Arx/j03pqqkVHnHkEEpgMDUGA1UdHwQuMCwwKqAooCaGJGh0dHA6Ly9wa2kuc3dl
# Y28uc2UvU3dlY28lMjBSb290LmNybDBABggrBgEFBQcBAQQ0MDIwMAYIKwYBBQUH
# MAKGJGh0dHA6Ly9wa2kuc3dlY28uc2UvU3dlY28lMjBSb290LmNydDANBgkqhkiG
# 9w0BAQsFAAOCAgEAV7eK3kj8om9FLPFuZIpOPPN9JoxeohHlYrfGcI4i5/pVLAZG
# qhhpjGXEsLL1yywXK05vFAEU372X+/LwDHe+raaCprG8caiNYpaoWnjP59BDT5T7
# LnvqmeFTEi7/QsNO7aduDTXUc8IMyDNe/St0bbKh9P5TrUC57gqp+ZpdN0eRrFEX
# d30ed8cxE9Z/PXABmwmHzYZLngUPz4Ca14+RAH2wAQprUR76G63aAQIEWzvvmu6f
# IMdsPto2joOabEU8K+lZFUOBxJpwEK0vTwLjGcfSi5FNacacmfl0iqUu114SBCCp
# ywyaOikQGtncP6NGLvXJLgDykn4nZ36TbGXFaQRZb81QvYsp7yPxhVWnjG/1Dt5X
# jxzHmBPwH75DKglMxGigQem/LW4HfzldQHOUezCbIw5MuYMBGNP9RVydcStfAtxN
# 70wD8iIqKDWk+BfBHKVly8BPcqQrAhr/HhrWpUs/YFs0Oa4SgIEN6DJ03H/BDqHv
# wvEmWtcrgHLvYTWRy1WM7gaQ51Jo6gY1DlHiLNI+LrROgRwgH7+4ZO1/XI3LK/jc
# T1P32U1hKOeet5JT5ZxMqzINojxpzmuR+IRMHuY4ZGFWabagK63uxuJuQZXZL67Z
# l5yIoNL96gSAs4uZuIl4/gQ+kSncjdskwS189G55YI+gvyM8J4UDvzZRY04wggap
# MIIEkaADAgECAhNGAAAEECkxIxP6pCi7AAAAAAQQMA0GCSqGSIb3DQEBCwUAMDkx
# CzAJBgNVBAYTAlNFMREwDwYDVQQKEwhTd2VjbyBBQjEXMBUGA1UEAxMOU3dlY28g
# U3ViQ0EgMDYwHhcNMjUwNzE0MTMxNjM5WhcNMjcwNzE0MTMyNjM5WjAjMSEwHwYD
# VQQDExhTd2Vjb0lULUNvZGVzaWduLVN3ZWNvQ0EwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQC8t3FpnS9IsDWPaVdlP/mmoYGTYNsJCrWCv93dzmRCdn9c
# YE7hImB8lNkOCFf7lCjPH/IUHj0RAikTT4E5aoLl5210synAWjshFO98oCcdDJ1C
# DBGcNvhXnEzXzaUPplM0VDQVWMtndNHWC4UQ7enwqfP4c7O8UneJhNqFWbH2hULK
# ljx/FmyDpPe838gDIVnuvHv0eLdoHN/fujHwtxIuqol9vhglsA8fiGfdl6LdX+bn
# GtD+uz3XT/KgbcU1Oag2iE7wLFzzVQ+Oygd19/wz86KuXWxeCVh1gVNyl16Ho33U
# ifYbONwsEtGhogoGhqx7EKNHEDaCRzoB24K+NgEZAgMBAAGjggK+MIICujA8Bgkr
# BgEEAYI3FQcELzAtBiUrBgEEAYI3FQiH7fdBgtn+VYHhizm7gTGBtMV7gTXAoTmD
# 5qgkAgFkAgEHMBMGA1UdJQQMMAoGCCsGAQUFBwMDMAsGA1UdDwQEAwIHgDAbBgkr
# BgEEAYI3FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBRgJYe2G1A16WGEZBq4
# njcMMlowVjAfBgNVHSMEGDAWgBQ+1AOG9FWvhOT98HLM+zB5REBnQTCB/QYDVR0f
# BIH1MIHyMIHvoIHsoIHphoG5bGRhcDovLy9DTj1Td2VjbyUyMFN1YkNBJTIwMDYs
# Q049U0VTVE9DQTAwNixDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMs
# Q049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1zd2VjbyxEQz1zZT9jZXJ0
# aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9Y1JMRGlzdHJp
# YnV0aW9uUG9pbnSGK2h0dHA6Ly9wa2kuc3dlY28ubmV0L1N3ZWNvJTIwU3ViQ0El
# MjAwNi5jcmwwgfoGCCsGAQUFBwEBBIHtMIHqMIGuBggrBgEFBQcwAoaBoWxkYXA6
# Ly8vQ049U3dlY28lMjBTdWJDQSUyMDA2LENOPUFJQSxDTj1QdWJsaWMlMjBLZXkl
# MjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPXN3ZWNv
# LERDPXNlP2NBQ2VydGlmaWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0
# aW9uQXV0aG9yaXR5MDcGCCsGAQUFBzAChitodHRwOi8vcGtpLnN3ZWNvLm5ldC9T
# d2VjbyUyMFN1YkNBJTIwMDYuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQAS/0595IM+
# 0/Um47EGXU26Ar3FBOc4K3pyUgrSJU+siiAVpLc2AKFb0tmAL91+kyEKKK9ELioL
# beM3X7J1xEXnIrgvoW8I4A73TiVjPcduN0/uz2jc6r9WgIiJgsI8TKpOPuUCPpPF
# rHcG5SjGvuQM0ORE5PpV6uAeqO76dPG33Xo6yaxTDzYUuSDr4aLs2gxbCtSDIenl
# 0/CgCkb99S/a0KHwl9F4nSJReXXK4Exw7OV+uWEBSLzDJac3ltaTS76cnGVplNX6
# rTBB+ZqIq5f9RpUGgfTvpL9ti8zvRMmj3KwQp5I/biqJo49MBUoKfiuXIV6uR8ld
# ht/CIaSk0Z7qd8VcYXYR+Q2ne8PLwi4rKZeETkZ1PogfYnrQTLEXxiWKXtGZNwkI
# ch+5vRm3yTB/cX2f5Tkq9JlC12UNjqmcKPjkI84D/nzI3HL9aZsVMjQ2P2p/eitB
# 8lrvsijZf8iFAwh3CJToLuSUwljuvh27dkBgWvdykYd9K0F7Xwm9T40yooz3Aja0
# YqKtK9q8L7Gj4lGmB3ZMXU86vB4wtwrbnTsCqLZMfknJSOZMSLN3qKHY5V27FY+/
# O8DOJGZIRKz8vMxl/0CtD/jFaEXMJuGX9KGi2jhN9oGo7XwLfA7uowxRpRdxsHqu
# hGai/V9HhPIu53foyQKImPMr9OFrJ/6ceTGCGXwwghl4AgEBMFAwOTELMAkGA1UE
# BhMCU0UxETAPBgNVBAoTCFN3ZWNvIEFCMRcwFQYDVQQDEw5Td2VjbyBTdWJDQSAw
# NgITRgAABBApMSMT+qQouwAAAAAEEDANBglghkgBZQMEAgEFAKCBhDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBF73AI
# ZAwIElL4dhnHRPUQ7Conac5QUfk+uq7pmaxmOjANBgkqhkiG9w0BAQEFAASCAQAY
# CbZh7QfQ+fgeFPTgumuGtp9RYVXgzT46biTQnqs+67IDXY1q53kdXmLN7Vtf0Av7
# TDGaaS6VdqMbEUOv9DeBPU+O1bwESqUx8/WMEiffofIre4+4uX3Sqsd3d+CbfZNR
# f+Za9Kc1CMaqJ1hQ91ENsrAToM/iT7KZindfcqf0SNbbNYGMVifbHRXjTiLzDhGM
# +fqk4FvCPsxeBOTMJM9Bb66S2nhO9XmhSov6VLCGHPgRaNoA9CtIZc2QmTkmcV0j
# F44BhNQGHB30s+oCbWi3JzUtMoeLpOEeEGj3ZMGw5H0z789uEfUBsIGVRRJb8XET
# wq6st5qiXbrF3EDsS9ESoYIXdjCCF3IGCisGAQQBgjcDAwExghdiMIIXXgYJKoZI
# hvcNAQcCoIIXTzCCF0sCAQMxDzANBglghkgBZQMEAgEFADB3BgsqhkiG9w0BCRAB
# BKBoBGYwZAIBAQYJYIZIAYb9bAcBMDEwDQYJYIZIAWUDBAIBBQAEIJpW7WjKcf+j
# FyvGZSTNcmTXw2qmNK5fBTza8PxpAVAzAhAeSaUx25A5murn8LRrfJx4GA8yMDI2
# MDUyOTEwNTAxOFqgghM6MIIG7TCCBNWgAwIBAgIQCoDvGEuN8QWC0cR2p5V0aDAN
# BgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1MDYwNDAwMDAwMFoXDTM2MDkw
# MzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVz
# cG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANBG
# rC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMyqJnfFNZx+wvA69HFTBdwbHwB
# SOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4QKpVD7dvNZh6wW2R6kSu9RJt/
# 4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8SOhPUWlLnh00Cll8pjrUcCV3
# K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtUDVHRXdmncOOMA3CoB/iUSROU
# INDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCvpSduSwhwUmotuQhcg9tw2YD3
# w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1Hf2JNMVL4Q1OpbybpMe46Yce
# NA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORVbPR1VVnDuSeHVZlc4seAO+6d
# 2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWnqWU3dCCyFG1roSrgHjSHlq8x
# ymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyTlaCCfw7aSUROwnu7zER6EaJ+
# AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0yZIXe+giAwW00aHzrDchIc2b
# Qhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mnAgMBAAGjggGVMIIBkTAMBgNV
# HRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfzkXFjGVBDz2GM6DAfBgNVHSME
# GDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBp
# bmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIw
# CwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQBlKq3xHCcEua5gQezRCESe
# Y0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fNaNmFj6Eh8/YmRDfxT7C0k8FU
# FqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim8/9yJmZSe2F8AQ/UdKFOtj7Y
# MTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4daIqToXFE/JQ/EABgfZXLWU0zi
# TN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX8VBRKe1uNnzQVTeLni2nHkX/
# QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1d0IbX6Wq8/gVutDojBIFeRlq
# AcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQfVjnzrvwiCZ85EE8LUkqRhoS3
# Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ35XTxfUlQ+8Hggt8l2Yv7roan
# cJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3CrWqZzBt1R9xJgKf47CdxVRd/
# ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlKV9jEnstrniLvUxxVZE/rptb7
# IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk+EMF/cWuiC7POGT75qaL6vdC
# vHlshtjdNXOCIUjsarfNZzCCBrQwggScoAMCAQICEA3HrFcF/yGZLkBDIgw6SYYw
# DQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNl
# cnQgVHJ1c3RlZCBSb290IEc0MB4XDTI1MDUwNzAwMDAwMFoXDTM4MDExNDIzNTk1
# OVowaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYD
# VQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNI
# QTI1NiAyMDI1IENBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALR4
# MdMKmEFyvjxGwBysddujRmh0tFEXnU2tjQ2UtZmWgyxU7UNqEY81FzJsQqr5G7A6
# c+Gh/qm8Xi4aPCOo2N8S9SLrC6Kbltqn7SWCWgzbNfiR+2fkHUiljNOqnIVD/gG3
# SYDEAd4dg2dDGpeZGKe+42DFUF0mR/vtLa4+gKPsYfwEu7EEbkC9+0F2w4QJLVST
# EG8yAR2CQWIM1iI5PHg62IVwxKSpO0XaF9DPfNBKS7Zazch8NF5vp7eaZ2CVNxpq
# umzTCNSOxm+SAWSuIr21Qomb+zzQWKhxKTVVgtmUPAW35xUUFREmDrMxSNlr/NsJ
# yUXzdtFUUt4aS4CEeIY8y9IaaGBpPNXKFifinT7zL2gdFpBP9qh8SdLnEut/Gcal
# NeJQ55IuwnKCgs+nrpuQNfVmUB5KlCX3ZA4x5HHKS+rqBvKWxdCyQEEGcbLe1b8A
# w4wJkhU1JrPsFfxW1gaou30yZ46t4Y9F20HHfIY4/6vHespYMQmUiote8ladjS/n
# J0+k6MvqzfpzPDOy5y6gqztiT96Fv/9bH7mQyogxG9QEPHrPV6/7umw052AkyiLA
# 6tQbZl1KhBtTasySkuJDpsZGKdlsjg4u70EwgWbVRSX1Wd4+zoFpp4Ra+MlKM2ba
# oD6x0VR4RjSpWM8o5a6D8bpfm4CLKczsG7ZrIGNTAgMBAAGjggFdMIIBWTASBgNV
# HRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTvb1NK6eQGfHrK4pBW9i/USezLTjAf
# BgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMG
# A1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG
# /WwHATANBgkqhkiG9w0BAQsFAAOCAgEAF877FoAc/gc9EXZxML2+C8i1NKZ/zdCH
# xYgaMH9Pw5tcBnPw6O6FTGNpoV2V4wzSUGvI9NAzaoQk97frPBtIj+ZLzdp+yXdh
# OP4hCFATuNT+ReOPK0mCefSG+tXqGpYZ3essBS3q8nL2UwM+NMvEuBd/2vmdYxDC
# vwzJv2sRUoKEfJ+nN57mQfQXwcAEGCvRR2qKtntujB71WPYAgwPyWLKu6RnaID/B
# 0ba2H3LUiwDRAXx1Neq9ydOal95CHfmTnM4I+ZI2rVQfjXQA1WSjjf4J2a7jLzWG
# NqNX+DF0SQzHU0pTi4dBwp9nEC8EAqoxW6q17r0z0noDjs6+BFo+z7bKSBwZXTRN
# ivYuve3L2oiKNqetRHdqfMTCW/NmKLJ9M+MtucVGyOxiDf06VXxyKkOirv6o02Oo
# XN4bFzK0vlNMsvhlqgF2puE6FndlENSmE+9JGYxOGLS/D284NHNboDGcmWXfwXRy
# 4kbu4QFhOm0xJuF2EZAOk5eCkhSxZON3rGlHqhpB/8MluDezooIs8CVnrpHMiD2w
# L40mm53+/j7tFaxYKIqL0Q4ssd8xHZnIn/7GELH3IdvG2XlM9q7WP/UwgOkw/HQt
# yRN62JK4S1C8uw3PdBunvAZapsiI5YKdvlarEvf8EA+8hcpSM9LHJmyrxaFtoza2
# zNaQ9k+5t1wwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3
# DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3Vy
# ZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/
# MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv
# 9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYG
# BFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72a
# rKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFID
# yE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/o
# Wajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv
# 76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30
# fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQxggN8MIID
# eAIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIB
# BQCggdEwGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEP
# Fw0yNjA1MjkxMDUwMThaMCsGCyqGSIb3DQEJEAIMMRwwGjAYMBYEFN1iMKyGCi0w
# a9o4sWh5UjAH+0F+MC8GCSqGSIb3DQEJBDEiBCAYRiHnOwOPBKAQzOL4S7oZr2hw
# PhWA0zbhR7zKo5aPwjA3BgsqhkiG9w0BCRACLzEoMCYwJDAiBCBKoD+iLNdchMVc
# k4+CjmdrnK7Ksz/jbSaaozTxRhEKMzANBgkqhkiG9w0BAQEFAASCAgCZglazfnqi
# vs/lzC83Efz1JYFOpNzbymt/908R47Q04Cz1GLNqlqLSHonxm6PeWxhuixyVk2j9
# maYj9UyLXFTDX5c41dblLI9MNfjL22V/cg3DaiWcBsl4NpbyV+liBaTN5Ho2P8Zp
# d80HJ11ju0KaXsa0tdZfXSTz/4UQzVDPVFHUiJpBQqjF5k53HEhEd86wm38qlvAP
# WYSlawGQ6Gz70toQQvJ42AijK2XAH8dVBXXRau09o6yJ/POGaz5KKkUrH7XcxXDu
# Gk+qntfytPTN2xklNEfZS6DAUFjqdWwJLNksIy9qv62d/5wO+7l1s+9BglCVtVC1
# FHRTGtTn2dMbUWuH5lLWV6FLISsVWXtf7u3XZ1yI69E1k8zQt21VMDEQfmAp57zt
# zYh9q11zAnKVjcvrabIJZ99ahNFqt95voERdWfModGo62cmRhT95Gh6IIs8+fsK+
# mCrl30PZnYev106C3DJjX1hI/W5k9Bjg4ODqvC9muBC4hfJ6+l/w/pRS08gFMtAy
# suqdwcxvlgydsVenCNoO6cIPlpivGeTPh4F3H7XLN3db/swVBbbD21cBYmE7CAdK
# h4ocTktdEAhokzz25rhWK9JjEHG0nMZ4lBrZi4S9X6tcyGI+ojJoYZovMt+Pcvjb
# +oCP35fIuahHlWAJSQa3wT20PYnii3IEAg==
# SIG # End signature block
