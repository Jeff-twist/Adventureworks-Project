select * from [Production].[Product];
select * from [Production].[WorkOrder];
select * from [Purchasing].[PurchaseOrderDetail];
select * from [Purchasing].[PurchaseOrderHeader];
select * from [Purchasing].[Vendor];
select * from [Sales].[Customer];
select * from [Sales].[SalesOrderDetail];
select * from [Sales].[SalesOrderHeader];
select * from [Sales].[SalesPerson];
select * from [Sales].[SalesTerritory];
--------------------------------------------------------------------------------------------------------------------------------------------------------

-- Cleaning the Weight column
select distinct Weight from [Production].[Product]
where Weight > 50;
 - Then convert the Weight column to have all in KG
UPDATE [Production].[Product]
SET Weight = (
round(CASE
WHEN Weight is NULL then 0
when Weight > 50 THEN cast(weight/453.59 AS DECIMAL(10, 2))
else Weight
END,2))
from [Production].[Product]
 - checking the result
select distinct weight from [Production].[Product]

----------------------------------------------------------------------------------------------------------------------------------------------------------

-- What are the most popular products among customers ?
SELECT TOP 10
Product.Name AS ProductName,
SUM(SalesOrderDetail.OrderQty) QuantitySold
FROM Sales.SalesOrderDetail SalesOrderDetail
JOIN Production.Product AS Product
ON SalesOrderDetail.ProductID = Product.ProductID
GROUP BY Product.Name
ORDER BY QuantitySold DESC;

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Which Geographical regions generate the most sales ?
SELECT SalesTerritory.[Group] GeographicRegion,
ROUND(SUM(SalesOrderHeader.TotalDue), 2) TotalRegionSales
FROM Sales.SalesOrderHeader SalesOrderHeader
JOIN Sales.Customer Customer
ON SalesOrderHeader.CustomerID = Customer.CustomerID
JOIN Sales.SalesTerritory SalesTerritory
ON SalesOrderHeader.TerritoryID = SalesTerritory.TerritoryID
GROUP BY SalesTerritory.[Group]
ORDER BY TotalRegionSales DESC;
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
 - How has sales volume changed over time?
SELECT YEAR(OrderDate) Year,
ROUND(SUM(TotalDue), 2) Sales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY Year;

-----------------------------------------------------------------------------------------------------------------------------------------------------

-- Which customer segments generate the most revenue?
SELECT CASE WHEN Customer.AccountNumber LIKE 'AW%' THEN 'A'
WHEN Customer.AccountNumber LIKE 'CB%' THEN 'C'
ELSE 'B'
END AS CustomerSegment,
SUM(SalesOrderHeader.TotalDue) Revenue
FROM Sales.SalesOrderHeader SalesOrderHeader
JOIN Sales.Customer Customer
ON SalesOrderHeader.CustomerID = Customer.CustomerID
GROUP BY CASE WHEN Customer.AccountNumber LIKE 'AW%' THEN 'A'
WHEN Customer.AccountNumber LIKE 'CB%' THEN 'C'
ELSE 'B'
END
ORDER BY Revenue DESC;

-- Checking for changes
SELECT COUNT(DISTINCT
CASE
WHEN Customer.AccountNumber LIKE 'AW%' THEN 'A'
WHEN Customer.AccountNumber LIKE 'CB%' THEN 'C'
ELSE 'B'
END) UniqueCustomerSegments
FROM Sales.SalesOrderHeader SalesOrderHeader
JOIN Sales.Customer Customer
ON SalesOrderHeader.CustomerID = Customer.CustomerID;

-------------------------------------------------------------------------------------------------------------------------------------------------------

-- Which salespeople are the most successful?
SELECT sp.BusinessEntityID,
ROUND(SUM(soh.TotalDue), 2) Sales,
sp.SalesQuota
FROM Sales.SalesPerson sp
JOIN Sales.SalesOrderHeader soh
ON sp.BusinessEntityID = soh.SalesPersonID
GROUP BY sp.BusinessEntityID, sp.SalesQuota
ORDER BY Sales DESC;

------------------------------------------------------------------------------------------------------------------------------------------------------

