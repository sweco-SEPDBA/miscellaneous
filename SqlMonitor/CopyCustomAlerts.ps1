
$SourceInstance = 'SESTODS094\SWSQL58P'
$SourceDatabase = 'RedgateMonitor'
$DestinationInstance = 'NLAMSDS030\SWSQL52P'
$DestinationDatabase = 'RedgateMonitor'

#Region Create Staging tables
$query = @"
CREATE TABLE [sweco].[CustomMetricsStaging](
	[Id] [bigint] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[Tsql] [nvarchar](max) NOT NULL,
	[Frequency] [bigint] NOT NULL,
	[SampleTime] [nvarchar](10) NULL,
	[UseRateOfChange] [bit] NOT NULL,
	[Multiplier] [float] NOT NULL,
	[Status] [tinyint] NOT NULL,
	[Databases] [xml] NOT NULL,
	[DatabaseSelectionMode] [tinyint] NOT NULL,
	[TargetEntityType] [tinyint] NOT NULL,
	[AlertDetailQuery] [nvarchar](max) NULL
) ON [PRIMARY]
"@
Invoke-DbaQuery -SqlInstance $DestinationInstance -Database $DestinationDatabase -Query $query

$query = @"
CREATE TABLE [sweco].[CustomAlertDefinitionsStaging](
	[Id] [bigint] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[CustomMetricId] [bigint] NOT NULL,
	[Direction] [int] NOT NULL
) ON [PRIMARY]
"@
Invoke-DbaQuery -SqlInstance $DestinationInstance -Database $DestinationDatabase -Query $query

$query = @"
CREATE TABLE [sweco].[AlertConfigurationStaging](
	[_AlertType] [bigint] NOT NULL,
	[_SubType] [bigint] NOT NULL,
	[_Configuration] [xml] NOT NULL,
	[_Enabled] [bit] NOT NULL,
	[_AlertNotification] [bigint] NOT NULL,
	[_EmailAddress] [nvarchar](max) NOT NULL,
	[_Comments] [nvarchar](max) NOT NULL,
	[_Version] [bigint] NOT NULL,
	[_SlackEnabled] [bit] NOT NULL,
	[_SnmpEnabled] [bit] NOT NULL,
	[_WebhookEnabled] [bit] NOT NULL,
	[_ScriptEnabled] [bit] NOT NULL,
	[_ServiceNowEnabled] [bit] NOT NULL,
	[_MsTeamsEnabled] [bit] NOT NULL,
	[_GenericCustomEmailText] [nvarchar](max) NOT NULL,
	[_LowSeverityCustomEmailText] [nvarchar](max) NOT NULL,
	[_MediumSeverityCustomEmailText] [nvarchar](max) NOT NULL,
	[_HighSeverityCustomEmailText] [nvarchar](max) NOT NULL
) ON [PRIMARY]
"@
Invoke-DbaQuery -SqlInstance $DestinationInstance -Database $DestinationDatabase -Query $query

#endregion

#Region create mapping tables
$query = @"

-- Create the mapping tables (if they doesn't exist)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sweco' AND TABLE_NAME = 'CustomMetricsMapping')
BEGIN
    CREATE TABLE sweco.CustomMetricsMapping (
        OldId BIGINT NOT NULL,
        NewId BIGINT NOT NULL
    );
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sweco' AND TABLE_NAME = 'CustomAlertDefinitionsMapping')
BEGIN
    CREATE TABLE sweco.CustomAlertDefinitionsMapping (
        OldId BIGINT NOT NULL,
        NewId BIGINT NOT NULL
    );
END;
"@
Invoke-DbaQuery -SqlInstance $DestinationInstance -Database $DestinationDatabase -Query $query

#endregion


#Region populate staging tables
# settings.CustomMetrics
$query = @"
SELECT 
    [Id], [Name], [Description], [Tsql], [Frequency], [SampleTime], [UseRateOfChange], [Multiplier], [Status], [Databases], [DatabaseSelectionMode], [TargetEntityType], [AlertDetailQuery]
FROM 
    settings.CustomMetrics cm
WHERE
    cm.status = 2
    AND cm.Id NOT IN (1, 2, 10, 30)
ORDER BY cm.Id;
"@
$cm = Invoke-DbaQuery -SqlInstance $SourceInstance -Database $SourceDatabase -Query $query

$cm | Write-DbaDbTableData -SqlInstance $DestinationInstance -Database $DestinationDatabase -Schema sweco -Table CustomMetricsStaging -Truncate -AutoCreateTable

# settings.CustomAlertDefinitions
$query = @"
SELECT cad.[Id], cad.[Name], cad.[Description], cad.[CustomMetricId], cad.[Direction]
  FROM 
    [settings].[CustomMetrics] cm
    INNER JOIN [settings].[CustomAlertDefinitions] cad ON cm.Id = cad.CustomMetricId
  where
    cm.[status] = 2
    AND cm.Id NOT IN (1, 2, 10, 30)
