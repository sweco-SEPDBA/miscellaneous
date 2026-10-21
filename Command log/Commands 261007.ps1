Get-DnsServerZone -ComputerName SESTODC020

$cred = Get-Credential -UserName "SEPDBA_DA@swecopartner.com" -Message "Enter password for SEPDBA_DA@swecopartner.com"
Connect-DbaInstance -SqlInstance SEDCXDS016.swecopartner.com  -SqlCredential $cred

# Restore command to renew test for GLENN BEEK
Restore-DbaDatabase -SqlInstance NLSQL16T.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLNL\SqlBackup\NLAMSDS018$BESQL01P\ADMASTER' -MaintenanceSolutionBackup -IgnoreLogBackup
Restore-DbaDatabase -SqlInstance NLSQL16T.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLNL\SqlBackup\NLAMSDS018$BESQL01P\EXACTMASTER' -MaintenanceSolutionBackup -IgnoreLogBackup
Restore-DbaDatabase -SqlInstance NLSQL16T.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLNL\SqlBackup\NLAMSDS018$BESQL01P\PMOPRO' -MaintenanceSolutionBackup -IgnoreLogBackup

Restore-DbaDatabase -SqlInstance NLSQL16T.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLNL\SqlBackup\NLAMSDS022$NLSQL16P\Synergy' -MaintenanceSolutionBackup -IgnoreLogBackup
Restore-DbaDatabase -SqlInstance NLSQL16T.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLNL\SqlBackup\NLAMSDS022$NLSQL16P\200' -MaintenanceSolutionBackup -IgnoreLogBackup
Restore-DbaDatabase -SqlInstance NLSQL16T.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLNL\SqlBackup\NLAMSDS022$NLSQL16P\470' -MaintenanceSolutionBackup -IgnoreLogBackup
Restore-DbaDatabase -SqlInstance NLSQL16T.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLNL\SqlBackup\NLAMSDS022$NLSQL16P\474' -MaintenanceSolutionBackup -IgnoreLogBackup
Restore-DbaDatabase -SqlInstance NLSQL16T.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLNL\SqlBackup\NLAMSDS022$NLSQL16P\478' -MaintenanceSolutionBackup -IgnoreLogBackup
Restore-DbaDatabase -SqlInstance NLSQL16T.sql.sweco.net -Path '\\sweco.se\sw\IT\Backup\SQLNL\SqlBackup\NLAMSDS022$NLSQL16P\479' -MaintenanceSolutionBackup -IgnoreLogBackup


$cred = Get-Credential -UserName "SEPDBA_DA@swecopartner.com" -Message "Enter password for SEPDBA_DA@swecopartner.com"
Invoke-Command `
    -ComputerName SEDCXDS016.swecopartner.com `
    -Credential $cred `
    -Authentication Kerberos `
    -ScriptBlock {
        whoami
        hostname
        Connect-DbaInstance -SqlInstance SEDCXDS016
    }

########################################################################

[string]$FQDN = 'SEDCXDS016.swecopartner.com'
[string]$Instance = 'SESHAREPOINT01'
[string]$CMDB_SqlInstance = 'SWSQL16P.sql.sweco.se'
[string]$CMDB = 'CMDB'
$IPv4 = Resolve-DnsName -Name $FQDN  | Where-Object {$psitem.Type -eq 'A'} | Select-Object  -ExpandProperty IPAddress

            $FQDN           = $FQDN
            $InstanceName   = "$Instance"
            $ServiceAccount = "SWECOPARTNER.com\msvc_SEDCXDS016$"

            $Maxdop         = 1
            $IPv4           = $IPv4
            $AliasIp        = ""
            $Aliases        = ""
            [bool]$InDmz    = $true
            $Sla            = "Silver"
            $Collation      = "Latin1_General_CI_AS_KS_WS"
            $Edition        = "Standard"
            $Purpose        = "Dev - Sharepoint"
            $Country        = "Sweden"
            $CountryCode    = "SE"
            $Environment    = "Production"
            $Version        = "2022"
            $Operator       = "sepdba"
            $SNOWTicket     = ""
            [bool]$RegisterInRM   = $False
            $CU             = "SQL2022CU26"
            [bool]$UseInstanceAsAlias = $false 
            [bool]$SkipDiskSpd    = $true


    #Region Register the instance in CMDB

