-- Run this on the SOURCE database to generate an insert script for the TARGET database.
-- Copy the output from the Messages tab and run it on the TARGET database.
-- Make sure not to copy the completion time of the script! 

SET NOCOUNT ON;

DECLARE @Script NVARCHAR(MAX) = N'';
DECLARE @MetricValues NVARCHAR(MAX) = N'';
DECLARE @AlertValues NVARCHAR(MAX) = N'';
DECLARE @CRLF NVARCHAR(2) = CHAR(13) + CHAR(10);

-- Build the VALUES rows for @SourceMetrics
SELECT @MetricValues = @MetricValues +
    CASE WHEN @MetricValues <> N'' THEN N',' + @CRLF ELSE N'' END +
    N'    (' +
        CAST(cm.Id AS NVARCHAR(20)) + N', ' +
        N'N''' + REPLACE(cm.Name, '''', '''''') + N''', ' +
        N'N''' + REPLACE(ISNULL(cm.Description, N''), '''', '''''') + N''', ' +
        N'N''' + REPLACE(cm.Tsql, '''', '''''') + N''', ' +
        CAST(cm.Frequency AS NVARCHAR(20)) + N', ' +
        CAST(cm.UseRateOfChange AS NVARCHAR(1)) + N', ' +
        CAST(cm.Multiplier AS NVARCHAR(50)) + N', ' +
        CAST(cm.Status AS NVARCHAR(5)) + N', ' +
        N'N''' + REPLACE(CAST(cm.Databases AS NVARCHAR(MAX)), '''', '''''') + N''', ' +
        CAST(cm.DatabaseSelectionMode AS NVARCHAR(5)) + N', ' +
        N'N''' + REPLACE(ISNULL(cm.SampleTime, N''), '''', '''''') + N''', ' +
        CAST(cm.TargetEntityType AS NVARCHAR(5)) + N', ' +
        CASE WHEN cm.AlertDetailQuery IS NULL THEN N'NULL'
             ELSE N'N''' + REPLACE(cm.AlertDetailQuery, '''', '''''') + N'''' END +
    N')'
FROM settings.CustomMetrics cm
ORDER BY cm.Id;

-- Build the VALUES rows for CustomAlertDefinitions
SELECT @AlertValues = @AlertValues +
    CASE WHEN @AlertValues <> N'' THEN N',' + @CRLF ELSE N'' END +
    N'    (' +
        N'N''' + REPLACE(cad.Name, '''', '''''') + N''', ' +
        N'N''' + REPLACE(ISNULL(cad.Description, N''), '''', '''''') + N''', ' +
        CAST(cad.CustomMetricId AS NVARCHAR(20)) + N', ' +
        CAST(cad.Direction AS NVARCHAR(10)) +
    N')'
FROM settings.CustomAlertDefinitions cad
ORDER BY cad.Id;

-- Assemble the full script
SET @Script =
N'-- Generated insert script - run this on the TARGET database' + @CRLF + 
N'-- Make sure to restart the Redgate Monitor base monitor service after the insert' + @CRLF + @CRLF +
N'DECLARE @NewIDs TABLE (OriginalMetricID BIGINT, NewMetricID BIGINT);' + @CRLF +
N'DECLARE @SourceMetrics TABLE (' + @CRLF +
N'    OriginalMetricId BIGINT,' + @CRLF +
N'    Name NVARCHAR(255),' + @CRLF +
N'    Description NVARCHAR(MAX),' + @CRLF +
N'    Tsql NVARCHAR(MAX),' + @CRLF +
N'    Frequency BIGINT,' + @CRLF +
N'    UseRateOfChange BIT,' + @CRLF +
N'    Multiplier FLOAT,' + @CRLF +
N'    Status TINYINT,' + @CRLF +
N'    Databases NVARCHAR(MAX),' + @CRLF +
N'    DatabaseSelectionMode TINYINT,' + @CRLF +
N'    SampleTime NVARCHAR(10),' + @CRLF +
N'    TargetEntityType TINYINT,' + @CRLF +
N'    AlertDetailQuery NVARCHAR(MAX)' + @CRLF +
N');' + @CRLF + @CRLF +
N'INSERT INTO @SourceMetrics (OriginalMetricId, Name, Description, Tsql, Frequency, UseRateOfChange, Multiplier, Status, Databases, DatabaseSelectionMode, SampleTime, TargetEntityType, AlertDetailQuery)' + @CRLF +
N'VALUES' + @CRLF +
@MetricValues + N';' + @CRLF + @CRLF +
N'DECLARE @OrigId BIGINT, @Name NVARCHAR(255), @Desc NVARCHAR(MAX), @Tsql NVARCHAR(MAX),' + @CRLF +
N'        @Freq BIGINT, @UseRoC BIT, @Mult FLOAT, @Stat TINYINT, @Dbs NVARCHAR(MAX),' + @CRLF +
N'        @DbSelMode TINYINT, @SampleT NVARCHAR(10), @TargetET TINYINT, @AlertDQ NVARCHAR(MAX);' + @CRLF + @CRLF +
N'DECLARE MetricCursor CURSOR LOCAL FAST_FORWARD FOR' + @CRLF +
N'    SELECT OriginalMetricId, Name, Description, Tsql, Frequency, UseRateOfChange, Multiplier,' + @CRLF +
N'           Status, Databases, DatabaseSelectionMode, SampleTime, TargetEntityType, AlertDetailQuery' + @CRLF +
N'    FROM @SourceMetrics' + @CRLF +
N'    ORDER BY OriginalMetricId;' + @CRLF + @CRLF +
N'OPEN MetricCursor;' + @CRLF +
N'FETCH NEXT FROM MetricCursor INTO @OrigId, @Name, @Desc, @Tsql, @Freq, @UseRoC, @Mult,' + @CRLF +
N'                                   @Stat, @Dbs, @DbSelMode, @SampleT, @TargetET, @AlertDQ;' + @CRLF + @CRLF +
N'WHILE @@FETCH_STATUS = 0' + @CRLF +
N'BEGIN' + @CRLF +
N'    INSERT INTO settings.CustomMetrics (Name, Description, Tsql, Frequency, UseRateOfChange, Multiplier, Status, Databases, DatabaseSelectionMode, SampleTime, TargetEntityType, AlertDetailQuery)' + @CRLF +
N'    VALUES (@Name, @Desc, @Tsql, @Freq, @UseRoC, @Mult, @Stat, CAST(@Dbs AS XML), @DbSelMode, @SampleT, @TargetET, @AlertDQ);' + @CRLF + @CRLF +
N'    INSERT INTO @NewIDs (OriginalMetricID, NewMetricID)' + @CRLF +
N'    VALUES (@OrigId, SCOPE_IDENTITY());' + @CRLF + @CRLF +
N'    FETCH NEXT FROM MetricCursor INTO @OrigId, @Name, @Desc, @Tsql, @Freq, @UseRoC, @Mult,' + @CRLF +
N'                                       @Stat, @Dbs, @DbSelMode, @SampleT, @TargetET, @AlertDQ;' + @CRLF +
N'END' + @CRLF + @CRLF +
N'CLOSE MetricCursor;' + @CRLF +
N'DEALLOCATE MetricCursor;' + @CRLF + @CRLF;

IF @AlertValues <> N''
BEGIN
    SET @Script = @Script +
    N'INSERT INTO settings.CustomAlertDefinitions (Name, Description, CustomMetricId, Direction)' + @CRLF +
    N'SELECT ad.Name, ad.Description, n.NewMetricID, ad.Direction' + @CRLF +
    N'FROM (' + @CRLF +
    N'    VALUES' + @CRLF +
    @AlertValues + @CRLF +
    N') AS ad (Name, Description, OldMetricId, Direction)' + @CRLF +
    N'INNER JOIN @NewIDs n ON ad.OldMetricId = n.OriginalMetricID;' + @CRLF;
END

-- Chunked PRINT to avoid 4000-char truncation
DECLARE @Offset INT = 0;
DECLARE @Length INT = LEN(@Script);
DECLARE @ChunkSize INT = 4000;

WHILE @Offset < @Length
BEGIN
    PRINT SUBSTRING(@Script, @Offset + 1, @ChunkSize);
    SET @Offset = @Offset + @ChunkSize;
END