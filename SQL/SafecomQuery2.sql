declare @dt1 DateTime;
declare @dt2 DateTime;

--set @dt1= '2013-07-01 00:00:00.000'
--set @dt2= '2013-07-30 23:59:59.000'  

set @dt1 = {ts '2021-11-02 00:00:00'};
set @dt2 = {ts '2021-11-02 23:59:59'};


declare @TS varchar(50)
--SET @TS='All'
SET @TS='Completed'



declare @jt_str nvarchar(20);
--set @jt_str = 'Paper';
set @jt_str = 'All';


declare @p varchar(20)

--set @p= 'All'
set @p= 'All'
IF @p='All' set @p= ''


declare @UsrN varchar(3)

--SET @UsrN='Yes'
SET @UsrN='No'

declare @jt1 int; set @jt1 = 0;
declare @jt2 int; set @jt2 = 0;
declare @jt3 int; set @jt3 = 0;
declare @jt4 int; set @jt4 = 0;
declare @jt5 int; set @jt5 = 0;
declare @jt6 int; set @jt6 = 0;
declare @jt7 int; set @jt7 = 0;
declare @jt8 int; set @jt8 = 0;
declare @jt9 int; set @jt9 = 0;
declare @jt10 int; set @jt10 = 0;
declare @jt11 int; set @jt11 = 0;
declare @jt12 int; set @jt12 = 0;

if @jt_str = 'All'
begin
  set @jt1 = 1;
  set @jt2 = 2;
  set @jt3 = 3;
  set @jt4 = 4;
  set @jt5 = 5;
  set @jt6 = 6;
 set @jt10 = 10;
 set @jt11 = 11;
 set @jt12 = 12;
end
else if @jt_str = 'Paper'
begin
  set @jt1 = 1;
  set @jt2 = 2;
  set @jt3 = 3;
 set @jt10 = 10;
 set @jt11 = 11;
 set @jt12 = 12;
end
else if @jt_str = 'Paperless'
begin
  set @jt1 = 0;
  set @jt2 = 0;
  set @jt3 = 0;
  set @jt4 = 4;
  set @jt5 = 5;
  set @jt6 = 6;
end
else if @jt_str = 'Pull/Push Print'
begin
  set @jt1 = 1;
  set @jt2 = 2;
  set @jt11 = 11;
  set @jt12 = 12;
end
else if @jt_str = 'Offline'
begin
  set @jt11 = 11;
  set @jt12 = 12;
end
else if @jt_str = 'Pull'
begin
  set @jt2 = 2;
  set @jt12 = 12;
end
else if @jt_str = 'Push'
begin
  set @jt1 = 1;
  set @jt11 = 11;
end
else if @jt_str = 'Copy'
begin
  set @jt3 =3;
end
else if @jt_str = 'Fax'
begin
  set @jt4 = 4;
end
else if @jt_str = 'Scan'
begin
  set @jt5 = 5;
end
else if @jt_str = 'E-mail'
begin
  set @jt6 = 6;
end
else if @jt_str = 'Deleted'
begin
  set @jt7 = 7;
  set @jt8 = 8;
  set @jt9 = 9;
end
else if @jt_str = 'System-deleted'
begin
  set @jt7 = 7;
end
else if @jt_str = 'User-deleted'
begin
  set @jt8 = 8;
end
else if @jt_str = 'RBP-deleted'
begin
  set @jt9 = 9;
end
else if @jt_str = 'USB Print'
begin
  set @jt10 = 10;
end
else if @jt_str = 'Offline Push'
begin
  set @jt11 = 11;
end
else if @jt_str = 'Offline Pull'
begin
  set @jt12 = 12;
end



use sccore
--==================================================================================
-- User Info
--==================================================================================
 --GOAL: TABLE WITH ALL USERS (CC= trk.latest OR sccore.current)
If Exists(Select * from tempdb..sysobjects Where id = object_id('tempdb.dbo.#TAB_USERS'))
         DROP TABLE #TAB_USERS

	select LU.UserId as UsrId, 
	trk.UserLogon as UsrLogon, 
	trk.UserFullName as UsrFullName, 	
	UserCostCode as FinalCC, 
	1 as UsrDeleted