OsName                      : Microsoft Windows Server 2025 Standard
OsProductType               : Server
CsNumberOfLogicalProcessors : 8
CsNumberOfProcessors        : 1
CsTotalPhysicalMemory       : 34358743040
CsHypervisorPresent         : True
RunspaceId                  : 2c023f8e-af0e-4118-b8cb-9aac8cb59708

    $ServerInstance = [PSCustomObject]@{
        FQDN     = $FQDN
        InstanceName = $InstanceName
        InDmz    = $InDmz
        Country = $Country
        Environment = $Environment
        Sla = $Sla
        Purpose = $Purpose
        Edition = $Edition
        OsName = "Microsoft Windows Server 2025 Standard" -replace "Microsoft Windows ", ""
        NumberOfProcessors = 8
        NumberOfSockets = 1
        PhysicalMemory = 34358743040
        HypervisorPresent = $true
        IPv4 = $IPv4
        IsServer = $true
    }
    $ServerInstance | Write-DbaDbTableData -SqlInstance $CMDB_SqlInstance  -Database $CMDB -Table ImportServerInstance_Stage -Truncate

    $sql = @"

    declare @ServerId smallint
    DECLARE @ServerIdTable TABLE (  
        ServerId smallint NOT NULL);  
    
    
    ;with ServerInstance AS (
    SELECT 
        isi.FQDN,
        c.CountryCode,
        os.OperatingSystemId,
        isi.HypervisorPresent AS IsVirtual,
        CASE when isi.IsServer = 3 then 1 else 0 END AS IsServer,
        isi.InDmz,
        CAST(isi.PhysicalMemory AS BIGINT) / 1024 / 1024 / 1024 AS MemoryGB, 
        isi.NumberOfSockets AS Sockets,
        isi.NumberOfProcessors AS Cores,
        isi.IPv4
    FROM
        ImportServerInstance_Stage isi
        INNER JOIN Country c ON isi.Country = c.Country
        INNER JOIN Environment e ON isi.Environment = e.Environment
        INNER JOIN SLA s ON isi.Sla = s.Sla
        INNER JOIN InstancePurpose p ON isi.Purpose = p.Purpose
        INNER JOIN Edition ed ON isi.Edition = ed.Edition
        INNER JOIN OperatingSystem os ON isi.OsName = os.Os
    )
    MERGE INTO Server t
    USING (SELECT FQDN, CountryCode, OperatingSystemId, IsVirtual, IsServer, InDmz, MemoryGB, Sockets, Cores, IPv4
    FROM
        ServerInstance) s
    ON t.FQDN = s.FQDN
    WHEN MATCHED THEN 
        UPDATE
            SET FQDN = s.FQDN, CountryCode = s.CountryCode, OperatingSystemId = s.OperatingSystemId, IsVirtual = s.IsVirtual, IsServer = s.IsServer, InDmz = s.InDmz, 
            Memory = s.MemoryGB, Sockets = s.Sockets, Cores = s.Cores, IPv4 = s.IPv4
    WHEN NOT MATCHED THEN 
        INSERT (FQDN, CountryCode, OperatingSystemId, IsVirtual, IsServer, InDmz, Memory, Sockets, Cores, IPv4)
        VALUES (s.FQDN, s.CountryCode, s.OperatingSystemId, s.IsVirtual, s.IsServer, s.InDmz, s.MemoryGB, s.Sockets, s.Cores, s.IPv4)
        OUTPUT inserted.ServerId INTO @ServerIdTable 
        ;
    
    SELECT TOP 1 @ServerId = ServerId FROM @ServerIdTable 
    
    
    ;With ServerInstance AS (
    SELECT 
        @ServerId AS ServerId,
        isi.InstanceName,
        isi.FQDN + '\' + isi.InstanceName AS SqlInstance,
        e.EnvironmentId AS EnvironmentId,
        1 AS IsActive,
        p.InstancePurposeId,
        c.CountryCode,
        159 AS VersionId,
        ed.EditionId,
        s.SlaId
    FROM
        ImportServerInstance_Stage isi
        INNER JOIN Country c ON isi.Country = c.Country
        INNER JOIN Environment e ON isi.Environment = e.Environment
        INNER JOIN SLA s ON isi.Sla = s.Sla
        INNER JOIN InstancePurpose p ON isi.Purpose = p.Purpose
        INNER JOIN Edition ed ON isi.Edition = ed.Edition
        INNER JOIN OperatingSystem os ON isi.OsName = os.Os
    )
    MERGE INTO Instance t
    USING (SELECT ServerId, InstanceName, SqlInstance, EnvironmentId, IsActive, InstancePurposeId, CountryCode, VersionId, EditionId, SlaId
        FROM ServerInstance) AS s
        ON s.SqlInstance = t.SqlInstance
    WHEN MATCHED THEN UPDATE
        SET ServerId = s.ServerId, InstanceName = s.InstanceName, SqlInstance = s.SqlInstance, EnvironmentId = s.EnvironmentId, IsActive = s.IsActive, 
        InstancePurposeId = s.InstancePurposeId, CountryCode = s.CountryCode, VersionId = s.VersionId, EditionId = s.EditionId, SlaId = s.SlaId
    WHEN NOT MATCHED THEN
        INSERT (ServerId, InstanceName, SqlInstance, EnvironmentId, IsActive, InstancePurposeId, CountryCode, VersionId, EditionId, SlaId, CmsServerName)
        VALUES (s.ServerId, s.InstanceName, s.SqlInstance, s.EnvironmentId, s.IsActive, s.InstancePurposeId, s.CountryCode, s.VersionId, s.EditionId, s.SlaId, s.SqlInstance)
    ;
