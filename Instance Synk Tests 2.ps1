[string]$Primary = "SESTODS950\SWERP04PC"
#[PSCredential]$PrimarySqlCredential,
[string[]]$Secondary = "SESTODS951\SWERP05PC", "SESTODS952\SWERP06PC"
#[PSCredential]$SecondarySqlCredential,
[string]$AvailabilityGroup = "SWERP02PA"
# [Alias("ExcludeType")]
#[ValidateSet('AgentCategory', 'AgentOperator', 'AgentAlert', 'AgentProxy', 'AgentSchedule', 'AgentJob', 'Credentials', 'CustomErrors', 'DatabaseMail', 'DatabaseOwner', 'LinkedServers', 'Logins', 'LoginPermissions', 'SpConfigure', 'SystemTriggers')]
#[string[]]$Exclude,
#[string[]]$Login,
[string[]]$ExcludeLogin = "SWECO\svc_sql_SWEROP02PA", "SWECO\SW-ROLE-SQLAdmin", "SWECO\svc_sql_AGSync"
#[string[]]$Job,
#[string[]]$ExcludeJob,
[switch]$DisableJobOnDestination = $false
#[parameter(ValueFromPipeline)]
#[Microsoft.SqlServer.Management.Smo.AvailabilityGroup[]]$InputObject,
[switch]$Force = $true
[switch]$EnableException = $true

if ($Force) { $ConfirmPreference = 'none' }
    $allcombos = @()
if (-Not $Primary) {
    Stop-Function -Message "You must supply either -Primary or an Input Object"
    return
}

if (-not $AvailabilityGroup -and -not $Secondary -and -not $InputObject) {
    Stop-Function -Message "You must specify a secondary or an availability group."
    return
}
try {
    $server = Connect-DbaInstance -SqlInstance $Primary 
} catch {
    Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $Primary
    return
}

if ($AvailabilityGroup) {
    $InputObject += Get-DbaAvailabilityGroup -SqlInstance $Primary -AvailabilityGroup $AvailabilityGroup
}

if ($InputObject) {
    $Secondary += (($InputObject.AvailabilityReplicas | Where-Object Name -ne $server.DomainInstanceName).Name | Select-Object -Unique)
}

if ($Secondary) {
    $Secondary = $Secondary | Sort-Object
    $secondaries = @()
    foreach ($computer in $Secondary) {
        try {
            $secondaries += Connect-DbaInstance -SqlInstance $computer -SqlCredential $SecondarySqlCredential
        } catch {
            Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $computer -Continue
        }
    }
}

$thiscombo = [pscustomobject]@{
    PrimaryServer   = $server
    SecondaryServer = $secondaries
}

# In the event that someone pipes in an availability group, this will keep the sync from running a bunch of times
$dupe = $false

foreach ($ag in $allcombos) {
    if ($ag.PrimaryServer.Name -eq $thiscombo.PrimaryServer.Name -and
        $ag.SecondaryServer.Name.ToString() -eq $thiscombo.SecondaryServer.Name.ToString()) {
        $dupe = $true
    }
}

if ($dupe -eq $false) {
    $allcombos += $thiscombo
}

$server = $null
$secondaries = $null
$server = $allcombos.PrimaryServer
$secondaries = $allcombos.SecondaryServer
$server
$secondaries


$stepCounter = 0
$activity = "Syncing availability group $AvailabilityGroup"

if (-not $secondaries) {
    Stop-Function -Message "No secondaries found."
    return
}

$primaryserver = $server.Name
$secondaryservers = $secondaries.Name -join ", "

#Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing SQL Server Configuration"
Copy-DbaSpConfigure -Source $server -Destination $secondaries

Copy-DbaLogin -Source $server -Destination $secondaries -Login $Login -ExcludeLogin $ExcludeLogin -Force:$Force

# foreach ($sec in $secondaries) {
#     $null = Update-SqlDbOwner -Source $server -Destination $sec
#     $null = set-DbaDbOwner -Source $server -Destination $sec
# }

Copy-DbaCustomError -Source $server -Destination $secondaries -Force:$Force

Copy-DbaCredential -Source $server -Destination $secondaries -Force:$Force

Copy-DbaDbMail -Source $server -Destination $secondaries -Force:$Force

Copy-DbaLinkedServer -Source $server -Destination $secondaries -Force:$Force

Copy-DbaInstanceTrigger -Source $server -Destination $secondaries -Force:$Force

#Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing Agent Categories"
Copy-DbaAgentJobCategory -Source $server -Destination $secondaries -Force:$force
$secondaries.JobServer.JobCategories.Refresh()
$secondaries.JobServer.OperatorCategories.Refresh()
$secondaries.JobServer.AlertCategories.Refresh()

Copy-DbaAgentOperator -Source $server -Destination $secondaries -Force:$force
#$secondaries.JobServer.Operators.Refresh()

Copy-DbaAgentAlert -Source $server -Destination $secondaries -Force:$force -IncludeDefaults
$secondaries.JobServer.Alerts.Refresh()

Copy-DbaAgentProxy -Source $server -Destination $secondaries -Force:$force
$secondaries.JobServer.ProxyAccounts.Refresh()

Copy-DbaAgentSchedule -Source $server -Destination $secondaries -Force:$force
$secondaries.JobServer.SharedSchedules.Refresh()
$secondaries.JobServer.Refresh()
$secondaries.Refresh()

Copy-DbaAgentJob -Source $server -Destination $secondaries -Force:$force -Job $Job -ExcludeJob $ExcludeJob -DisableOnDestination:$DisableJobOnDestination

Sync-DbaLoginPermission -Source $server -Destination $secondaries -Login $Login -ExcludeLogin $ExcludeLogin
