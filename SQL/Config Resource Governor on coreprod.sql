-- Run this in coreprod instances

USE [master]
GO

CREATE RESOURCE POOL [PoolHighUsers] 
WITH(
	min_cpu_percent=0, 
	max_cpu_percent=40, 
	min_memory_percent=0, 
	max_memory_percent=100, 
	cap_cpu_percent=60, 
	AFFINITY SCHEDULER = AUTO, 
	min_iops_per_volume=0, 
	max_iops_per_volume=0
)
GO

CREATE WORKLOAD GROUP [GroupHighUsers] WITH(group_max_requests=0, 
		importance=Medium, 
		request_max_cpu_time_sec=0, 
		request_max_memory_grant_percent=20, 
		request_memory_grant_timeout_sec=0, 
		max_dop=0) USING [PoolHighUsers], EXTERNAL [default]
GO


CREATE FUNCTION [dbo].[GroupHighUsers]() RETURNS sysname 
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @grp_name sysname

    IF (SUSER_NAME()  IN ('SwecoApi')) 
        SET @grp_name = 'GroupHighUsers'

    IF (SUSER_NAME()  IN  ('swecocore'))
        SET @grp_name = 'GroupPrioUsers'

    RETURN @grp_name 
END;
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;  -- Enables and restarts rg run after alter or when you want to start rg.
GO  


-- Run this in projectwise instances
USE [master]
GO

/****** Object:  ResourcePool [PoolPerftest]    Script Date: 2023-12-05 12:58:51 ******/
CREATE RESOURCE POOL [PoolHighUsers] 
WITH(
	min_cpu_percent=0, 
	max_cpu_percent=20, 
	min_memory_percent=0, 
	max_memory_percent=100, 
	cap_cpu_percent=30, 
	AFFINITY SCHEDULER = AUTO, 
	min_iops_per_volume=0, 
	max_iops_per_volume=0
)
GO

/****** Object:  WorkloadGroup [GroupPerftest]    Script Date: 2023-12-05 12:59:00 ******/
CREATE WORKLOAD GROUP [GroupHighUsers] WITH(group_max_requests=0, 
		importance=Medium, 
		request_max_cpu_time_sec=0, 
		request_max_memory_grant_percent=20, 
		request_memory_grant_timeout_sec=0, 
		max_dop=0) USING [PoolHighUsers], EXTERNAL [default]
GO


CREATE FUNCTION [dbo].[GroupHighUsers]() RETURNS sysname 
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @grp_name sysname

    IF (SUSER_NAME()  IN ('SWECO\svc_pw_integr')) 
        SET @grp_name = 'GroupHighUsers'

    RETURN @grp_name 
END;
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;  -- Enables and restarts rg run after alter or when you want to start rg.
GO  







































/****** Object:  ResourcePool [PoolRGUser]    Script Date: 2023-12-05 12:59:13 ******/
CREATE RESOURCE POOL [PoolPrioUsers] 
WITH(
	min_cpu_percent=20, 
	max_cpu_percent=80, 
	min_memory_percent=0, 
	max_memory_percent=100, 
	cap_cpu_percent=100, 
	AFFINITY SCHEDULER = AUTO, 
	min_iops_per_volume=0, 
	max_iops_per_volume=0)
GO


/****** Object:  WorkloadGroup [GroupRGUser]    Script Date: 2023-12-05 12:59:38 ******/
CREATE WORKLOAD GROUP [GroupPrioUsers] WITH(group_max_requests=0, 
		importance=Medium, 
		request_max_cpu_time_sec=0, 
		request_max_memory_grant_percent=25, 
		request_memory_grant_timeout_sec=0, 
		max_dop=0) USING [PoolPrioUsers], EXTERNAL [default]
GO

/****** Object:  UserDefinedFunction [dbo].[RG_Classifier]    Script Date: 2023-12-05 13:00:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[GroupHighUsers]() RETURNS sysname 
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @grp_name sysname

    IF (SUSER_NAME()  IN ('SwecoApi', 'webbeko', 'tre')) -- For projectwise instance this will be: ('SWECO\svc_pw_integr')
        SET @grp_name = 'GroupHighUsers'

    IF (SUSER_NAME()  IN  ('swecocore'))
        SET @grp_name = 'GroupPrioUsers'

    RETURN @grp_name 
END;
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;  -- Enables and restarts rg run after alter or when you want to start rg.
GO  

--ALTER RESOURCE POOL [PoolPerftest] 
--WITH(
--	min_cpu_percent=20, 
--	max_cpu_percent=30, 
--	min_memory_percent=0, 
--	max_memory_percent=100, 
--	cap_cpu_percent=60, 
--	AFFINITY SCHEDULER = AUTO, 
--	min_iops_per_volume=0, 
--	max_iops_per_volume=0
--)
--GO  

--ALTER RESOURCE POOL [PoolRGUser] 
--WITH(
--	min_cpu_percent=20, 
--	max_cpu_percent=20, 
--	min_memory_percent=0, 
--	max_memory_percent=100, 
--	cap_cpu_percent=30, 
--	AFFINITY SCHEDULER = AUTO, 
--	min_iops_per_volume=0, 
--	max_iops_per_volume=0
--)
--GO


--ALTER RESOURCE GOVERNOR RECONFIGURE;  -- Enables and restarts rg run after alter or when you want to start rg.
--GO  
--ALTER RESOURCE GOVERNOR DISABLE; -- Disables rg
--GO

