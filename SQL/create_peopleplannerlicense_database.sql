USE master
GO

CREATE DATABASE [PeoplePlannerLicense]
GO

USE [PeoplePlannerLicense]
GO

CREATE TABLE [ResourceAssignments] (
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Date] [date] NULL,
	[ResourceCount] [int] NULL,
	[Resources] [nvarchar](max) NULL,
) ON [PRIMARY]

CREATE TABLE [dbo].[Resources] (
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Oid] [nvarchar](max) NULL,
	[ExternalId] [nvarchar](max) NULL,
	[Origin] [nvarchar](max) NULL,
	[EmploymentEnded] [datetime] NULL,
	[Name] [nvarchar](max) NULL,
	[CreatedUTC] [datetime] NULL,
	[HasAssignments] [bit] NULL,
	[HasPeoplePlannerAssignments] [bit] NULL,
	[HasPeoplePlannerManhours] [bit] NULL,
	[CountedUTC] [datetime] NULL
) ON [PRIMARY]


ALTER TABLE dbo.Resources ADD [HasPeoplePlannerAssignments] [bit] NULL;
ALTER TABLE dbo.Resources ADD [HasPeoplePlannerManhours] [bit] NULL;
