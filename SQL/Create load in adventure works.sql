

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
	Sales.SalesOrderHeader AS soh -- WITH (HOLDLOCK TABLOCKX)
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


SELECT * 
FROM 
	Sales.SalesOrderHeader soh
	inner join Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
	inner join @TableVar tv ON soh.SalesOrderID = NewSalesOrderID

GO 5


