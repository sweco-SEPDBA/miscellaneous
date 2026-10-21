
select top 1 count ( * ) from ( "dbo" . "Event" N0 inner join "dbo" . "Event" N1 on ( N0 . "ParentProject" = N1 . "Oid" ) ) where ( N1 . "ProjectNumber" = @0 )

/*
USE [PeoplePlanner]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[Event] ([ProjectNumber])

GO
*/



select top 10 N0 . "Oid" from "dbo" . "Resource" N0 where ( ( N0 . "Kind" < > @0 ) and exists ( select * from "dbo" . "Assignment" N1 where ( ( N0 . "Oid" = N1 . "Resource" ) and exists ( select * from ( "dbo" . "Event" N2 inner join "dbo" . "Event" N3 on ( N2 . "ParentProject" = N3 . "Oid" ) ) where ( ( N1 . "Event" = N2 . "Oid" ) and ( N3 . "ProjectNumber" = @1 ) ) ) ) ) ) order by N0 . "Name" asc , N0 . "Oid" asc

/*
USE [PeoplePlanner]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[Event] ([ProjectNumber])

GO
*/


select top 22 N0 . "Oid" from ( ( "dbo" . "Event" N0 inner join "dbo" . "Event" N1 on ( N0 . "ParentProject" = N1 . "Oid" ) ) left join "dbo" . "Event" N2 on ( N0 . "MainProject" = N2 . "Oid" ) ) where ( N1 . "ProjectNumber" = @0 ) order by N2 . "AutomaticWBSSequence" asc , N0 . "AutomaticWBSString" asc , N0 . "Oid" asc


/*
USE [PeoplePlanner]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[Event] ([ProjectNumber])

GO
*/


select top 1 count ( * ) from "dbo" . "Resource" N0 where ( ( N0 . "Kind" < > @0 ) and exists ( select * from "dbo" . "Assignment" N1 where ( ( N0 . "Oid" = N1 . "Resource" ) and exists ( select * from ( "dbo" . "Event" N2 inner join "dbo" . "Event" N3 on ( N2 . "ParentProject" = N3 . "Oid" ) ) where ( ( N1 . "Event" = N2 . "Oid" ) and ( N3 . "ProjectNumber" = @1 ) ) ) ) ) )

/*
Missing Index Details from SQLQuery15.sql - swsrvds005.database.windows.net.master (sepdba_da@sweco.se (96))
The Query Processor estimates that implementing the following index could improve the query cost by 98.143%.
*/

/*
USE [PeoplePlanner]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[Event] ([ProjectNumber])

GO
*/

select N0."Oid" from ("dbo"."Assignment" N0 inner join "dbo"."Event" N1 on (N0."Event" = N1."Oid")) where ((N1."IsArchived" = 0) and (N0."Resource" = @p0)) order by N0."Name" asc,N0."Oid" asc offset 980 rows fetch next 20 rows only

exec sp_executesql 'select N0."Oid",N0."ModificationTimestamp",N0."ModifiedBy",N0."Name",N0."IsArchived",N0."Version",N0."Description",N0."CreateUTC",N0."AdHoc",N0."Marked",N0."Color",N0."Origin",N0."ExternalId",N0."IsBlocked",N0."Label1",N0."CustomFlag",N0."Label2",N0."Label3",N0."Prototype",N0."CreatedFromPrototypeOid",N0."IsFromPrototype",N0."State",N0."StateTime",N0."StateMessage",N0."GroupValueDistibution",N0."IsComplete",N0."Kind",N0."CreationKind",N0."ChildAssignmentCount",N0."ParentAssignment",N0."EmployeeCategory",N0."AssignedResourceCategory",N0."Resource",N0."Event",N0."EstimateToComplete",N0."Estimate",N0."Allocated",N0."AllocatedAmount",N0."ApprovedAllocated",N0."OriginalAllocated",N0."SimpleRate",N0."TopDownWorkload",N0."ReasonForRequestText",N0."ReasonForRequest",N0."ImportantSkill",N0."WorkflowStatus",N0."Text1",N0."Text2",N0."Text3",N0."Text4",N0."Text5",N0."Text6",N0."Text7",N0."Text8",N0."Text9",N0."Text10",N0."Value1",N0."Value2",N0."Value3",N0."Value4",N0."Value5",N0."Value6",N0."Value7",N0."Value8",N0."Value9",N0."Value10",N0."Date1",N0."Date2",N0."Date3",N0."Date4",N0."Date5",N0."Date6",N0."Date7",N0."Date8",N0."Date9",N0."Date10",N0."Popup1",N0."Popup2",N0."Popup3",N0."Popup4",N0."Popup5",N0."Popup6",N0."Popup7",N0."Popup8",N0."Popup9",N0."Popup10",N0."Flag1",N0."Flag2",N0."Flag3",N0."Flag4",N0."Flag5",N0."Flag6",N0."Flag7",N0."Flag8",N0."Flag9",N0."Flag10",N0."SortingKey",N0."RequestedTimeStamp",N0."ProcessedTimeStamp",N0."Status",N0."ExpandedResourceGroupName",N0."SimpleCost",N0."Finish",N0."Start",N0."OptimisticLockField" from ("dbo"."Assignment" N0 inner join "dbo"."Event" N1 on (N0."Event" = N1."Oid")) where ((N0."Start" <= @p0) and (N0."Finish" >= @p1) and (N1."IsArchived" = #) and (N0."Resource" = @p2))',N'@p0 datetime,@p1 datetime,@p2 uniqueidentifier',@p0=$,@p1=$,@p2=$	


