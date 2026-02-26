
#Create databases
new-dbadatabase -SqlInstance SESTOVH110.sweco.se\SWSQL54P -Database SwecoAccess -PrimaryFilesize 10240 -LogSize 1024 -PrimaryFileGrowth 1024 -LogGrowth 512 
new-dbadatabase -SqlInstance SESTOVH110.sweco.se\SWSQL54P -Database SwecoCore -PrimaryFilesize 40960 -LogSize 1024 -PrimaryFileGrowth 1024 -LogGrowth 512 
new-dbadatabase -SqlInstance SESTOVH111.sweco.se\SWSQL55P -Database SwecoAccess -PrimaryFilesize 10240 -LogSize 1024 -PrimaryFileGrowth 1024 -LogGrowth 512 
new-dbadatabase -SqlInstance SESTOVH111.sweco.se\SWSQL55P -Database SwecoCore -PrimaryFilesize 40960 -LogSize 1024 -PrimaryFileGrowth 1024 -LogGrowth 512 
new-dbadatabase -SqlInstance DEFRADS015.sweco.se\DESQL18P -Database SwecoAccess -PrimaryFilesize 10240 -LogSize 1024 -PrimaryFileGrowth 1024 -LogGrowth 512 
new-dbadatabase -SqlInstance DEFRADS015.sweco.se\DESQL18P -Database SwecoCore -PrimaryFilesize 40960 -LogSize 1024 -PrimaryFileGrowth 1024 -LogGrowth 512 

#Create Schemas
New-DbaDbSchema -SqlInstance SESTOVH110.sweco.se\SWSQL54P -Database SwecoCore -Schema coredata
New-DbaDbSchema -SqlInstance SESTOVH110.sweco.se\SWSQL54P -Database SwecoCore -Schema core
New-DbaDbSchema -SqlInstance SESTOVH110.sweco.se\SWSQL54P -Database SwecoCore -Schema corex
New-DbaDbSchema -SqlInstance SESTOVH110.sweco.se\SWSQL54P -Database SwecoCore -Schema coreEco
New-DbaDbSchema -SqlInstance SESTOVH110.sweco.se\SWSQL54P -Database SwecoCore -Schema coreEcox

New-DbaDbSchema -SqlInstance SESTOVH111.sweco.se\SWSQL55P -Database SwecoCore -Schema coredata
New-DbaDbSchema -SqlInstance SESTOVH111.sweco.se\SWSQL55P -Database SwecoCore -Schema core
New-DbaDbSchema -SqlInstance SESTOVH111.sweco.se\SWSQL55P -Database SwecoCore -Schema corex
New-DbaDbSchema -SqlInstance SESTOVH111.sweco.se\SWSQL55P -Database SwecoCore -Schema coreEco
New-DbaDbSchema -SqlInstance SESTOVH111.sweco.se\SWSQL55P -Database SwecoCore -Schema coreEcox

New-DbaDbSchema -SqlInstance DEFRADS015.sweco.se\DESQL18P -Database SwecoCore -Schema coredata
New-DbaDbSchema -SqlInstance DEFRADS015.sweco.se\DESQL18P -Database SwecoCore -Schema core
New-DbaDbSchema -SqlInstance DEFRADS015.sweco.se\DESQL18P -Database SwecoCore -Schema corex
New-DbaDbSchema -SqlInstance DEFRADS015.sweco.se\DESQL18P -Database SwecoCore -Schema coreEco
New-DbaDbSchema -SqlInstance DEFRADS015.sweco.se\DESQL18P -Database SwecoCore -Schema coreEcox

#Pre create some tables
$query = @"
CREATE TABLE [CoreData].[EcoAccount](
	[AccountKey] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[AccountchartKey] [int] NOT NULL,
	[AccountId] [varchar](10) NOT NULL,
	[MainAccountKey] [int] NOT NULL,
	[AccountGroupProjectKey] [int] NULL,
	[AccountName] [nvarchar](100) NOT NULL,
	[Active] [bit] NOT NULL,
	[IncludeInGroupAccounting] [bit] NOT NULL,
	[ManualBookingsAllowed] [bit] NULL,
	[src_ChangedBy] [int] NULL,
	[src_ChangedTime] [datetime2](0) NULL,
	[md_InsertedTime] [datetime2](7) NULL,
	[md_InsertedBy] [varchar](35) NULL,
	[md_ChangedTime] [datetime2](7) NULL,
	[md_ChangedBy] [varchar](35) NULL,
	[md_RowVersion] [int] NULL,
	[md_RowState] [int] NULL,
	[md_SourceId] [int] NULL,
	[md_StgRowId] [int] NULL,
	[md_LoadJobId] [int] NULL,
	[md_DqLevel] [int] NULL,
	[md_DqIssueDescription] [varchar](200) NULL,
	[BudgetAccountID] [varchar](10) NULL,
	[md_BPK]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(isnull(CONVERT([nvarchar](30),[AccountchartKey]),'')+'|')+isnull(CONVERT([nvarchar](30),[AccountId]),'')))),
	[md_BD]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(isnull(CONVERT([nvarchar](100),[AccountName]),'')+'|')+isnull(CONVERT([nvarchar](30),[Active]),'')))),
 CONSTRAINT [PK_EcoAccount] PRIMARY KEY CLUSTERED 