"@
$cad = Invoke-DbaQuery -SqlInstance $SourceInstance -Database $SourceDatabase -Query $query
$cad | Write-DbaDbTableData -SqlInstance $DestinationInstance -Database $DestinationDatabase -Schema sweco -Table CustomAlertDefinitionsStaging -Truncate -AutoCreateTable

# config.AlertConfiguration
$query = @"
SELECT 
    ac.[_AlertType], ac.[_SubType], ac.[_Configuration], ac.[_Enabled], ac.[_AlertNotification], ac.[_EmailAddress], ac.[_Comments], 
    ac.[_Version], ac.[_SlackEnabled], ac.[_SnmpEnabled], ac.[_WebhookEnabled], ac.[_ScriptEnabled], ac.[_ServiceNowEnabled], 
    ac.[_MsTeamsEnabled], ac.[_GenericCustomEmailText], ac.[_LowSeverityCustomEmailText], ac.[_MediumSeverityCustomEmailText], ac.[_HighSeverityCustomEmailText]
FROM 
    [settings].[CustomMetrics] cm
    INNER JOIN [settings].[CustomAlertDefinitions] cad ON cm.Id = cad.CustomMetricId
    INNER JOIN config.AlertConfiguration ac ON cad.Id = ac.[_SubType]
WHERE
    cm.[status] = 2
    AND cm.Id NOT IN (1, 2, 10, 30)
    AND ac._AlertType = 40
"@
$ac = Invoke-DbaQuery -SqlInstance $SourceInstance -Database $SourceDatabase -Query $query
$ac | Write-DbaDbTableData -SqlInstance $DestinationInstance -Database $DestinationDatabase -Schema sweco -Table AlertConfigurationStaging -Truncate -AutoCreateTable
#endregion

#Region Insert data and remap IDs

# Merge custom metrics
$query = @"
-- Merge data into settings.CustomMetrics and capture the mapping
DECLARE @OUTPUTTABLE1 TABLE (
    OldId BIGINT,
    [NewId] BIGINT
);
MERGE INTO settings.CustomMetrics AS Target
USING (
    SELECT 
        cms.[Id] AS OldId, 
        cmm.[NewId], -- Get the new Id if it exists, otherwise it will be NULL for new records
        cms.[Name], 
        cms.[Description], 
        cms.[Tsql], 
        cms.[Frequency], 
        cms.[SampleTime], 
        cms.[UseRateOfChange], 
        cms.[Multiplier], 
        cms.[Status], 
        cms.[Databases], 
        cms.[DatabaseSelectionMode], 
        cms.[TargetEntityType], 
        cms.[AlertDetailQuery]
    FROM 
        sweco.CustomMetricsStaging cms
        LEFT JOIN sweco.CustomMetricsMapping cmm ON cms.Id = cmm.OldId -- Join to get existing mappings
) AS Source
ON Target.Id = Source.[NewId] -- Match rows based on the Id
WHEN MATCHED 
THEN
    UPDATE SET
        [Name] = Source.[Name],
        [Description] = Source.[Description],
        [Tsql] = Source.[Tsql],
        [Frequency] = Source.[Frequency],
        [SampleTime] = Source.[SampleTime],
        [UseRateOfChange] = Source.[UseRateOfChange],
        [Multiplier] = Source.[Multiplier],
        [Status] = Source.[Status],
        [Databases] = Source.[Databases],
        [DatabaseSelectionMode] = Source.[DatabaseSelectionMode],
        [TargetEntityType] = Source.[TargetEntityType],
        [AlertDetailQuery] = Source.[AlertDetailQuery]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Name], [Description], [Tsql], [Frequency], [SampleTime], [UseRateOfChange], [Multiplier], [Status], [Databases], [DatabaseSelectionMode], [TargetEntityType], [AlertDetailQuery])
    VALUES (Source.[Name], Source.[Description], Source.[Tsql], Source.[Frequency], Source.[SampleTime], Source.[UseRateOfChange], Source.[Multiplier], Source.[Status], Source.[Databases], Source.[DatabaseSelectionMode], Source.[TargetEntityType], Source.[AlertDetailQuery])
    OUTPUT Source.OldId, INSERTED.Id INTO @OUTPUTTABLE1 (OldId, [NewId]);

MERGE INTO sweco.CustomMetricsMapping AS Target
USING (SELECT OldId, [NewId] FROM @OUTPUTTABLE1) AS source ON Target.OldId = Source.OldId
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (OldId, [NewId])
        VALUES (source.OldId, source.[NewId]);

"@
Invoke-DbaQuery -SqlInstance $DestinationInstance -Database $DestinationDatabase -Query $query

