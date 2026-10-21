
$query = @"

DECLARE @CRLF NVARCHAR(2) = CHAR(13) + CHAR(10)

SELECT
    -- @NewIDs declaration
      'DECLARE @NewIDs TABLE (OriginalMetricID BIGINT, NewMetricID BIGINT)' + @CRLF + @CRLF

    -- MERGE for CustomMetrics (includes original Id in source so OUTPUT can reference it)
    + 'MERGE INTO settings.CustomMetrics AS target' + @CRLF
    + 'USING (' + @CRLF
    + '    VALUES' + @CRLF
    + STUFF((
        SELECT ',' + @CRLF + '    ('
            + ISNULL(CAST(Id AS NVARCHAR(20)), 'NULL')                                                    + ', '
            + 'N''' + REPLACE(ISNULL(Name,            ''), '''', '''''')                        + ''', '
            + 'N''' + REPLACE(ISNULL(Description,     ''), '''', '''''')                        + ''', '
            + 'N''' + REPLACE(ISNULL(Tsql,            ''), '''', '''''')                        + ''', '
            + ISNULL(CAST(Frequency        AS NVARCHAR(20)), 'NULL')                             + ', '
            + ISNULL(CAST(UseRateOfChange  AS NVARCHAR(1)),  'NULL')                             + ', '
            + ISNULL(CAST(Multiplier       AS NVARCHAR(50)), 'NULL')                             + ', '
            + ISNULL(CAST(Status           AS NVARCHAR(3)),  'NULL')                             + ', '
            + CASE WHEN Databases IS NULL THEN 'NULL'
                   ELSE 'N''' + REPLACE(CAST(Databases AS NVARCHAR(MAX)), '''', '''''') + ''''
              END                                                                                 + ', '
            + ISNULL(CAST(DatabaseSelectionMode AS NVARCHAR(3)), 'NULL')                         + ', '
            + 'N''' + REPLACE(ISNULL(SampleTime, ''), '''', '''''')                             + ''', '
            + ISNULL(CAST(TargetEntityType AS NVARCHAR(3)), 'NULL')                              + ', '
            + CASE WHEN AlertDetailQuery IS NULL THEN 'NULL'
                   ELSE 'N''' + REPLACE(AlertDetailQuery, '''', '''''') + ''''
              END
            + ')'
        FROM settings.CustomMetrics
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 7, '    ') + @CRLF
    + ') AS source (OriginalMetricId, Name, Description, Tsql, Frequency, UseRateOfChange, Multiplier, Status, Databases, DatabaseSelectionMode, SampleTime, TargetEntityType, AlertDetailQuery)' + @CRLF
    + 'ON 1 = 0' + @CRLF
    + 'WHEN NOT MATCHED THEN' + @CRLF
    + '    INSERT (Name, Description, Tsql, Frequency, UseRateOfChange, Multiplier, Status, Databases, DatabaseSelectionMode, SampleTime, TargetEntityType, AlertDetailQuery)' + @CRLF
    + '    VALUES (source.Name, source.Description, source.Tsql, source.Frequency, source.UseRateOfChange, source.Multiplier, source.Status, source.Databases, source.DatabaseSelectionMode, source.SampleTime, source.TargetEntityType, source.AlertDetailQuery)' + @CRLF
    + 'OUTPUT source.OriginalMetricId, INSERTED.Id INTO @NewIDs (OriginalMetricID, NewMetricID);' + @CRLF + @CRLF

    -- INSERT for CustomAlertDefinitions, joining @NewIDs to remap IDs
    + 'INSERT INTO settings.CustomAlertDefinitions (Name, Description, CustomMetricId, Direction)' + @CRLF
    + 'SELECT ad.Name, ad.Description, n.NewMetricID, ad.Direction' + @CRLF
    + 'FROM (' + @CRLF
    + '    VALUES' + @CRLF
    + STUFF((
        SELECT ',' + @CRLF + '    ('
            + 'N''' + REPLACE(ISNULL(Name,        ''), '''', '''''') + ''', '
            + 'N''' + REPLACE(ISNULL(Description, ''), '''', '''''') + ''', '
            + ISNULL(CAST(CustomMetricId AS NVARCHAR(20)), 'NULL')    + ', '
            + ISNULL(CAST(Direction      AS NVARCHAR(10)), 'NULL')
            + ')'
        FROM settings.CustomAlertDefinitions
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 7, '    ') + @CRLF
    + ') AS ad (Name, Description, OldMetricId, Direction)' + @CRLF
    + 'INNER JOIN @NewIDs n ON ad.OldMetricId = n.OriginalMetricID;'
"@
$query


invoke-dbaquery -sqlinstance SESTODS094\SWSQL58P -Database RedgateMonitor -Query $query | Select-Object -ExpandProperty Column1