(
	[AccountKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_EcoAccount_AccountId] UNIQUE NONCLUSTERED 
(
	[AccountId] ASC,
	[AccountchartKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];

"@
Invoke-DbaQuery -SqlInstance sestovh110.sweco.se\swsql54p -Database SwecoCore -Query $query 
Invoke-DbaQuery -SqlInstance sestovh111.sweco.se\swsql55p -Database SwecoCore -Query $query 
Invoke-DbaQuery -SqlInstance defrads015.sweco.se\desql18p -Database SwecoCore -Query $query

$query = @"
CREATE TABLE [CoreData].[ProjectTask](
	[ProjectTaskKey] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ProjectKey] [int] NOT NULL,
	[ProjectTaskCode] [nvarchar](255) NULL,
	[ProjectTaskName] [nvarchar](255) NULL,
	[src_ChangedTime] [datetime2](0) NULL,
	[src_ChangedBy] [int] NULL,
	[md_InsertedTime] [datetime2](7) NULL,
	[md_InsertedBy] [varchar](35) NULL,
	[md_ChangedTime] [datetime2](7) NULL,
	[md_ChangedBy] [varchar](35) NULL,
	[md_RowVersion] [int] NULL,
	[md_RowState] [int] NULL,
	[md_SourceId] [int] NULL,
	[md_StgRowId] [int] NULL,
	[md_LoadJobId] [int] NULL,
	[md_DqLevel] [int] NULL,
	[md_DqIssueDescription] [varchar](200) NULL,
	[ActivityNumber] [varchar](10) NULL,
	[AllowTime] [bit] NULL,
	[AllowExpenses] [bit] NULL,
	[md_BPK]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(isnull(CONVERT([nvarchar](30),[ProjectKey]),'')+'|')+isnull(CONVERT([nvarchar](255),[ProjectTaskCode]),'')))),
	[md_BD]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(((((((((isnull(CONVERT([nvarchar](255),[ProjectTaskName]),'')+'|')+isnull(CONVERT([nvarchar](30),[src_ChangedTime],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[src_ChangedBy]),''))+'|')+isnull(CONVERT([nvarchar](30),[AllowTime]),''))+'|')+isnull(CONVERT([nvarchar](30),[AllowExpenses]),''))+'|')+isnull(CONVERT([nvarchar](30),[ActivityNumber]),'')))),
 CONSTRAINT [PK_ProjectTask] PRIMARY KEY CLUSTERED 
