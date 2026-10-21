param(
    [string]$SwedenInstance = 'SESTODS094\SWSQL58P',
    [string]$NetherlandsInstance = 'NLAMSDS030\SWSQL52P',
    [string]$Database = 'RedgateMonitor'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command Invoke-DbaQuery -ErrorAction SilentlyContinue)) {
    throw 'Invoke-DbaQuery is required (dbatools).'
}

function Get-Hash {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hash = $sha.ComputeHash($bytes)
        return -join ($hash | ForEach-Object { $_.ToString('x2') })
    }
    finally {
        $sha.Dispose()
    }
}

$query = @"
SELECT
  cad.Name AS AlertName,
  cad.Description AS AlertDescription,
  cad.Direction,
  cm.Name AS MetricName,
  cm.Frequency,
  cm.UseRateOfChange,
  cm.Multiplier,
  cm.DatabaseSelectionMode,
  cm.TargetEntityType,
  CAST(cm.Tsql as nvarchar(max)) AS Tsql,
  ac._Enabled AS Enabled,
  ac._AlertNotification AS AlertNotification,
  ac._EmailAddress AS EmailAddress,
  ac._Comments AS Comments,
  ac._SlackEnabled AS SlackEnabled,
  ac._SnmpEnabled AS SnmpEnabled,
  ac._WebhookEnabled AS WebhookEnabled,
  ac._ScriptEnabled AS ScriptEnabled,
  ac._ServiceNowEnabled AS ServiceNowEnabled,
  ac._MsTeamsEnabled AS MsTeamsEnabled,
  CAST(ac._Configuration as nvarchar(max)) AS AlertConfigurationXml
FROM settings.CustomAlertDefinitions cad
JOIN settings.CustomMetrics cm ON cm.Id = cad.CustomMetricId
LEFT JOIN config.AlertConfiguration ac ON ac._AlertType = 40 AND ac._SubType = cad.Id
WHERE cm.Status = 2
ORDER BY cad.Name;
"@

$sweden = Invoke-DbaQuery -SqlInstance $SwedenInstance -Database $Database -Query $query
$netherlands = Invoke-DbaQuery -SqlInstance $NetherlandsInstance -Database $Database -Query $query

$swedenByName = @{}
foreach ($row in $sweden) {
    $swedenByName[$row.AlertName] = $row
}

$netherlandsByName = @{}
foreach ($row in $netherlands) {
    $netherlandsByName[$row.AlertName] = $row
}

$allNames = ($swedenByName.Keys + $netherlandsByName.Keys) | Sort-Object -Unique
$onlySweden = @()
$onlyNetherlands = @()
$different = @()
$identical = @()

foreach ($name in $allNames) {
    $sw = $swedenByName[$name]
    $nl = $netherlandsByName[$name]

    if ($null -eq $sw) {
        $onlyNetherlands += [pscustomobject]@{ AlertName = $name }
        continue
    }

    if ($null -eq $nl) {
        $onlySweden += [pscustomobject]@{ AlertName = $name }
        continue
    }

    $fields = @(
        'Direction',
        'MetricName',
        'Frequency',
        'UseRateOfChange',
        'Multiplier',
        'DatabaseSelectionMode',
        'TargetEntityType',
        'Enabled',
        'AlertNotification',
        'EmailAddress',
        'SlackEnabled',
        'SnmpEnabled',
        'WebhookEnabled',
        'ScriptEnabled',
        'ServiceNowEnabled',
        'MsTeamsEnabled'
    )

    $changed = @()
    foreach ($field in $fields) {
        if ([string]$sw.$field -ne [string]$nl.$field) {
            $changed += $field
        }
    }

    if ((Get-Hash -Text ([string]$sw.Tsql)) -ne (Get-Hash -Text ([string]$nl.Tsql))) {
        $changed += 'Tsql'
    }

    if ((Get-Hash -Text ([string]$sw.AlertConfigurationXml)) -ne (Get-Hash -Text ([string]$nl.AlertConfigurationXml))) {
        $changed += 'AlertConfigurationXml'
    }

    if ($changed.Count -gt 0) {
        $different += [pscustomobject]@{
            AlertName = $name
            DifferentSettings = $changed -join ', '
        }
    }
    else {
        $identical += [pscustomobject]@{ AlertName = $name }
    }
}

