--*************************************************************************--
-- Title: Assignment07
-- Desc: This file demonstrates how to use Functions
-- Change Log: When,Who,What
-- 2026-06-03,LThurgood,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_LThurgood')
	 Begin 
	  Alter Database [Assignment07DB_LThurgood] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_LThurgood;
	 End
	Create Database Assignment07DB_LThurgood;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment07DB_LThurgood;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count], [ReorderLevel]) -- New column added this week
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock, ReorderLevel
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10, ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, abs(UnitsInStock - 10), ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go


-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
go
Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
go
Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
go
Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
go
Select * From vProducts;
go
Select * From vEmployees;
go
Select * From vInventories;
go

/********************************* Questions and Answers *********************************/
Print
'NOTES------------------------------------------------------------------------------------ 
 1) You must use the BASIC views for each table.
 2) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'
-- Question 1 (5% of pts):
-- Show a list of Product names and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the product name.

/*
-- FORMAT() turns UnitPrice into a USD string like "$15.00".
*/

SELECT P.ProductName,
       [UnitPrice] = FORMAT(P.UnitPrice, 'C', 'en-us')
  FROM dbo.vProducts AS P
  ORDER BY P.ProductName;
GO

-- Question 2 (10% of pts): 
-- Show a list of Category and Product names, and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the Category and Product.

/*
-- Q1 with the Category join added.
*/

SELECT C.CategoryName,
       P.ProductName,
       [UnitPrice] = FORMAT(P.UnitPrice, 'C', 'en-us')
  FROM dbo.vCategories AS C
  JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
  ORDER BY C.CategoryName, P.ProductName;
GO

-- Question 3 (10% of pts): 
-- Use functions to show a list of Product names, each Inventory Date, and the Inventory Count.
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

/*
-- FORMAT() with 'MMMM, yyyy' gets us "January, 2017".
-- Order by the underlying date, not the formatted string. Sorting the string would
-- alphabetize the months (Feb, Jan, Mar) which isn't what we want.
-- Rename [Count] to InventoryCount to match the answer key header.
*/

SELECT P.ProductName,
       [InventoryDate] = FORMAT(I.InventoryDate, 'MMMM, yyyy'),
       [InventoryCount] = I.[Count]
  FROM dbo.vProducts AS P
  JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
  ORDER BY P.ProductName, I.InventoryDate;
GO

-- Question 4 (10% of pts): 
-- CREATE A VIEW called vProductInventories. 
-- Shows a list of Product names, each Inventory Date, and the Inventory Count. 
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

/*
-- Wrap Q3 in a view. TOP is in there so the view's ORDER BY is legal.
*/

GO
CREATE VIEW dbo.vProductInventories WITH SCHEMABINDING AS
 SELECT TOP (1000000000)
   P.ProductName,
   [InventoryDate] = FORMAT(I.InventoryDate, 'MMMM, yyyy'),
   [InventoryCount] = I.[Count]
  FROM dbo.vProducts AS P
  JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
  ORDER BY P.ProductName, I.InventoryDate;
GO

-- Check that it works: Select * From vProductInventories;
go

-- Question 5 (10% of pts): 
-- CREATE A VIEW called vCategoryInventories. 
-- Shows a list of Category names, Inventory Dates, and a TOTAL Inventory Count BY CATEGORY
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

/*
-- Three-way join, then SUM the Count grouped by Category and Date for the per-category total.
-- Answer key calls the total column InventoryCountByCategory.
*/

GO
CREATE VIEW dbo.vCategoryInventories WITH SCHEMABINDING AS
 SELECT TOP (1000000000)
   C.CategoryName,
   [InventoryDate] = FORMAT(I.InventoryDate, 'MMMM, yyyy'),
   [InventoryCountByCategory] = SUM(I.[Count])
  FROM dbo.vCategories AS C
  JOIN dbo.vProducts AS P ON C.CategoryID = P.CategoryID
  JOIN dbo.vInventories AS I ON P.ProductID = I.ProductID
  GROUP BY C.CategoryName, I.InventoryDate
  ORDER BY C.CategoryName, I.InventoryDate;
GO

-- Check that it works: Select * From vCategoryInventories;
go

