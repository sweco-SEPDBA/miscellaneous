# SQL Server Firewall Rules - Standard Ports
# Segmented Network Configuration - Remote Server
# Run this script as Administrator

# --- Configuration ---
$remoteServer = "NOOSLDS006.sweco.se"        # Replace with your server name or IP
$remoteCredential = Get-Credential   # Will prompt for credentials

# Script block to run remotely
$firewallScriptBlock = {

    $rules = @(
        @{ Name = "SQL Server - Default Instance (TCP 1433)";       Protocol = "TCP"; Port = 1433; Description = "SQL Server default instance" }
        ,@{ Name = "SQL Server - Browser Service (UDP 1434)";        Protocol = "UDP"; Port = 1434; Description = "SQL Server Browser Service" }
        # ,@{ Name = "SQL Server - Analysis Services (TCP 2383)";      Protocol = "TCP"; Port = 2383; Description = "SQL Server Analysis Services" }
        # ,@{ Name = "SQL Server - Reporting Services HTTP (TCP 80)";  Protocol = "TCP"; Port = 80;   Description = "SQL Server Reporting Services HTTP" }
        # ,@{ Name = "SQL Server - Reporting Services HTTPS (TCP 443)";Protocol = "TCP"; Port = 443;  Description = "SQL Server Reporting Services HTTPS" }
    )

    foreach ($rule in $rules) {
        # Check if rule already exists
        $existing = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Host "Rule already exists, skipping: $($rule.Name)" -ForegroundColor Yellow
        } else {

            
            $Params = @{
                "Direction"         = "Inbound"
                "DisplayName"       = $rule.Name
                "Protocol"          = $rule.Protocol
                "LocalPort"         = $rule.Port
                "Action"            = "Allow"
                "Profile"           = "Any"
                "Description"       = $($rule.Description)
            }
            New-NetFirewallRule  @Params
            Write-Host "Rule added: $($rule.Name)" -ForegroundColor Green
        }
    }
}

# Execute the script block on the remote server
Invoke-Command `
    -ComputerName $remoteServer `
    -Credential $remoteCredential `
    -ScriptBlock $firewallScriptBlock

Write-Host "`nDone! Firewall rules have been configured on $remoteServer." -ForegroundColor Cyan