# Merge custom alert definitions, joining to the mapping table to remap CustomMetricId
$query = @"
DECLARE @OUTPUTTABLE2 TABLE (
    OldId BIGINT,
    [NewId] BIGINT
);
MERGE INTO settings.CustomAlertDefinitions AS Target
USING (
    SELECT 
        cad.[Id] AS OldId, 
        cadm.[NewId] AS [NewId], -- Get the new Id if it exists, otherwise it will be NULL for new records
        cmm.[NewId] AS [CustomMetricId], 
        cad.[Name], 
        cad.[Description], 
        cad.[Direction]
    FROM 
        [sweco].[CustomAlertDefinitionsStaging] cad
        INNER JOIN sweco.CustomMetricsMapping cmm ON cad.CustomMetricId = cmm.OldId
        LEFT JOIN sweco.CustomAlertDefinitionsMapping cadm ON cad.Id = cadm.OldId 
) AS Source
ON Target.Id = Source.[NewId] -- Match rows based on the Id
WHEN MATCHED 
THEN
    UPDATE SET
        [Name] = Source.[Name],
        [Description] = Source.[Description],
        [CustomMetricId] = Source.[CustomMetricId],
        [Direction] = Source.[Direction]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Name], [Description], [CustomMetricId], [Direction])
    VALUES (Source.[Name], Source.[Description], Source.[CustomMetricId], Source.[Direction])
    OUTPUT Source.OldId, INSERTED.Id INTO @OUTPUTTABLE2 (OldId, [NewId]);

MERGE INTO sweco.CustomAlertDefinitionsMapping AS Target
USING (SELECT OldId, [NewId] FROM @OUTPUTTABLE2) AS source ON Target.OldId = Source.OldId
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (OldId, [NewId])
        VALUES (source.OldId, source.[NewId]);
"@
Invoke-DbaQuery -SqlInstance $DestinationInstance -Database $DestinationDatabase -Query $query

# Merge alert configuration, joining to the mapping table to remap SubType (CustomAlertDefinitionId)
$query = @"
MERGE INTO config.AlertConfiguration AS Target
USING (
    SELECT 
        [_AlertType],
        cadm.[NewId] AS [_SubType],
        [_Configuration],
        [_Enabled],
        [_AlertNotification],
        [_EmailAddress],
        [_Comments],
        [_Version],
        [_SlackEnabled],
        [_SnmpEnabled],
        [_WebhookEnabled],
        [_ScriptEnabled],
        [_ServiceNowEnabled],
        [_MsTeamsEnabled],
        [_GenericCustomEmailText],
        [_LowSeverityCustomEmailText],
        [_MediumSeverityCustomEmailText],
        [_HighSeverityCustomEmailText]
    FROM 
        [sweco].[AlertConfigurationStaging] acs
    INNER JOIN sweco.CustomAlertDefinitionsMapping cadm 
        ON acs._SubType = cadm.OldId
) AS Source
ON Target._AlertType = Source._AlertType AND Target._SubType = Source._SubType -- Match rows based on _AlertType and _SubType
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        [_AlertType],
        [_SubType],
        [_Configuration],
        [_Enabled],
        [_AlertNotification],
        [_EmailAddress],
        [_Comments],
        [_Version],
        [_SlackEnabled],
        [_SnmpEnabled],
        [_WebhookEnabled],
        [_ScriptEnabled],
        [_ServiceNowEnabled],
        [_MsTeamsEnabled],
        [_GenericCustomEmailText],
        [_LowSeverityCustomEmailText],
        [_MediumSeverityCustomEmailText],
        [_HighSeverityCustomEmailText]
    )
    VALUES (
        Source._AlertType,
        Source._SubType,
        Source._Configuration,
        Source._Enabled,
        Source._AlertNotification,
        Source._EmailAddress,
        Source._Comments,
        Source._Version,
        Source._SlackEnabled,
        Source._SnmpEnabled,
        Source._WebhookEnabled,
        Source._ScriptEnabled,
        Source._ServiceNowEnabled,
        Source._MsTeamsEnabled,
        Source._GenericCustomEmailText,
        Source._LowSeverityCustomEmailText,
        Source._MediumSeverityCustomEmailText,
        Source._HighSeverityCustomEmailText
    );
"@
Invoke-DbaQuery -SqlInstance $DestinationInstance -Database $DestinationDatabase -Query $query


#endregion

#Region CustomMetricGroups 
# First time add date to custommetricsGroups
$query = @" 
INSERT INTO settings.CustomMetricGroups ([CustomMetricId], [GroupId])
SELECT cmm.[NewId], null
FROM
    sweco.CustomMetricsMapping cmm
"@
Invoke-DbaQuery -SqlInstance $DestinationInstance -Database $DestinationDatabase -Query $query


#endregion