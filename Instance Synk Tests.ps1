param (
    [DbaInstanceParameter]$Primary,
    [PSCredential]$PrimarySqlCredential,
    [DbaInstanceParameter[]]$Secondary,
    [PSCredential]$SecondarySqlCredential,
    [string]$AvailabilityGroup,
    [Alias("ExcludeType")]
    [ValidateSet('AgentCategory', 'AgentOperator', 'AgentAlert', 'AgentProxy', 'AgentSchedule', 'AgentJob', 'Credentials', 'CustomErrors', 'DatabaseMail', 'DatabaseOwner', 'LinkedServers', 'Logins', 'LoginPermissions', 'SpConfigure', 'SystemTriggers')]
    [string[]]$Exclude,
    [string[]]$Login,
    [string[]]$ExcludeLogin,
    [string[]]$Job,
    [string[]]$ExcludeJob,
    [switch]$DisableJobOnDestination,
    [parameter(ValueFromPipeline)]
    [Microsoft.SqlServer.Management.Smo.AvailabilityGroup[]]$InputObject,
    [switch]$Force,
    [switch]$EnableException
)
begin {
    if ($Force) { $ConfirmPreference = 'none' }

    $allcombos = @()
}
process {
    if (Test-Bound -Not Primary, InputObject) {
        Stop-Function -Message "You must supply either -Primary or an Input Object"
        return
    }

    if (-not $AvailabilityGroup -and -not $Secondary -and -not $InputObject) {
        Stop-Function -Message "You must specify a secondary or an availability group."
        return
    }

    if ($InputObject) {
        $server = $InputObject.Parent
    } else {
        try {
            $server = Connect-DbaInstance -SqlInstance $Primary -SqlCredential $PrimarySqlCredential
        } catch {
            Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $Primary
            return
        }
    }

    if ($AvailabilityGroup) {
        $InputObject += Get-DbaAvailabilityGroup -SqlInstance $server -AvailabilityGroup $AvailabilityGroup
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
}

end {
    if (Test-FunctionInterrupt) { return }

    # now that all combinations have been figured out, begin sync without duplicating work
    foreach ($ag in $allcombos) {
        $server = $ag.PrimaryServer
        $secondaries = $ag.SecondaryServer

        $stepCounter = 0
        $activity = "Syncing availability group $AvailabilityGroup"

        if (-not $secondaries) {
            Stop-Function -Message "No secondaries found."
            return
        }

        $primaryserver = $server.Name
        $secondaryservers = $secondaries.Name -join ", "

        if ($Exclude -notcontains "SpConfigure") {
            if ($PSCmdlet.ShouldProcess("Syncing SQL Server Configuration from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing SQL Server Configuration"
                Copy-DbaSpConfigure -Source $server -Destination $secondaries
            }
        }

        if ($Exclude -notcontains "Logins") {
            if ($PSCmdlet.ShouldProcess("Syncing logins from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing logins"
                Copy-DbaLogin -Source $server -Destination $secondaries -Login $Login -ExcludeLogin $ExcludeLogin -Force:$Force
            }
        }

        if ($Exclude -notcontains "DatabaseOwner") {
            if ($PSCmdlet.ShouldProcess("Updating database owners to match newly migrated logins from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Updating database owners to match newly migrated logins"
                foreach ($sec in $secondaries) {
                    $null = Update-SqlDbOwner -Source $server -Destination $sec
                }
            }
        }

        if ($Exclude -notcontains "CustomErrors") {
            if ($PSCmdlet.ShouldProcess("Syncing custom errors (user defined messages) from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing custom errors (user defined messages)"
                Copy-DbaCustomError -Source $server -Destination $secondaries -Force:$Force
            }
        }

        if ($Exclude -notcontains "Credentials") {
            if ($PSCmdlet.ShouldProcess("Syncing SQL credentials from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing SQL credentials"
                Copy-DbaCredential -Source $server -Destination $secondaries -Force:$Force
            }
        }

        if ($Exclude -notcontains "DatabaseMail") {
            if ($PSCmdlet.ShouldProcess("Syncing database mail from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing database mail"
                Copy-DbaDbMail -Source $server -Destination $secondaries -Force:$Force
            }
        }

        if ($Exclude -notcontains "LinkedServers") {
            if ($PSCmdlet.ShouldProcess("Syncing linked servers from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing linked servers"
                Copy-DbaLinkedServer -Source $server -Destination $secondaries -Force:$Force
            }
        }

        if ($Exclude -notcontains "SystemTriggers") {
            if ($PSCmdlet.ShouldProcess("Syncing System Triggers from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing System Triggers"
                Copy-DbaInstanceTrigger -Source $server -Destination $secondaries -Force:$Force
            }
        }

        if ($Exclude -notcontains "AgentCategory") {
            if ($PSCmdlet.ShouldProcess("Syncing Agent Categories from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing Agent Categories"
                Copy-DbaAgentJobCategory -Source $server -Destination $secondaries -Force:$force
                $secondaries.JobServer.JobCategories.Refresh()
                $secondaries.JobServer.OperatorCategories.Refresh()
                $secondaries.JobServer.AlertCategories.Refresh()
            }
        }

        if ($Exclude -notcontains "AgentOperator") {
            if ($PSCmdlet.ShouldProcess("Syncing Agent Operators from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing Agent Operators"
                Copy-DbaAgentOperator -Source $server -Destination $secondaries -Force:$force
                $secondaries.JobServer.Operators.Refresh()
            }
        }

        if ($Exclude -notcontains "AgentAlert") {
            if ($PSCmdlet.ShouldProcess("Syncing Agent Alerts from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing Agent Alerts"
                Copy-DbaAgentAlert -Source $server -Destination $secondaries -Force:$force -IncludeDefaults
                $secondaries.JobServer.Alerts.Refresh()
            }
        }

        if ($Exclude -notcontains "AgentProxy") {
            if ($PSCmdlet.ShouldProcess("Syncing Agent Proxy Accounts from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing Agent Proxy Accounts"
                Copy-DbaAgentProxy -Source $server -Destination $secondaries -Force:$force
                $secondaries.JobServer.ProxyAccounts.Refresh()
            }
        }

        if ($Exclude -notcontains "AgentSchedule") {
            if ($PSCmdlet.ShouldProcess("Syncing Agent Schedules from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing Agent Schedules"
                Copy-DbaAgentSchedule -Source $server -Destination $secondaries -Force:$force
                $secondaries.JobServer.SharedSchedules.Refresh()
                $secondaries.JobServer.Refresh()
                $secondaries.Refresh()
            }
        }

        if ($Exclude -notcontains "AgentJob") {
            if ($PSCmdlet.ShouldProcess("Syncing Agent Jobs from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing Agent Jobs"
                Copy-DbaAgentJob -Source $server -Destination $secondaries -Force:$force -Job $Job -ExcludeJob $ExcludeJob -DisableOnDestination:$DisableJobOnDestination
            }
        }

        if ($Exclude -notcontains "LoginPermissions") {
            if ($PSCmdlet.ShouldProcess("Syncing login permissions from $primaryserver to $secondaryservers")) {
                Write-ProgressHelper -Activity $activity -StepNumber ($stepCounter++) -Message "Syncing login permissions"
                Sync-DbaLoginPermission -Source $server -Destination $secondaries -Login $Login -ExcludeLogin $ExcludeLogin
            }
        }
    }
}