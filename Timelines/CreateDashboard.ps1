    $Parameters = @{
        StartDateTime = '2026-04-15 00:00:00'
        EndDateTime = '2026-04-15 08:00:00'
        MinRuntime = '1'
        jobName = '%CMDB%'
        ServerInstances = 'SESTODS039\SWSQL16P'
      }
.\CreateAgentJobTimeLineDashboard.ps1 @Parameters -Verbose