into [#TAB_USERS] 
	from 
	sctracking.dbo.sctrkrepview TRK WITH (READPAST),
		(
    select 
      UserId, 
      max(trackingid) as LatTkId
    from sctracking.dbo.sctrkrepview WITH(READPAST)
where StartDateTime between @dt1 and @dt2
    group by UserID
  ) LU
	where 
		TRK.TrackingId = LU.LatTkId and TRK.UserId=LU.UserId;

-----------------------------------------------
-- GET: Current user info (CC) from scCore
-----------------------------------------------
update #TAB_USERS
	set		FinalCC=U.CostCode, UsrDeleted=0, UsrFullName=U.FullName
	from	sccore.dbo.scUserInfo U WITH (READPAST)
	where	UsrId = U.UserId;

--select * from @TAB_USERS order by usrlogon



--==================================================================================
-- Device Info
--==================================================================================
-- TABLE: ALL DEVICES (with trk.latest or sccore.current info)
If Exists(Select * from tempdb..sysobjects Where id = object_id('tempdb.dbo.#TAB_DEVS'))
         DROP TABLE #TAB_DEVS


	select 
	Trk.DeviceId as DevId, 
	DeviceName as DevName, 
	DeviceLocation as DevLoc, 
	1 as DevDeleted 
into [#TAB_DEVS] 
	--,DeviceLocation
	from 
		sctracking.dbo.sctrkrepview TRK WITH (READPAST),
		(
    select 
      DeviceId, 
      max(trackingid) as LatTkId
    from sctracking.dbo.sctrkrepview WITH(READPAST)
where StartDateTime between @dt1 and @dt2
    group by DeviceId
  ) LD
	where 
		TRK.TrackingId = LD.LatTkId and TRK.DeviceId=LD.DeviceId; 

		
-----------------------------------------------
-- GET: Current device info (CC) from scCore
-----------------------------------------------
-- Insert scCore.Current
--update @TAB_DEVS
update #TAB_DEVS
	set		DevName=D.Name, DevDeleted=0 --,DevLoct=D.Location 
	from	sccore.dbo.scDeviceInfo D WITH (READPAST)
	where	DevId = D.DeviceId;


--select * from @TAB_DEVS order by DevId		

--use sctracking;	


IF @UsrN='No'
		select
			T.DeviceId,
			D.DevName as DeviceName,
			D.DevLoc as DeviceLocation,			
			U.UsrLogon as UserLogon,
			COUNT(T.TrackingId)			as Jobs,
			SUM(T.TrackingPageCount)	as Pages,
			SUM(T.TrackingColorPageCount
			  *(1-T.JobIsDuplex))		as ColorSpx,
			SUM(T.TrackingColorPageCount
			  *(T.JobIsDuplex))			as ColorDpx,
			SUM((T.TrackingPageCount-
			  T.TrackingColorPageCount)
			  *(1-T.JobIsDuplex))		as MonoSpx,
			SUM((T.TrackingPageCount-
			  T.TrackingColorPageCount)
			  *(T.JobIsDuplex))			as MonoDpx,
			CAST(SUM(T.Price) as money)	as Price
			--,D.DevDeleted as DeviceIsDeleted,
			--U.UsrDeleted as UserIsDeleted
		from 
			sctracking.dbo.sctrkrepview	T WITH (READPAST),
			--@TAB_DEVS	D,		
			--@TAB_USERS	U
			#TAB_DEVS	D,		
			#TAB_USERS	U			
		where	T.DeviceId  = D.DevId
			and T.UserID = U.UsrID
			and T.TrackingState = ( CASE @TS
                WHEN 'Completed' THEN 2 
                WHEN 'Interrupted'  THEN 1 
                ELSE T.TrackingState
                END )
			and T.StartDateTime between @dt1 and @dt2
			and T.JobType in (@jt1,@jt2,@jt3,@jt4,@jt5,@jt6,@jt7,@jt8,@jt9,@jt10,@jt11,@jt12)
and DeviceId = D.DevId					
and JobPageFormat =
CASE WHEN len(@p)=0 THEN JobPageFormat
WHEN @p like '%'+isnull((select LEFT(JobPageFormat,2) where LEFT(JobPageFormat,2)='LF'),JobPageFormat)+'%' THEN JobPageFormat
END 
		group by
			D.DevLoc,
			T.DeviceId,
			U.UsrLogon,
			D.DevName
			--,D.DevDeleted,
			--U.UsrDeleted;
ELSE
		select
			T.DeviceId,
			D.DevName as DeviceName,
			D.DevLoc as DeviceLocation,			
			U.UsrFullName as UserLogon,
			COUNT(T.TrackingId)			as Jobs,
			SUM(T.TrackingPageCount)	as Pages,
			SUM(T.TrackingColorPageCount
			  *(1-T.JobIsDuplex))		as ColorSpx,
			SUM(T.TrackingColorPageCount
			  *(T.JobIsDuplex))			as ColorDpx,
			SUM((T.TrackingPageCount-
			  T.TrackingColorPageCount)
			  *(1-T.JobIsDuplex))		as MonoSpx,
			SUM((T.TrackingPageCount-
			  T.TrackingColorPageCount)
			  *(T.JobIsDuplex))			as MonoDpx,
			CAST(SUM(T.Price) as money)	as Price
			--,D.DevDeleted as DeviceIsDeleted,
			--U.UsrDeleted as UserIsDeleted
		from 
			sctracking.dbo.sctrkrepview	T WITH (READPAST),
			--@TAB_DEVS	D,		
			--@TAB_USERS	U
			#TAB_DEVS	D,		
			#TAB_USERS	U			
		where	T.DeviceId  = D.DevId
			and T.UserID = U.UsrID
			and T.TrackingState = ( CASE @TS
                WHEN 'Completed' THEN 2 
                WHEN 'Interrupted'  THEN 1 
                ELSE T.TrackingState
                END )
			and T.StartDateTime between @dt1 and @dt2
			and T.JobType in (@jt1,@jt2,@jt3,@jt4,@jt5,@jt6,@jt7,@jt8,@jt9,@jt10,@jt11,@jt12)
and DeviceId = D.DevId					
and JobPageFormat =
CASE WHEN len(@p)=0 THEN JobPageFormat
WHEN @p like '%'+isnull((select LEFT(JobPageFormat,2) where LEFT(JobPageFormat,2)='LF'),JobPageFormat)+'%' THEN JobPageFormat
END 
		group by
			D.DevLoc,
			T.DeviceId,
			U.UsrFullName,
			D.DevName
			--,D.DevDeleted,
			--U.UsrDeleted;


If Exists(Select * from tempdb.sys.objects Where name like '%TAB_USERS%') 
BEGIN
declare @sql nvarchar(max)
 select @sql = isnull(@sql+';',' ') + 'drop table ' + quotename(name)
 from tempdb..sysobjects
 where name like '#tab_users%'
 --SELECT @sql
 exec (@sql)
END

         DROP TABLE [#TAB_DEVS]