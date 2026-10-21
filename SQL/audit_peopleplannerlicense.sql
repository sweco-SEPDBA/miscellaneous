
UPDATE audit
SET audit.Name = pp.Name, audit.ExternalId = pp.ExternalId, audit.EmploymentEnded = pp.EmploymentEnded
FROM [PeoplePlannerLicense].[dbo].[Resources] audit
LEFT JOIN [PeoplePlanner].[dbo].[Resource] pp ON pp.Oid = audit.Oid
WHERE pp.Oid IS NOT NULL;

UPDATE audit
SET audit.EmploymentEnded = pp.EmploymentEnded
FROM [PeoplePlannerLicense].[dbo].[Resources] audit
LEFT JOIN [PeoplePlanner].[dbo].[Resource] pp ON pp.ExternalId = audit.ExternalId
WHERE pp.ExternalId IS NOT NULL OR pp.ExternalId <> '';

----------------------------------------------------------------

INSERT INTO [PeoplePlannerLicense].[dbo].[Resources]
(Oid, ExternalId, Origin, Name, EmploymentEnded, HasAssignments, HasPeoplePlannerAssignments, HasPeoplePlannerManhours, CountedUTC, CreatedUTC)
SELECT pp.Oid
, pp.ExternalId
, pp.Origin
, pp.Name
, pp.EmploymentEnded
, 0
, 0
, 0
, NULL
, GETUTCDATE()
FROM [PeoplePlanner].[dbo].[Resource] pp
WHERE NOT EXISTS(SELECT Oid
                 FROM [PeoplePlannerLicense].[dbo].[Resources] audit
                 WHERE audit.Oid = pp.Oid);

----------------------------------------------------------------

UPDATE audit
SET audit.HasAssignments = 1
FROM [PeoplePlannerLicense].[dbo].[Resources] audit
LEFT JOIN [PeoplePlanner].[dbo].[Resource] pp ON pp.Oid = audit.Oid
WHERE audit.HasAssignments = 0 
AND pp.AssignmentCount IS NOT NULL 
AND pp.AssignmentCount > 0;

----------------------------------------------------------------

UPDATE audit
SET audit.HasPeoplePlannerAssignments = 1, CountedUTC = ISNULL(CountedUTC, GETUTCDATE())
FROM [PeoplePlannerLicense].[dbo].[Resources] audit
LEFT JOIN [PeoplePlanner].[dbo].[Assignment] pp ON pp.Resource = audit.Oid
WHERE audit.HasAssignments = 1 
AND audit.HasPeoplePlannerAssignments = 0
AND pp.CreationKind = 0;

----------------------------------------------------------------

UPDATE audit
SET audit.HasPeoplePlannerManhours = 1, CountedUTC = ISNULL(CountedUTC, GETUTCDATE())
FROM [PeoplePlannerLicense].[dbo].[Resources] audit
RIGHT JOIN [PeoplePlanner].[dbo].[ManHoursEntry] pp ON pp.Resource = audit.Oid
WHERE audit.HasAssignments = 1
AND audit.HasPeoplePlannerManhours = 0;


----------------------------------------------------------------


DECLARE @resources NVARCHAR(MAX);
SET @resources = '<resources>' +
(
	SELECT Id, Oid, ExternalId, Origin, EmploymentEnded, Name, CreatedUTC, HasAssignments, HasPeoplePlannerAssignments, HasPeoplePlannerManhours, CountedUTC
	FROM [PeoplePlannerLicense].[dbo].[Resources]
	FOR XML AUTO
) + '</resources>';

INSERT INTO [PeoplePlannerLicense].[dbo].[ResourceAssignments]
(Date, ResourceCount, Resources)
VALUES (GETUTCDATE(), 
(
	SELECT COUNT(DISTINCT (CASE
								WHEN ExternalId IS NULL THEN Oid
								WHEN ExternalId = '' THEN Oid
								ELSE ExternalId
						   END))
	FROM [PeoplePlannerLicense].[dbo].[Resources]
	WHERE (ExternalId <> 'MaconomyGenericAmountResource' AND ExternalId <> 'MaconomyActualResourceEvent' OR ExternalId IS NULL) 
	AND (HasPeoplePlannerAssignments = 1 OR HasPeoplePlannerManhours = 1) 
	AND (EmploymentEnded IS NULL OR EmploymentEnded > GETDATE())
), @resources);