"@

    Invoke-DbaQuery -SqlInstance $CMDB_SqlInstance -Database $CMDB -Query $sql


























    #EndRegion Register the instance in CMDB

    #Region Add installation info to cmdb
    #TBD USE Add-SwInstanceChange instead
    if($Continue){
        $Message =  @"
<p><strong><span style="font-size: 26px; color: rgb(61, 142, 185);">Instance installed.</span></strong></p>
<p>SQL Version: <span style="color: rgb(61, 142, 185);">$Version</span></p>
<p>Patched to: <span style="color: rgb(61, 142, 185);">$CU</span></p>
"@
        $Sql = @"
INSERT INTO InstanceChanges (InstanceId, CreatedTime, ChangeDesc, ChangeNote, ChangedBy, ExternalReference)
SELECT
    InstanceId,
    GETDATE() AS CreatedTime,
    'Installed sql instance' AS ChangeDesc,
    '$Message'AS ChangeNote,
    '$Operator' AS ChangedBy,
    '$SNOWTicket' AS ExternalReference
FROM
    Instance
WHERE
    SqlInstance = '$FQDN\$InstanceName'
"@

        Invoke-DbaQuery -SqlInstance SESTODS039\SWSQL16P -Database CMDB -Query $Sql 
        "Installation registered in CMDB" | Out-File $LogGeneral -Append
    }
    #EndRegion Add installation info to cmdb

    #Region dokument installation in cmdb
    #TBD Create a commandlet for this
    if($Continue){
        $msgBoxInput = [System.Windows.Forms.MessageBox]::Show("Open cmdb web page to add information",'Verify Instance installation','YesNo','Warning')
        switch  ($msgBoxInput) {
            'Yes' {
                $sql = "SELECT InstanceId FROM Instance WHERE SqlInstance = '$FQDN\$InstanceName'"
                $InstanceId = Invoke-DbaQuery -SqlInstance SESTODS039\SWSQL16P -Database CMDB -Query $sql | select-object -ExpandProperty InstanceId
                Start-Process "https://cmdb-db.sweco.net/App/GetDetails?datasetid=2&key=$InstanceId&editable=0;"
            }
            'No' {
                Write-Host "Installation not dokumented." -ForegroundColor Red
            }
        }
    }
    #EndRegion dokument installation in cmdb

#########################################################################

Get-DbaDbBackupHistory -SqlInstance SESTODS089\SESQL50P -Database syslog_db -type Full | # get-member
select-object SqlInstance, Database, Type, TotalSize, DeviceType, Start, Duration, Path, UserName

Get-DbaDbBackupHistory -SqlInstance SESTODS072.sweco.se\SWSQL06PC -Database BI -type Differential | # get-member
select-object SqlInstance, Database, Type, TotalSize, DeviceType, Start, Duration, Path, UserName

Test-DbaLastBackup -SqlInstance sestods072.sweco.se\swsql06pc -Database BI -Destination SESTODS076.sweco.se\SESQL43T