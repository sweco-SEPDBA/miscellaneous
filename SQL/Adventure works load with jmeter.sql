DECLARE @IdNum AS INT
DECLARE @MaxNum AS INT
SELECT @MaxNum=MAX(SalesOrderId) FROM sales.SalesOrderDetail  WITH(NOLOCK)
SELECT @IdNum =FLOOR(RAND()*(@MaxNum-43659)+43659)
 
 
IF @IdNum%5 =0 
BEGIN
print '0'
select * from sales.SalesOrderDetail where SalesOrderID=@IdNum
END
 
IF @IdNum%5 =1
BEGIN
print '1'
DELETE FROM sales.SalesOrderDetail where SalesOrderID=@IdNum
END
IF @IdNum%5 =2
BEGIN
print '2'
INSERT INTO sales.SalesOrderDetail 
(  SalesOrderID,[CarrierTrackingNumber]
        ,[OrderQty]
        ,[ProductID]
        ,[SpecialOfferID]
        ,[UnitPrice]
        ,[UnitPriceDiscount]
        
        ,[rowguid]
        ,[ModifiedDate])
    SELECT 
    (  SELECT MAX(SalesOrderID) FROM [Sales].[SalesOrderHeader]),
        [CarrierTrackingNumber]
        ,[OrderQty]
        ,[ProductID]
        ,[SpecialOfferID]
        ,[UnitPrice]
        ,[UnitPriceDiscount]
        
        ,NEWID()
        ,[ModifiedDate]
    FROM [Sales].[SalesOrderDetail]
    where SalesOrderID=@IdNum
END
 
IF @IdNum%5 =3
BEGIN
print '3'
	UPDATE [Sales].[SalesOrderDetail] SET OrderQty=OrderQty*5 , UnitPrice =UnitPrice*5  where SalesOrderID=@IdNum
END

IF @IdNum%5 =4
BEGIN	
	DECLARE @TableVar TABLE
	(OrigSalesOrderID int, NewSalesOrderID int)
	
	INSERT INTO Sales.SalesOrderHeader
		(RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, 
		 PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, 
		 BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, 
		 CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight, Comment, 
		 rowguid, ModifiedDate)
	OUTPUT inserted.Comment, inserted.SalesOrderID
		INTO @TableVar
	SELECT TOP 1 
		RevisionNumber, 
		GETDATE() AS OrderDate, 
		DATEADD(dd, 10, GETDATE()) DueDate,  
		DATEADD(dd, 7, GETDATE()) ShipDate, 
		[Status], 
		OnlineOrderFlag, 
		PurchaseOrderNumber, 
		AccountNumber, 
		CustomerID, 
		SalesPersonID, 
		TerritoryID, 
		BillToAddressID, 
		ShipToAddressID, 
		ShipMethodID, 
		CreditCardID, 
		CreditCardApprovalCode, 
		CurrencyRateID, 
		SubTotal, 
		TaxAmt, 
		Freight, 
		SalesOrderID Comment, 
		NEWID() rowguid, 
		GETDATE() ModifiedDate
	FROM 
		Sales.SalesOrderHeader AS soh TABLESAMPLE (1000 ROWS)
	ORDER BY NEWID()
	
	INSERT INTO Sales.SalesOrderDetail
		(SalesOrderID, CarrierTrackingNumber, OrderQty, ProductID, 
		 SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
	SELECT 
		tv.NewSalesOrderID, CarrierTrackingNumber, OrderQty, ProductID, 
		SpecialOfferID, UnitPrice, UnitPriceDiscount, NEWID(), ModifiedDate 
	FROM Sales.SalesOrderDetail AS sod
	JOIN @TableVar AS tv
		ON sod.SalesOrderID = tv.OrigSalesOrderID
	ORDER BY sod.SalesOrderDetailID
END