-- How does sales performance vary by geographic region?
SELECT ST.Name SalesTerritory,
SUM(SOH.TotalDue) Sales
FROM
Sales.SalesOrderHeader SOH
JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
JOIN Sales.SalesPerson SP ON SOH.SalesPersonID = SP.BusinessEntityID
JOIN Sales.SalesTerritory ST ON SP.TerritoryID = ST.TerritoryID
GROUP BY ST.Name
ORDER BY Sales DESC;

-------------------------------------------------------------------------------------------------------------------------------------------------------

-- Are there any correlations between salesperson characteristics and performance?
SELECT sp.TerritoryID,
sp.SalesQuota,
SUM(soh.TotalDue) Sales
FROM Sales.SalesPerson sp
JOIN Sales.SalesOrderHeader soh ON sp.BusinessEntityID = soh.SalesPersonID
WHERE sp.TerritoryID is not null
GROUP BY sp.TerritoryID,
sp.SalesQuota
ORDER BY Sales DESC;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- Which territories generate the most revenue?
SELECT st.TerritoryID,
st.Name Region, ROUND(SUM(soh.TotalDue), 2) Revenue
FROM Sales.SalesTerritory st
JOIN Sales.SalesOrderHeader soh ON st.TerritoryID = soh.TerritoryID
GROUP BY st.TerritoryID, st.Name
ORDER BY Revenue DESC;

----------------------------------------------------------------------------------------------------------------------------------------------------

-- What are the most profitable products?
SELECT TOP 10 p.Name ProductName,
SUM(od.LineTotal) Sales,
SUM(od.LineTotal - (od.OrderQty * p.StandardCost)) Profit,
(SUM(od.LineTotal - (od.OrderQty * p.StandardCost)) / SUM(od.LineTotal)) * 100 ProfitMargin
FROM Sales.SalesOrderDetail od
JOIN Production.Product p ON od.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY ProfitMargin DESC;

-------------------------------------------------------------------------------------------------------------------------------------

-- Are there any patterns or trends in product sales over time?
SELECT CONVERT(date, MAX(Sales.SalesOrderHeader.OrderDate)) MaxOrderDate,
YEAR(Sales.SalesOrderHeader.OrderDate) Year,
MONTH(Sales.SalesOrderHeader.OrderDate) Month,
SUM(Sales.SalesOrderDetail.LineTotal) Sales
FROM Sales.SalesOrderHeader
JOIN Sales.SalesOrderDetail ON Sales.SalesOrderHeader.SalesOrderID = Sales.SalesOrderDetail.SalesOrderID
GROUP BY YEAR(Sales.SalesOrderHeader.OrderDate), MONTH(Sales.SalesOrderHeader.OrderDate)
ORDER BY Year, Month;

---------------------------------------------------------------------------------------------------------------------------------------

-- How does product popularity vary by geographic region?
SELECT TOP 10 st.Name Region,
p.Name ProductName,
SUM(od.OrderQty) TotalQuantitySold
FROM Sales.SalesOrderDetail od
JOIN Production.Product p ON od.ProductID = p.ProductID
JOIN Sales.SalesOrderHeader oh ON od.SalesOrderID = oh.SalesOrderID
JOIN Sales.SalesTerritory st ON oh.TerritoryID = st.TerritoryID
GROUP BY p.Name, st.Name
ORDER BY TotalQuantitySold DESC;

----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Suppliers performance by sales
SELECT top 10 v.Name VendorName,
COUNT(DISTINCT po.PurchaseOrderID) TotalOrders,
SUM(pod.OrderQty * pod.UnitPrice) TotalSales
FROM Production.Product p
JOIN Production.ProductSubcategory psub ON psub.ProductSubcategoryID = p.ProductSubcategoryID
JOIN Production.ProductCategory pc ON pc.ProductCategoryID = psub.ProductCategoryID
JOIN Purchasing.PurchaseOrderDetail pod ON pod.ProductID = p.ProductID
JOIN Purchasing.PurchaseOrderHeader po ON po.PurchaseOrderID = pod.PurchaseOrderID
JOIN Purchasing.Vendor v ON v.BusinessEntityID = po.VendorID
GROUP BY pc.Name, v.Name
ORDER BY TotalSales DESC;

-----------------------------------------------------------------------------------------------------------------------------------------

-- Total Revenue by Order Year and Quarter
SELECT YEAR(OrderDate) Year, DATEPART(QUARTER, OrderDate) QuarterlyOrder, SUM(TotalDue) Revenue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
ORDER BY YEAR, QuarterlyOrder;