-- Question 6 (10% of pts): 
-- CREATE ANOTHER VIEW called vProductInventoriesWithPreviouMonthCounts. 
-- Show a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month Count.
-- Use functions to set any January NULL counts to zero. 
-- Order the results by the Product and Date. 
-- This new view must use your vProductInventories view.

/*
-- LAG() grabs the count from the previous row, partitioned by Product so each product
-- gets its own history.
-- Module 7 notes (page 16) call out "Don't use IsNull!" with LAG. Use IIF on the known
-- first period instead. For us that's January:
--    IIF(InventoryDate LIKE 'January%', 0, LAG(InventoryCount) OVER (...))
-- That zeroes January only and lets any other unexpected NULL stay visible as a real bug.
-- The window's ORDER BY needs the formatted date string converted back to a date:
--    CAST('1 ' + REPLACE(InventoryDate, ',', '') AS DATE)
-- That's the "function in the Order By clause" hint from the assignment NOTES.
*/

GO
CREATE VIEW dbo.vProductInventoriesWithPreviousMonthCounts WITH SCHEMABINDING AS
 SELECT TOP (1000000000)
   ProductName,
   InventoryDate,
   InventoryCount,
   [PreviousMonthCount] = IIF(
     InventoryDate LIKE 'January%',
     0,
     LAG(InventoryCount) OVER (
       PARTITION BY ProductName
       ORDER BY CAST('1 ' + REPLACE(InventoryDate, ',', '') AS DATE)
     )
   )
  FROM dbo.vProductInventories
  ORDER BY ProductName, CAST('1 ' + REPLACE(InventoryDate, ',', '') AS DATE);
GO

-- Check that it works: Select * From vProductInventoriesWithPreviousMonthCounts;
go

-- Question 7 (15% of pts): 
-- CREATE a VIEW called vProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- Varify that the results are ordered by the Product and Date.

/*
-- Build on Q6. Add a CountVsPreviousCountKPI column (1 if up, 0 if same, -1 if down).
-- PreviousMonthCount stays as the actual previous count; the KPI is a separate column.
-- Module 7 notes (page 16) show the exact CASE pattern.
*/

GO
CREATE VIEW dbo.vProductInventoriesWithPreviousMonthCountsWithKPIs WITH SCHEMABINDING AS
 SELECT TOP (1000000000)
   ProductName,
   InventoryDate,
   InventoryCount,
   PreviousMonthCount,
   [CountVsPreviousCountKPI] = CASE
     WHEN InventoryCount >  PreviousMonthCount THEN  1
     WHEN InventoryCount =  PreviousMonthCount THEN  0
     WHEN InventoryCount <  PreviousMonthCount THEN -1
   END
  FROM dbo.vProductInventoriesWithPreviousMonthCounts
  ORDER BY ProductName, CAST('1 ' + REPLACE(InventoryDate, ',', '') AS DATE);
GO

-- Important: This new view must use your vProductInventoriesWithPreviousMonthCounts view!
-- Check that it works: Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs;
go

-- Question 8 (25% of pts): 
-- CREATE a User Defined Function (UDF) called fProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, the Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- The function must use the ProductInventoriesWithPreviousMonthCountsWithKPIs view.
-- Varify that the results are ordered by the Product and Date.

/*
-- A function this time instead of a view. Takes the KPI value (1, 0, or -1) as a parameter
-- and gives back the rows from Q7's view where CountVsPreviousCountKPI matches. 
-- SCHEMABINDING so it chains with the views above.
*/

GO
CREATE FUNCTION dbo.fProductInventoriesWithPreviousMonthCountsWithKPIs(@KPI INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
  SELECT TOP (1000000000)
    ProductName,
    InventoryDate,
    InventoryCount,
    PreviousMonthCount,
    CountVsPreviousCountKPI
  FROM dbo.vProductInventoriesWithPreviousMonthCountsWithKPIs
  WHERE CountVsPreviousCountKPI = @KPI
  ORDER BY ProductName, CAST('1 ' + REPLACE(InventoryDate, ',', '') AS DATE)
);
GO

Print 'Note: You will get an error until the views and functions are created!'

/* Check that it works:
Select * From vProductInventories;
Select * From vCategoryInventories;
Select * From vProductInventoriesWithPreviousMonthCounts;
Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs;

Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
*/
GO

/***************************************************************************************/