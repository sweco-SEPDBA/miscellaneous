
-- LANSweeper
-- Global Database server: SWSQL42P.sql.sweco.se
-- Database: lansweeperdb


-- Used by DE for cost allocation
-- Contact: Pierre Karlsson, Daniel Mille
-- Created: 2024-06-18
-- Hardware - Get list of PC
CREATE VIEW DE_HW AS 
select
	ta.AssetID AssetID,
	ta.AssetName PCNR,
	ta.Username 'Login',  
	ta.IPAddress IP,
	ta.Mac MACAdres,
	ta.Firstseen Firstseen,
	ta.Lastseen Lastseen,
	cast (ta.Memory as varchar) RAM,
	ta.Processor Prozessor,
	ta.BuildNumber BuildNumber,
	ta.Version BSystemVersion,
	loc.IPLocation Location,
	tac.PurchaseDate Lieferdatum,
	tac.Warrantydate Frist,
	tac.Manufacturer Hersteller,
	tac.Model Modell,
	tac.Serialnumber Seriennummer,
	tac.SystemSKU Produktcode,
	op.Caption BSystem,
	op.Version BSVersion
from 
	tblAssets ta
	INNER JOIN tblADusers tu On tu.Username = ta.Username
	LEFT JOIN tblAssetCustom tac on ta.AssetID=tac.AssetID
	LEFT JOIN tsysIPLocations loc on ta.LocationID=loc.LocationID
	LEFT JOIN tblOperatingsystem op on ta.AssetID=op.AssetID
where 
	ta.Assettype=-1
	AND tu.Division LIKE 'DE%'
	AND tac.State = 1; 
GO

--Hardware - Get list of of Monitors
--CREATE VIEW DE_Monitors AS
select
	ta.Assettype,
	ta.AssetID AssetID,
	tac.Serialnumber MONNR,
	ta.Firstseen Firstseen, 
	ta.Lastseen Lastseen,
	tac.Manufacturer Hersteller, 
	tac.Model MonitorModell,
	tac.Serialnumber Seriennummer
from 
	tblAssets ta
	INNER JOIN tblADusers tu On tu.Username = ta.Username
	LEFT JOIN tblAssetCustom tac on ta.AssetID=tac.AssetID
where 
	ta.Assettype=208 -- 208 is monitor but no monitors in asset table
	--AND tu.Country = 'Germany'
	AND tu.Division LIKE 'DE%'

--SELECT *  FROM [lansweeperdb].[dbo].[tsysAssetTypes]
-- 208=Monitor 


--Hardware - Get Relation between PC & Monitor
--CREATE VIEW DE_PC_Monitor AS
select 
	apc.AssetName PCNR,
	amon.Assetid MON_ID
from 
	tblAssets apc
	INNER JOIN tblADusers tu On tu.Username = apc.Username
	INNER JOIN tblAssetRelations ar ON apc.AssetID=ar.ParentAssetID --Asset relations empty
	INNER JOIN tblAssets amon ON amon.AssetID=ar.ChildAssetID
where 
	apc.Assettype=-1
	and amon.Assettype=208 -- No monitors in asset table
	--AND tu.Country = 'Germany'
	AND tu.Division LIKE 'DE%';
GO

-- Used by DE for cost allocation
-- Contact: Pierre Karlsson, Daniel Mille
-- Created: 2024-06-18
-- Software - Get Software
CREATE VIEW DE_SW AS
with tsx as (
select 
	ts.softID, 
	count(*) anzahl 
from 
	tblSoftware ts 
	INNER JOIN tblAssets ta ON ts.AssetID=ta.AssetID 
	INNER JOIN tblADusers tu On tu.Username = ta.Username
WHERE
	--AND tu.Country = 'Germany'
	tu.Division LIKE 'DE%'
	
group by ts.softID
)
select 
	tsu.softId id, 
	tsu.softwarename software,
	tsu.softwarepublisher anbieter,
	tsu.Added datum,
	tsx.anzahl anzahl
from 
	tblSoftwareUni tsu
	INNER JOIN  tsx on tsu.SoftID =tsx.softID
GO


-- Used by DE for cost allocation
-- Contact: Pierre Karlsson, Daniel Mille
-- Created: 2024-06-18 
--Software - Get Releation between software and PC
CREATE VIEW DE_PC_Software AS
Select distinct 
	ta.AssetName as pcnr,
	tsu.SoftID
From 
	tblSoftwareUni tsu 
	INNER JOIN tblSoftware ts ON ts.softID = tsu.SoftID
	INNER JOIN tblAssets ta ON ts.AssetID=ta.AssetID
	INNER JOIN tblADusers tu On tu.Username = ta.Username
where 
	tu.Division LIKE 'DE%'

DROP VIEW DE_PC_Software

GO
--tsu.SoftID In ({ids})


-- Used by DE for cost allocation
-- Contact: Pierre Karlsson, Daniel Mille
-- Created: 2024-06-18 
--Software - Get Releation between software and PC
CREATE VIEW DE_PC_Software AS
select  
	tsu.softId id,
	tsu.softwarename software,
	tsu.softwarepublisher anbieter,
	ta.AssetName
from 
	tblSoftwareUni tsu 
	INNER JOIN tblSoftware ts ON tsu.SoftID =ts.softID 
	INNER JOIN tblAssets ta ON ts.AssetID=ta.AssetID
	INNER JOIN tblADusers tu On tu.Username = ta.Username
where 
	tu.Division LIKE 'DE%'
GO


Select Top (1000) tblAssets.AssetID,
  tblAssets.AssetName,
  tblAssetCustom.Serialnumber,
  Coalesce(tsysOS.Image, tsysAssetTypes.AssetTypeIcon10) As icon,
  tblSoftwareUni.softwareName As Software,
  tblSoftware.softwareVersion As Version,
  (Select Case tblSoftware.MsStore
        When 0 Then 'Desktop app'
        Else 'Microsoft Store app'
      End) As 'Type',
  tblSoftwareUni.SoftwarePublisher As Publisher,
  tblAssets.Username,
  tblADusers.Division,
  tblAssets.Lastseen
From tblAssets
  Inner Join tblAssetCustom On tblAssets.AssetID = tblAssetCustom.AssetID
  Inner Join tsysAssetTypes On tsysAssetTypes.AssetType = tblAssets.Assettype
  Inner Join tsysIPLocations On tsysIPLocations.LocationID =
      tblAssets.LocationID
  Inner Join tblState On tblState.State = tblAssetCustom.State
  Inner Join tblSoftware On tblAssets.AssetID = tblSoftware.AssetID
  Inner Join tblSoftwareUni On tblSoftwareUni.SoftID = tblSoftware.softID
  Left Outer Join tsysOS On tsysOS.OScode = tblAssets.OScode
  Left Join tblADusers On tblADusers.Username = tblAssets.Username
Where 
	tblADusers.Division LIKE 'DE%'
	--tblADusers.Division = 'FIWE' 
	And tblState.Statename = 'Active'
Order By tblAssets.Domain,
  tblAssets.AssetName,
  Software

