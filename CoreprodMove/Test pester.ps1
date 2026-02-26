$PesterConfigFile = "C:\Users\sepdba_da\Documents\Repos\Database-SwecoDbaTools\Internal\Tests\OpsValidationConfig.json"
$FQDN = "SESTODS075.sweco.se"
$PesterPath = "C:\Users\sepdba_da\Documents\Repos\Database-SwecoDbaTools\Internal\Tests\Check_prerequisites.Test.ps1"; 
$PesterParameters = @{Server = "$FQDN"; ConfigFile = $PesterConfigFile}
$Pestercontainer = New-PesterContainer -Path $PesterPath -Data $PesterParameters

$pesterConfig = [PesterConfiguration]@{
    Run = @{
        Exit = $false
        Container = $Pestercontainer
    }
    Output = @{
        Verbosity = 'Detailed'
    }
    Should = @{
        ErrorAction = 'Continue'
    }
}
invoke-pester -Configuration $pesterConfig

Get-WmiObject -ComputerName $FQDN -Class Win32_DiskPartition | Select-Object @{Name="Name";Expression={$_.Name}}, @{Name="SizeMB";Expression={$_.Size/1MB -as [int]}}, @{Name="BlockSize";Expression={$_.BlockSize}}, @{Name="Offset";Expression={$_.StartingOffset}}

    

$msgBoxInput = [System.Windows.Forms.MessageBox]::Show("Are all of the prerequisities ok?",'Verify check','YesNo','Warning')
switch  ($msgBoxInput) {
    'Yes' {
        Write-Host "Checks ok, continue with installation." -ForegroundColor Cyan
        #Write-Output "Set remote DAC on." | Out-File $LogGeneral -Append
        $Continue = $true
    }
    'No' {
        Write-Host "Checks not ok. Wizard stopped." -ForegroundColor Red
        #Write-Output "No changes done to remote DAC." | Out-File $LogGeneral -Append
        $Continue = $false
    }
}