Write-Output 'SUMMARY'
Write-Output ('Sweden custom alerts: ' + $sweden.Count)
Write-Output ('Netherlands custom alerts: ' + $netherlands.Count)
Write-Output ('Only Sweden: ' + $onlySweden.Count)
Write-Output ('Only Netherlands: ' + $onlyNetherlands.Count)
Write-Output ('In both, same settings: ' + $identical.Count)
Write-Output ('In both, different settings: ' + $different.Count)
Write-Output ''

Write-Output 'ONLY IN SWEDEN'
$onlySweden | Sort-Object AlertName | Format-Table -AutoSize
Write-Output ''

Write-Output 'ONLY IN NETHERLANDS'
$onlyNetherlands | Sort-Object AlertName | Format-Table -AutoSize
Write-Output ''

Write-Output 'DIFFERENT SETTINGS (present in both)'
$different | Sort-Object AlertName | Format-Table -AutoSize

Write-Output ''
Write-Output 'DIFFERENCE DETAILS (side-by-side)'
foreach ($row in ($different | Sort-Object AlertName)) {
    $name = $row.AlertName
    $sw = $swedenByName[$name]
    $nl = $netherlandsByName[$name]

    Write-Output ('Alert: ' + $name)

    $compareFields = @(
        'Direction',
        'MetricName',
        'Frequency',
        'UseRateOfChange',
        'Multiplier',
        'DatabaseSelectionMode',
        'TargetEntityType',
        'Enabled',
        'AlertNotification',
        'EmailAddress',
        'SlackEnabled',
        'SnmpEnabled',
        'WebhookEnabled',
        'ScriptEnabled',
        'ServiceNowEnabled',
        'MsTeamsEnabled'
    )

    foreach ($field in $compareFields) {
        if ([string]$sw.$field -ne [string]$nl.$field) {
            Write-Output ('  ' + $field + ' | Sweden: ' + [string]$sw.$field + ' | Netherlands: ' + [string]$nl.$field)
        }
    }

    if ((Get-Hash -Text ([string]$sw.Tsql)) -ne (Get-Hash -Text ([string]$nl.Tsql))) {
        $swSnippet = (([string]$sw.Tsql) -replace '\s+', ' ').Trim()
        $nlSnippet = (([string]$nl.Tsql) -replace '\s+', ' ').Trim()
        if ($swSnippet.Length -gt 180) { $swSnippet = $swSnippet.Substring(0, 180) + '...' }
        if ($nlSnippet.Length -gt 180) { $nlSnippet = $nlSnippet.Substring(0, 180) + '...' }
        Write-Output ('  Tsql | Sweden: ' + $swSnippet)
        Write-Output ('  Tsql | Netherlands: ' + $nlSnippet)
    }

    if ((Get-Hash -Text ([string]$sw.AlertConfigurationXml)) -ne (Get-Hash -Text ([string]$nl.AlertConfigurationXml))) {
        $swCfg = (([string]$sw.AlertConfigurationXml) -replace '\s+', ' ').Trim()
        $nlCfg = (([string]$nl.AlertConfigurationXml) -replace '\s+', ' ').Trim()
        if ($swCfg.Length -gt 220) { $swCfg = $swCfg.Substring(0, 220) + '...' }
        if ($nlCfg.Length -gt 220) { $nlCfg = $nlCfg.Substring(0, 220) + '...' }
        Write-Output ('  AlertConfigurationXml | Sweden: ' + $swCfg)
        Write-Output ('  AlertConfigurationXml | Netherlands: ' + $nlCfg)
    }

    Write-Output ''
}

Write-Output 'SWEDEN-ONLY ALERTS (server-specific hint from SQL text)'
foreach ($row in ($onlySweden | Sort-Object AlertName)) {
    $name = $row.AlertName
    $sw = $swedenByName[$name]
    $tsql = [string]$sw.Tsql
    $hint = if ($tsql -match '(?i)sesto|sedcx|swsql|sweco\.se|nlams|nldcx|defr|gbld') {
        'Likely server/environment specific'
    }
    else {
        'No obvious hardcoded server hint'
    }

    Write-Output ('  ' + $name + ' => ' + $hint)
}
