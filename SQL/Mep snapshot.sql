------------------------------------------------------
-- Create the snapshot
CREATE DATABASE mepHRM_SS20250310
ON
(
    NAME =mepHRMPohja,
    FILENAME ='E:\SQLData\SWSQL36P\mepHRM_SS20250310.ss'
)
AS SNAPSHOT OF mepHRM

------------------------------------------------------
-- Revert from snapshot
USE master;
RESTORE DATABASE mepHRM from
DATABASE_SNAPSHOT = 'mepHRM_SS20250310';
GO

------------------------------------------------------
-- Dropt the snapshot
DROP DATABASE mepHRM_SS20250310 ;
------------------------------------------------------