(
	[ProjectTaskKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
"@
Invoke-DbaQuery -SqlInstance sestovh110.sweco.se\swsql54p -Database SwecoCore -Query $query 
Invoke-DbaQuery -SqlInstance sestovh111.sweco.se\swsql55p -Database SwecoCore -Query $query 
Invoke-DbaQuery -SqlInstance defrads015.sweco.se\desql18p -Database SwecoCore -Query $query

$query = @"
CREATE TABLE [CoreData].[EcoExchangeRate](
	[ExchangeRateKey] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BaseCurrencyKey] [int] NOT NULL,
	[ForeignCurrencyKey] [int] NOT NULL,
	[RateDate] [date] NOT NULL,
	[ExchangeRate] [numeric](16, 8) NULL,
	[md_InsertedTime] [datetime2](7) NULL,
	[md_InsertedBy] [varchar](35) NULL,
	[md_ChangedTime] [datetime2](7) NULL,
	[md_ChangedBy] [varchar](35) NULL,
	[md_RowVersion] [int] NULL,
	[md_RowState] [int] NULL,
	[md_SourceId] [int] NULL,
	[md_StgRowId] [int] NULL,
	[md_LoadJobId] [int] NULL,
	[md_DqLevel] [int] NULL,
	[md_DqIssueDescription] [varchar](200) NULL,
	[ExchangeRateCalculationMethodKey] [int] NOT NULL,
	[md_BPK]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(((isnull(CONVERT([nvarchar](30),[BaseCurrencyKey]),'')+'|')+isnull(CONVERT([nvarchar](30),[ForeignCurrencyKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[RateDate],(112)),'')))),
	[md_BD]  AS (CONVERT([binary](32),hashbytes('SHA2_256',isnull(CONVERT([nvarchar](30),[ExchangeRate]),'')))),
 CONSTRAINT [PK_EcoExchangeRate] PRIMARY KEY CLUSTERED 
(
	[ExchangeRateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
"@

Invoke-DbaQuery -SqlInstance sestovh110.sweco.se\swsql54p -Database SwecoCore -Query $query 
Invoke-DbaQuery -SqlInstance sestovh111.sweco.se\swsql55p -Database SwecoCore -Query $query 
Invoke-DbaQuery -SqlInstance defrads015.sweco.se\desql18p -Database SwecoCore -Query $query

$query = @"
CREATE TABLE [CoreData].[EcoTimeCode](
	[TimeCodeKey] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TimeCodeId] [char](2) NOT NULL,
	[TimeCodeName] [nvarchar](50) NOT NULL,
	[IncludedInFTE] [bit] NULL,
	[src_ChangedBy] [int] NULL,
	[src_ChangedTime] [datetime2](0) NULL,
	[md_InsertedTime] [datetime2](7) NULL,
	[md_InsertedBy] [varchar](35) NULL,
	[md_ChangedTime] [datetime2](7) NULL,
	[md_ChangedBy] [varchar](35) NULL,
	[md_RowVersion] [int] NULL,
	[md_RowState] [int] NULL,
	[md_SourceId] [int] NULL,
	[md_StgRowId] [int] NULL,
	[md_LoadJobId] [int] NULL,
	[md_DqLevel] [int] NULL,
	[md_DqIssueDescription] [varchar](200) NULL,
	[TimecodeGroup]  AS (isnull(left([TimeCodeId],(1)),'')) PERSISTED NOT NULL,
	[TimecodeSubGroup]  AS (isnull(right([TimeCodeId],(1)),'')) PERSISTED NOT NULL,
	[TimecodeGroupName]  AS (case when left([TimecodeID],(1))='A' then 'Absence' when left([TimecodeID],(1))='E' then 'External Work' when left([TimecodeID],(1))='I' then 'Internal Work' else 'Other' end) PERSISTED NOT NULL,
	[md_BPK]  AS (CONVERT([binary](32),hashbytes('SHA2_256',isnull(CONVERT([nvarchar](30),[TimeCodeId]),'')))),
	[md_BD]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(isnull(CONVERT([nvarchar](50),[TimeCodeName]),'')+'|')+isnull(CONVERT([nvarchar](30),[IncludedInFTE]),'')))),
 CONSTRAINT [PK_EcoTimeCode] PRIMARY KEY CLUSTERED 
(
	[TimeCodeKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_EcoTimeCode_TimeCodeId] UNIQUE NONCLUSTERED 
(
	[TimeCodeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
"@
Invoke-DbaQuery -SqlInstance sestovh110.sweco.se\swsql54p -Database SwecoCore -Query $query
Invoke-DbaQuery -SqlInstance sestovh111.sweco.se\swsql55p -Database SwecoCore -Query $query
Invoke-DbaQuery -SqlInstance defrads015.sweco.se\desql18p -Database SwecoCore -Query $query

$query = @"
CREATE TABLE [CoreData].[EcoTimeRow](
	[TimeRowKey] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[SwecoTimecodeId] [char](2) NOT NULL,
	[EmployeeCompanyId] [char](3) NOT NULL,
	[EmployeeTeamKey] [int] NOT NULL,
	[EmployeeKey] [int] NOT NULL,
	[EmployeeTypeId] [int] NULL,
	[ProjectTaskKey] [int] NOT NULL,
	[ProjectCompanyId] [char](3) NULL,
	[ProjectTeamKey] [int] NULL,
	[ActivityNumber] [varchar](4) NULL,
	[OvertimeCode] [nvarchar](255) NULL,
	[InstanceKey] [nvarchar](255) NULL,
	[TimeDate] [date] NOT NULL,
	[TimeWeek] [int] NOT NULL,
	[TimeFiscalMonth] [int] NOT NULL,
	[ValueTypeKey] [smallint] NOT NULL,
	[OH] [money] NOT NULL,
	[Hours] [money] NOT NULL,
	[Price] [money] NOT NULL,
	[Cost] [money] NOT NULL,
	[src_ChangedTime] [datetime] NULL,
	[md_InsertedTime] [datetime2](7) NULL,
	[md_InsertedBy] [varchar](35) NULL,
	[md_ChangedTime] [datetime2](7) NULL,
	[md_ChangedBy] [varchar](35) NULL,
	[md_RowVersion] [int] NULL,
	[md_RowState] [int] NULL,
	[md_SourceId] [int] NULL,
	[md_StgRowId] [int] NULL,
	[md_LoadJobId] [int] NULL,
	[md_DqLevel] [int] NULL,
	[md_DqIssueDescription] [varchar](200) NULL,
	[TimeRowTimePeriod]  AS (case when [TimeDate]>'1900-01-01' then (0) else (1) end),
	[md_BD]  AS (CONVERT([binary](32),hashbytes('SHA2_256',((((((isnull(CONVERT([nvarchar](30),[OH]),'')+'|')+isnull(CONVERT([nvarchar](30),[Hours]),''))+'|')+isnull(CONVERT([nvarchar](30),[Price]),''))+'|')+isnull(CONVERT([nvarchar](30),[Cost]),''))+isnull(CONVERT([nvarchar](30),[EmployeeTypeId]),'')))),
	[md_BPK]  AS (CONVERT([binary](32),hashbytes('SHA2_256',((((((((((((((((((((((((((isnull(CONVERT([nvarchar](30),[SwecoTimecodeId]),'')+'|')+isnull(CONVERT([nvarchar](30),[EmployeeCompanyId]),''))+'|')+isnull(CONVERT([nvarchar](30),[EmployeeTeamKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[EmployeeKey]),''))+'|')+'|')+isnull(CONVERT([nvarchar](30),[ProjectTaskKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectCompanyId]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectTeamKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[ActivityNumber]),''))+'|')+isnull(CONVERT([nvarchar](255),[OvertimeCode]),''))+'|')+isnull(CONVERT([nvarchar](30),[ValueTypeKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[TimeDate],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[TimeWeek]),''))+'|')+isnull(CONVERT([nvarchar](30),[TimeFiscalMonth]),''))+'|')+isnull(CONVERT([nvarchar](255),[InstanceKey]),'')))),
CONSTRAINT [PK_EcoTimerow] PRIMARY KEY CLUSTERED 
(
	[TimeRowKey] ASC,
	[TimeFiscalMonth] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)  ON [PRIMARY],
CONSTRAINT [UQ_EcoTimerow2] UNIQUE NONCLUSTERED 
(
	[SwecoTimecodeId] ASC,
	[EmployeeCompanyId] ASC,
	[EmployeeTeamKey] ASC,
	[EmployeeKey] ASC,
	[EmployeeTypeId] ASC,
	[ProjectTaskKey] ASC,
	[ProjectCompanyId] ASC,
	[ProjectTeamKey] ASC,
	[ActivityNumber] ASC,
	[OvertimeCode] ASC,
	[ValueTypeKey] ASC,
	[TimeDate] ASC,
	[TimeWeek] ASC,
	[TimeFiscalMonth] ASC,
	[InstanceKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)  ON [PRIMARY]
)  ON [PRIMARY]
"@
Invoke-DbaQuery -SqlInstance sestovh110.sweco.se\swsql54p -Database SwecoCore -Query $query
Invoke-DbaQuery -SqlInstance sestovh111.sweco.se\swsql55p -Database SwecoCore -Query $query
Invoke-DbaQuery -SqlInstance defrads015.sweco.se\desql18p -Database SwecoCore -Query $query

$query = @"
CREATE TABLE [CoreData].[EcoTransaction](
	[TransactionKey] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[CompanyId] [char](3) NOT NULL,
	[TransactionDate] [date] NOT NULL,
	[VoucherId] [varchar](20) NOT NULL,
	[AccountId] [varchar](10) NULL,
	[TeamKey] [int] NULL,
	[ProjectKey] [int] NULL,
	[InterCompanyId] [char](3) NULL,
	[EmployeeKey] [int] NULL,
	[Amount] [money] NOT NULL,
	[Count] [money] NOT NULL,
	[Text] [nvarchar](255) NULL,
	[ValueTypeKey] [smallint] NULL,
	[LegacyAccountId] [varchar](10) NULL,
	[TaskName] [nvarchar](255) NULL,
	[ActivityNumber] [nvarchar](255) NULL,
	[InstanceKey] [nvarchar](255) NULL,
	[PostedBy] [nvarchar](255) NULL,
	[src_ChangedTime] [datetime] NOT NULL,
	[md_InsertedTime] [datetime2](7) NULL,
	[md_InsertedBy] [varchar](35) NULL,
	[md_ChangedTime] [datetime2](7) NULL,
	[md_ChangedBy] [varchar](35) NULL,
	[md_RowVersion] [int] NULL,
	[md_RowState] [int] NULL,
	[md_SourceId] [int] NULL,
	[md_StgRowId] [int] NULL,
	[md_LoadJobId] [int] NULL,
	[md_DqLevel] [int] NULL,
	[md_DqIssueDescription] [varchar](200) NULL,
	[CounterpartTeamKey] [int] NULL,
	[TransactionTypeKey] [int] NULL,
	[md_BD]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(((((((isnull(CONVERT([nvarchar](30),[Amount]),'')+'|')+isnull(CONVERT([nvarchar](30),[Count]),''))+'|')+isnull(CONVERT([nvarchar](30),[src_ChangedTime],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[CounterpartTeamKey],(112)),''))+'|')+isnull(CONVERT([nvarchar](255),[Text]),'')))),
	[md_BPK]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(((((((((((((((((((((((((isnull(CONVERT([nvarchar](255),[InstanceKey]),'')+'|')+isnull(CONVERT([nvarchar](30),[TransactionDate],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[AccountId]),''))+'|')+isnull(CONVERT([nvarchar](30),[InterCompanyId]),''))+'|')+isnull(CONVERT([nvarchar](30),[CompanyId]),''))+'|')+isnull(CONVERT([nvarchar](30),[TeamKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[EmployeeKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[VoucherId]),''))+'|')+isnull(CONVERT([nvarchar](30),[ValueTypeKey]),''))+'|')+isnull(CONVERT([nvarchar](255),[ActivityNumber]),''))+'|')+isnull(CONVERT([nvarchar](255),[TaskName]),''))+'|')+isnull(CONVERT([nvarchar](30),[md_SourceId]),''))+'|')+isnull(CONVERT([nvarchar](30),[TransactionTypeKey]),'')))),
CONSTRAINT [PK_EcoTransaction50] PRIMARY KEY CLUSTERED 
(
	[TransactionKey] ASC,
	[TransactionDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)  ON [PRIMARY]
)  ON [PRIMARY]
GO
"@
Invoke-DbaQuery -SqlInstance sestovh110.sweco.se\swsql54p -Database SwecoCore -Query $query
Invoke-DbaQuery -SqlInstance sestovh111.sweco.se\swsql55p -Database SwecoCore -Query $query
Invoke-DbaQuery -SqlInstance defrads015.sweco.se\desql18p -Database SwecoCore -Query $query

$query = @"

CREATE TABLE [CoreData].[Project](
	[ProjectKey] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[CompanyId] [char](3) NOT NULL,
	[ProjectNo] [varchar](20) NOT NULL,
	[ProjectName] [nvarchar](200) NOT NULL,
	[ProjectLevel] [tinyint] NOT NULL,
	[ProjectDescription] [nvarchar](500) NOT NULL,
	[MainProjectKey] [int] NOT NULL,
	[ProjectParentKey] [int] NOT NULL,
	[ProjectTypeKey] [tinyint] NOT NULL,
	[ProjectStatusKey] [tinyint] NOT NULL,
	[ProjectContractTypeKey] [int] NULL,
	[MunicipalityKey] [smallint] NOT NULL,
	[TeamKey] [int] NOT NULL,
	[ProjectStartDate] [date] NULL,
	[ProjectEndDate] [date] NULL,
	[CustomerContact] [nvarchar](100) NULL,
	[CustomerContactEmail] [varchar](150) NULL,
	[CustomerReference] [nvarchar](255) NULL,
	[TenderId] [int] NULL,
	[Archived] [bit] NOT NULL,
	[Secure] [bit] NOT NULL,
	[RestrictedReporting] [bit] NOT NULL,
	[AllowExpenses] [bit] NOT NULL,
	[AllowNonBillableExpenses] [bit] NOT NULL,
	[CurrencyKey] [int] NULL,
	[ProjectInsuranceNo] [nvarchar](255) NULL,
	[AccessLevelName] [varchar](10) NULL,
	[src_ChangedBy] [int] NULL,
	[src_ChangedTime] [datetime2](7) NULL,
	[md_InsertedTime] [datetime2](7) NULL,
	[md_InsertedBy] [varchar](35) NULL,
	[md_ChangedTime] [datetime2](7) NULL,
	[md_ChangedBy] [varchar](35) NULL,
	[md_RowVersion] [int] NULL,
	[md_RowState] [int] NULL,
	[md_SourceId] [int] NULL,
	[md_StgRowId] [int] NULL,
	[md_LoadJobId] [int] NULL,
	[md_DqLevel] [int] NULL,
	[md_DqIssueDescription] [varchar](200) NULL,
	[ProjectRiskProfileKey] [int] NULL,
	[BidTypeKey] [int] NULL,
	[ProjectStageOutcomeKey] [int] NULL,
	[BidProbability] [int] NULL,
	[BidSubmissionDate] [date] NULL,
	[BidStartDate] [date] NULL,
	[BidEndDate] [date] NULL,
	[ProjectStartDateEstimated] [date] NULL,
	[ProjectEndDateEstimated] [date] NULL,
	[Confidential] [int] NULL,
	[InitiatingOpportunityKey] [int] NULL,
	[src_CreatedDate] [date] NULL,
	[BidClosedDate] [date] NULL,
	[ProjectRiskLevelKey] [int] NULL,
	[SmallProject] [bit] NULL,
	[ProjectClosureRequested] [bit] NULL,
	[CompanyProjectNo]  AS (CONVERT([varchar](25),([CompanyID]+'/')+[ProjectNo])),
	[IsTender]  AS (CONVERT([bit],case when [ProjectTypeKey]=(1) then (1) else (0) end)) PERSISTED,
	[IsExternal]  AS (CONVERT([bit],case when [ProjectTypeKey]=(6) then (1) else (0) end)) PERSISTED,
	[IsMainProject]  AS (CONVERT([bit],case when [ProjectLevel]=(1) then (1) else (0) end)) PERSISTED,
	[InitiatingBidKey]  AS ([TenderId]) PERSISTED,
	[IsBid]  AS (CONVERT([bit],case [ProjectTypeKey] when (1) then (1) else (0) end)) PERSISTED,
	[IsOpportunity]  AS (CONVERT([bit],case [ProjectTypeKey] when (3) then (1) else (0) end)) PERSISTED,
	[md_BPK]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(((isnull(CONVERT([nvarchar](30),upper([ProjectNo])),'')+'|')+isnull(CONVERT([nvarchar](30),[ProjectLevel]),''))+'|')+isnull(CONVERT([nvarchar](30),[CompanyID]),'')))),
	[BidStatusKey]  AS (CONVERT([tinyint],case when [ProjectTypeKey]=(1) AND [ProjectStatusKey]=(2) then (2) when [ProjectTypeKey]=(1) AND [ProjectStatusKey]<>(2) then (3) when [ProjectTypeKey]=(6) AND [BidSubmissionDate] IS NOT NULL then (3) when [BidClosedDate] IS NOT NULL then (3) else (0) end)) PERSISTED,
	[md_BD]  AS (CONVERT([binary](32),hashbytes('SHA2_256',(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((isnull(CONVERT([nvarchar](200),[ProjectName]),'')+'|')+isnull(CONVERT([nvarchar](500),[ProjectDescription]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectParentKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectTypeKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectStatusKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectContractTypeKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[MainProjectKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[TeamKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[MunicipalityKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectStartDate],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectEndDate],(112)),''))+'|')+isnull(CONVERT([nvarchar](100),[CustomerContact]),''))+'|')+isnull(CONVERT([nvarchar](150),[CustomerContactEmail]),''))+'|')+isnull(CONVERT([nvarchar](255),[CustomerReference]),''))+'|')+isnull(CONVERT([nvarchar](30),[TenderId]),''))+'|')+isnull(CONVERT([nvarchar](30),[Archived]),''))+'|')+isnull(CONVERT([nvarchar](30),[Secure]),''))+'|')+isnull(CONVERT([nvarchar](30),[RestrictedReporting]),''))+'|')+isnull(CONVERT([nvarchar](30),[AllowExpenses]),''))+'|')+isnull(CONVERT([nvarchar](30),[AllowNonBillableExpenses]),''))+'|')+isnull(CONVERT([nvarchar](30),[CurrencyKey]),''))+'|')+isnull(CONVERT([nvarchar](255),[ProjectInsuranceNo]),''))+'|')+isnull(CONVERT([nvarchar](30),[AccessLevelName]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectRiskProfileKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[BidTypeKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectStageOutcomeKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[BidProbability]),''))+'|')+isnull(CONVERT([nvarchar](30),[BidSubmissionDate],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[BidStartDate],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[BidEndDate],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectStartDateEstimated],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectEndDateEstimated],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[Confidential]),''))+'|')+isnull(CONVERT([nvarchar](30),[InitiatingOpportunityKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[src_CreatedDate],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[BidClosedDate],(112)),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectRiskLevelKey]),''))+'|')+isnull(CONVERT([nvarchar](30),[SmallProject]),''))+'|')+isnull(CONVERT([nvarchar](30),[ProjectClosureRequested]),'')))),
	[Active]  AS (CONVERT([bit],case when CONVERT([date],getdate())>=[ProjectStartDate] AND CONVERT([date],getdate())<=isnull([ProjectEndDate],'2099-12-31') then (1) else (0) end)),
 CONSTRAINT [PK_project] PRIMARY KEY CLUSTERED 
