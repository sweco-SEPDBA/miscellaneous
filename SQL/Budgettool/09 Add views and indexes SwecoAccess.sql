USE [swecoaccess]
GO

CREATE VIEW [dbo].[APP_viewMainLevels]
as

select  t.id as RowId,
    t.loginId,
    t.unitLevelId as unitLevelId,
    l.UnitLevelName as unitLevelName,
    r.roleId as RoleId,
    r.name as RoleName,
    t.validFromDate,
    t.validToDate,
    isnull(r.AccessLevelId, 0) as AccessLevelId,
    isnull(o.addonOptionId,-1) as AddonId,
    isnull(o.OptionName,'') as AddonName,
    case t.unitLevelId when  5 then t.TeamId
      when 4 then t.DepartmentId
      when 3 then t.BusinessUnitId
      when 2 then t.BusinessDivisionId
      when 1 then t.BusinessAreaId
      when 99 then t.CompanyId
      when 0 then '0' end as UnitId,
    case t.unitLevelId when  5 then t.CompanyId
      when 4 then t.BusinessAreaId
      when 3 then t.BusinessAreaId
      when 2 then t.BusinessAreaId
      when 1 then t.BusinessAreaId
      when 99 then t.CompanyId
      when 0 then '0' end as ParentId,
    isnull(t.BusinessAreaId, '') as BusinessAreaId,
    isnull(t.BusinessDivisionId, '') as BusinessDivisionId,
    isnull(t.BusinessUnitId, '') as BusinessUnitId,
    isnull(t.DepartmentId, '') DepartmentId,
    isnull(t.TeamId, '') as TeamId,
    isnull(t.CompanyId, '') as CompanyId,
    -1 as InheritedFromId,
    '' as InheritedFromName,
    r.InheritencePossible,
    coalesce(t.updated, t.created) as updated,
    coalesce(t.updatedby, t.createdby) as updatedby,    -- select *
    t.approved as approved,
    t.approvedBy as approvedBy
from roleAssignments t
join swecocore.Core.OrgUnitLevel l on t.unitLevelId = l.UnitLevelId    -- changed from l.UnitLevelKey / Arnold 2021-09-16
left join roleDescriptions r on t.roleId = r.roleId
left join addonOptions o on o.addonOptionId = t.addonId
GO
SET ANSI_PADDING ON
GO


/****** Object:  Index [ix_roleAssignments_LoginId]    Script Date: 2025-07-16 09:22:36 ******/
CREATE NONCLUSTERED INDEX [ix_roleAssignments_LoginId] ON [dbo].[roleAssignments]
(
  [loginId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO