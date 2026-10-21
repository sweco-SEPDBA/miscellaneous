
        [DbaInstanceParameter]$Primary,
        [PSCredential]$PrimarySqlCredential
        [DbaInstanceParameter[]]$Secondary
        [PSCredential]$SecondarySqlCredential
        [string]$AvailabilityGroup = 'SWERP02PA'
        [string]$AvailabilityGroupListener = 'SWERP02PL.sweco.se'
        [string[]]$ExcludeSecondary = 'SESTODS952\SWERP06PC', 'SEDCXDS011\SWERP04PC'
        [Alias("IncludeType")]
        [ValidateSet('AgentOperator', 'AgentAlert', 'AgentProxy', 'AgentJob', 'Credential', 'CustomError', 'DatabaseMail', 'DatabaseOwner', 'LinkedServers', 'Login', 'LoginPermission', 'SpConfigure', 'SystemTrigger')]
        [string[]]$Include
        [Alias("ExcludeType")]
        [ValidateSet('AgentOperator', 'AgentAlert', 'AgentProxy', 'AgentJob', 'Credential', 'CustomError', 'DatabaseMail', 'DatabaseOwner', 'LinkedServers', 'Login', 'LoginPermission', 'SpConfigure', 'SystemTrigger')]
        [string[]]$Exclude
        [string[]]$Login
        [string[]]$ExcludeLogin
        [string[]]$Job
        [string[]]$ExcludeJob
        [switch]$DisableJobOnDestination
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityGroup[]]$InputObject
        [switch]$Force
        [switch]$EnableException

        if ($Force) { $ConfirmPreference = 'none' }

        $inputobject = @()

        $allcombos = @()
        if (-Not ($Primary -or $InputObject -or $AvailabilityGroupListener)) {
            #Stop-Function -Message "You must supply either -Primary or an Input Object"
            write-host "You must supply either -Primary or -AvailabilityGroupListener or an Input Object"
            return
        }

        if (-not $AvailabilityGroup -and -not $Secondary -and -not $InputObject -and -not $AvailabilityGroupListener) {
            #Stop-Function -Message "You must specify a secondary or an availability group."
            write-host "You must specify a secondary or an availability group or an availabilityGroupListener."
            return
        }

        if ($InputObject) {
            $server = $InputObject.Parent
        } else {
            try {
                if ($AvailabilityGroupListener) {
                    $Primary = $AvailabilityGroupListener
                }
                $server = Connect-DbaInstance -SqlInstance $Primary -SqlCredential $PrimarySqlCredential
            } catch {
                #Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $Primary
                write-host "Failure with error: $_"
                return
            }
        }

        $server | format-list *
        $inputobject | format-list *
        if ($AvailabilityGroup -or $AvailabilityGroupListener) {
            write-host "Get-DbaAvailabilityGroup -SqlInstance $server -AvailabilityGroup $AvailabilityGroup"
            $InputObject += Get-DbaAvailabilityGroup -SqlInstance $server -AvailabilityGroup $AvailabilityGroup 
        }
        $secondary = @()
        if ($InputObject) {
            $InputObject  | format-table | out-string | Write-Host
            $Secondary += (($InputObject.AvailabilityReplicas | Where-Object {$_.Name -ne $server.DomainInstanceName -and $_.Name -notin $ExcludeSecondary}).Name  | Select-Object -Unique)
        }

        if ($Secondary) {
            $Secondary = $Secondary | Sort-Object
            $secondaries = @()
            foreach ($computer in $Secondary) {
                try {
                    $secondaries += Connect-DbaInstance -SqlInstance $computer -SqlCredential $SecondarySqlCredential
                } catch {
                    #Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $computer -Continue
                }
            }
        }

        $thiscombo = [PSCustomObject]@{
            PrimaryServer   = $server
            SecondaryServer = $secondaries
        }
        $thiscombo | format-table | out-string | Write-Host
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