(
	[ProjectKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

"@
Invoke-DbaQuery -SqlInstance sestovh110.sweco.se\swsql54p -Database SwecoCore -Query $query
Invoke-DbaQuery -SqlInstance sestovh111.sweco.se\swsql55p -Database SwecoCore -Query $query
Invoke-DbaQuery -SqlInstance defrads015.sweco.se\desql18p -Database SwecoCore -Query $query


##################################################################################################################################################
#Copy tables one time
##################################################################################################################################################

# swecocore.CoreData.EcoCurrency
$query = @"
SELECT 
    CurrencyKey, CurrencyCode, CurrencyName, Active, ReportCurrency, md_InsertedTime, md_InsertedBy, md_ChangedTime, 
    md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription 
FROM coredata.EcoCurrency
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoCurrency -Query $query -AutoCreateTable -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoCurrency -Query $query -AutoCreateTable -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoCurrency -Query $query -AutoCreateTable -KeepIdentity -Truncate

# swecocore.CoreData.Activity
$query = @"
SELECT 
    ActivityKey, ActivityNumber, ActivityName, ActivityType, ActivityGroup, Billable, src_ChangedBy, src_ChangedTime, md_InsertedTime, 
    md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.Activity
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.Activity -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.Activity -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.Activity -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.CoreData.EcoAccount 
$query = @"
SELECT 
    AccountKey, AccountchartKey, AccountId, MainAccountKey, AccountGroupProjectKey, AccountName, Active, IncludeInGroupAccounting, 
    ManualBookingsAllowed, src_ChangedBy, src_ChangedTime, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, 
    md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription, BudgetAccountID
FROM
    coredata.EcoAccount
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccount -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccount -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccount -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.CoreData.EcoAccountchart
$query = @"
SELECT 
    AccountchartKey, AccountchartId, AccountchartName, SystemId, ProjRecIncomeSign, ProjHoursSign, PLincomeProjSign, PLhoursSign, ProjCorrMovePeriodBack, PLselfcostProjSign, AdministratorEmployeeKey, Active, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoAccountchart
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccountchart -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccountchart -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccountchart -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.CoreData.EcoAccountGroupOperational
$query = @"
SELECT 
    AccountGroupOperationalKey, AccountGroupOperationalId, AccountGroupOperationalName, MainAccountGroupOperationalKey, BudgetOverview, md_InsertedTime, md_InsertedBy, 
    md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoAccountGroupOperational
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccountGroupOperational -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccountGroupOperational -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccountGroupOperational -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.CoreData.EcoMainAccount
$query = @"
SELECT 
    MainAccountKey, MainAccountId, MainAccountName, AccountGroupOperationalKey, Type, Note, OcraImportMultiplier, DisplayAccountId, src_ChangedBy, 
    src_ChangedTime, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, 
    md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoMainAccount
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoMainAccount -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoMainAccount -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoMainAccount -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.CoreData.EcoMainAccountGroupOperational
$query = @"
SELECT 
    MainAccountGroupOperationalKey, MainAccountGroupOperationalId, MainAccountGroupOperationalName, ApplyPLincomeProjSign, ApplyPLselfcostProjSign, 
    md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoMainAccountGroupOperational
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoMainAccountGroupOperational -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoMainAccountGroupOperational -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoMainAccountGroupOperational -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.CoreData.EcoMainAccountGroupProject
$query = @"
SELECT 
    MainAccountGroupProjectKey, MainAccountGroupProjectId, MainAccountGroupProjectName, ApplyProjRecIncomeSign, md_InsertedTime, 
    md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoMainAccountGroupProject
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoMainAccountGroupProject -Query $query  -AutoCreateTable -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoMainAccountGroupProject -Query $query  -AutoCreateTable -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoMainAccountGroupProject -Query $query  -AutoCreateTable -KeepIdentity -Truncate

# swecocore.CoreData.EcoTransactionType
$query = @"
SELECT 
    TransactionTypeKey, SourceSystemKey, TransactionTypeId, TransactionTypeName, md_InsertedTime, md_InsertedBy, 
    md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoTransactionType
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTransactionType -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTransactionType -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTransactionType -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.CoreData.EmploymentContractType
$query = @"
SELECT 
    EmploymentContractTypeKey, EmploymentContractTypeId, EmploymentContractTypeName, EmploymentContractTypeGroupId, 
    EmploymentContractTypeGroupName, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, 
    md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EmploymentContractType
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EmploymentContractType -Query $query  -AutoCreateTable -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EmploymentContractType -Query $query  -AutoCreateTable -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EmploymentContractType -Query $query  -AutoCreateTable -KeepIdentity -Truncate

# swecocore.CoreData.EmpPayType
$query = @"
SELECT 
    PayTypeKey, PayTypeId, PayTypeName, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EmpPayType
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EmpPayType -Query $query  -AutoCreateTable -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EmpPayType -Query $query  -AutoCreateTable -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EmpPayType -Query $query  -AutoCreateTable -KeepIdentity -Truncate

# swecocore.CoreData.LangCountry
$query = @"
SELECT 
    LangCountryKey, CountryKey, LanguageKey, CountryName, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.LangCountry
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.LangCountry -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.LangCountry -Query $query  -AutoCreateTable -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.LangCountry -Query $query  -AutoCreateTable -KeepIdentity -Truncate

# swecocore.CoreData.ProjectSecurityLevel
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.ProjectSecurityLevel -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.ProjectSecurityLevel -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.ProjectSecurityLevel -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.CoreData.ProjectTask
$query = @"
SELECT 
    ProjectTaskKey, ProjectKey, ProjectTaskCode, ProjectTaskName, src_ChangedTime, src_ChangedBy, md_InsertedTime, md_InsertedBy, 
    md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, 
    md_DqIssueDescription, ActivityNumber, AllowTime, AllowExpenses
FROM
    coredata.ProjectTask
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.ProjectTask -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.ProjectTask -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.ProjectTask -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.coredata.EcoAccountGroupProject
$query = @"
SELECT 
    AccountGroupProjectKey, AccountGroupProjectId, AccountGroupProjectName, MainAccountGroupProjectKey, md_InsertedTime, md_InsertedBy, 
    md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoAccountGroupProject
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccountGroupProject -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccountGroupProject -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoAccountGroupProject -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.coredata.project 
$query = @"
SELECT
    ProjectKey, CompanyId, ProjectNo, ProjectName, ProjectLevel, ProjectDescription, MainProjectKey, ProjectParentKey, ProjectTypeKey, 
    ProjectStatusKey, ProjectContractTypeKey, MunicipalityKey, TeamKey, ProjectStartDate, ProjectEndDate, CustomerContact, CustomerContactEmail, 
    CustomerReference, TenderId, Archived, Secure, RestrictedReporting, AllowExpenses, AllowNonBillableExpenses, CurrencyKey, ProjectInsuranceNo, 
    AccessLevelName, src_ChangedBy, src_ChangedTime, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, 
    md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription, ProjectRiskProfileKey, BidTypeKey, ProjectStageOutcomeKey, 
    BidProbability, BidSubmissionDate, BidStartDate, BidEndDate, ProjectStartDateEstimated, ProjectEndDateEstimated, Confidential, 
    InitiatingOpportunityKey, src_CreatedDate, BidClosedDate, ProjectRiskLevelKey, SmallProject, ProjectClosureRequested
FROM
    coredata.Project
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.Project -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.Project -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.Project -Query $query  -AutoCreateTable  -KeepIdentity -Truncate


# swecocore.coredata.SecurityLevel
$query = @"
SELECT 
    SecurityLevelKey, SecurityLevelCode, SecurityLevelName, SecurityLevelDescription, WorkspaceSecurityOptions, md_InsertedTime, md_InsertedBy, 
    md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId 
FROM
    coredata.SecurityLevel
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.SecurityLevel -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.SecurityLevel -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.SecurityLevel -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.coredata.accesrole
$query = @"
SELECT 
    AccessRoleKey, AccessRoleName, Description, AllowEditOrg, maxAssignmentsPerUnit, AccessLevelId, mandatoryAddonId, roleTypeAOL, 
    validFromDate, validToDate, src_ChangedTime, ChangedBy, md_InsertedTime, md_InsertedBy, md_ChangedTime, 
    md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.accessrole
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.accessrole -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.accessrole -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.accessrole -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.coredata.accessrestriction

$query = @"
SELECT 
    AccessRestrictionOptionKey, AccessRestrictionTypeKey, AccessRestrictionOptionName, AccessRestrictionoptionDescription, externalCode, 
    src_ChangedTime, src_ChangedBy, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, 
    md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.accessrestriction
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.accessrestriction -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.accessrestriction -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.accessrestriction -Query $query  -AutoCreateTable  -KeepIdentity -Truncate


#swecocore.coredata.accessrestrictiontype

$query = @"
SELECT 
    AccessRestrictionTypeKey, AccessRestrictionTypeName, src_ChangedTime, src_ChangedBy, md_InsertedTime, md_InsertedBy, md_ChangedTime, 
    md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.accessrestrictiontype
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.accessrestrictiontype -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.accessrestrictiontype -Query $query  -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.accessrestrictiontype -Query $query  -AutoCreateTable  -KeepIdentity -Truncate


##################################################################################################################################################
#Copy tables repeatedly
##################################################################################################################################################

# swecocore.CoreData.EcoExchangeRate 
$query = @"
SELECT 
    ExchangeRateKey, BaseCurrencyKey, ForeignCurrencyKey, RateDate, ExchangeRate, md_InsertedTime, md_InsertedBy, 
    md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, 
    md_DqIssueDescription, ExchangeRateCalculationMethodKey
FROM
    coredata.EcoExchangeRate
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoExchangeRate -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoExchangeRate -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoExchangeRate -Query $query  -AutoCreateTable  -KeepIdentity -Truncate


# swecocore.core.EcoTimecode #TBD more computed columns
$query = @"
SELECT 
    TimeCodeKey, TimeCodeId, TimeCodeName, IncludedInFTE, src_ChangedBy, src_ChangedTime, 
    md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, 
    md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoTimecode
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTimecode -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTimecode -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTimecode -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.dbo.EcoCurrencyRate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table dbo.EcoCurrencyRate -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table dbo.EcoCurrencyRate -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table dbo.EcoCurrencyRate -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.coredata.EcoWorkCalendar
$query = @"
SELECT 
    EcoWorkCalendarKey, CompanyId, WorkYearMonth, WorkTimeHours, ValueTypeKey, md_InsertedTime, md_InsertedBy, md_ChangedTime, 
    md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoWorkCalendar
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoWorkCalendar -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoWorkCalendar -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoWorkCalendar -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

#swecocore.CoreData.EcoTimerow
$query = @"
SELECT 
    TimeRowKey, SwecoTimecodeId, EmployeeCompanyId, EmployeeTeamKey, EmployeeKey, EmployeeTypeId, ProjectTaskKey, ProjectCompanyId, 
    ProjectTeamKey, ActivityNumber, OvertimeCode, InstanceKey, TimeDate, TimeWeek, TimeFiscalMonth, ValueTypeKey, OH, Hours, 
    Price, Cost, src_ChangedTime, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, 
    md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.EcoTimerow
WHERE
    --TimeRowKey > 136042944 AND 
    TimeFiscalMonth > 202312
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTimerow -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTimerow -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTimerow -Query $query  -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.coredata.EcoTransaction 
$query = @"
SELECT 
    TransactionKey, CompanyId, TransactionDate, VoucherId, AccountId, TeamKey, ProjectKey, InterCompanyId, EmployeeKey, 
    Amount, Count, Text, ValueTypeKey, LegacyAccountId, TaskName, ActivityNumber, InstanceKey, PostedBy, src_ChangedTime, 
    md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, 
    md_LoadJobId, md_DqLevel, md_DqIssueDescription, CounterpartTeamKey, TransactionTypeKey
FROM
    coredata.EcoTransaction
WHERE
    -- TransactionKey > 1152839687 AND 
    TransactionDate > '2023-12-31'
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTransaction -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTransaction -Query $query -AutoCreateTable  -KeepIdentity -Truncate

$query = @"
SELECT 
    TransactionKey, CompanyId, TransactionDate, VoucherId, AccountId, TeamKey, ProjectKey, InterCompanyId, EmployeeKey, 
    Amount, Count, Text, ValueTypeKey, LegacyAccountId, TaskName, ActivityNumber, InstanceKey, PostedBy, src_ChangedTime, 
    md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, md_RowState, md_SourceId, md_StgRowId, 
    md_LoadJobId, md_DqLevel, md_DqIssueDescription, CounterpartTeamKey, TransactionTypeKey
FROM
    coredata.EcoTransaction
WHERE
    -- TransactionKey > 1152839687 AND 
    TransactionDate > '2023-12-31'
	and CompanyId = 710
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.EcoTransaction -Query $query -AutoCreateTable  -KeepIdentity -Truncate

# swecocore.coredata.ecovaluetype

$query = @"
SELECT 
    ValueTypeKey, ValueTypeId, ValueTypeName, md_InsertedTime, md_InsertedBy, md_ChangedTime, md_ChangedBy, md_RowVersion, 
    md_RowState, md_SourceId, md_StgRowId, md_LoadJobId, md_DqLevel, md_DqIssueDescription
FROM
    coredata.ecovaluetype
"@
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh110.sweco.se\swsql54p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.ecovaluetype -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination sestovh111.sweco.se\swsql55p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.ecovaluetype -Query $query -AutoCreateTable  -KeepIdentity -Truncate
Copy-DbaDbTableData -SqlInstance coreprod.sql.sweco.se -Destination defrads015.sweco.se\desql18p -Database swecocore -DestinationDatabase SwecoCore -Table coredata.ecovaluetype -Query $query -AutoCreateTable  -KeepIdentity -Truncate
