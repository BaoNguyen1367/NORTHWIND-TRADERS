USE NORTHWIND

-- Question 1: Finding the VIP and Less Engaged Customers

-- Top 5 VIP customer 

SELECT TOP 5
		c.CustomerID,
		c.CompanyName, 
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS "Total Sales"
FROM [dbo].[Orders] o
JOIN [dbo].[Order Details] od
  ON o.OrderID = od.OrderID
JOIN [dbo].[Customers] c
  ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY [Total Sales] DESC;

-- Top 5 least engaging Customer

SELECT TOP 5
		c.CustomerID,
		c.CompanyName, 
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS "Total Sales"
FROM [dbo].[Orders] o
JOIN [dbo].[Order Details] od
  ON o.OrderID = od.OrderID
JOIN [dbo].[Customers] c
  ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY [Total Sales] ;

-- Question 2: Ranking Employee Sales Performance
CREATE VIEW Ranking_Employee AS 
WITH EmployeeSales AS (
    SELECT e.EmployeeID, e.FirstName, e.LastName,
           SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS "Total Sales"
    FROM dbo.[Orders] o
    JOIN dbo.[Order Details] od
	  ON o.OrderID = od.OrderID
    JOIN dbo.[Employees] e 
	  ON o.EmployeeID = e.EmployeeID
   GROUP BY e.EmployeeID, e.FirstName, e.LastName
)
SELECT EmployeeID, FirstName, LastName,
       RANK() OVER (ORDER BY "Total Sales" DESC) AS "Sales Rank"
FROM EmployeeSales;

-- Question 3: Running Total of Monthly Sales

CREATE VIEW Running_Total_Month_Sales AS
WITH MonthlySales AS (
    SELECT DATETRUNC(Month, o.OrderDate) AS "Month", 
           SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS "Total Sales"
    FROM [dbo].[Orders] o
    JOIN [dbo].[Order Details] od
	ON o.OrderID = od.OrderID
    GROUP BY DATETRUNC(Month, o.OrderDate)
)
SELECT "Month", 
       SUM("Total Sales") OVER (ORDER BY "Month") AS "Running Total"
FROM MonthlySales;

-- Question 4: Month-Over-Month Sales Growth

WITH MonthlySales AS (
    SELECT MONTH(o.OrderDate) AS 'Month', 
           YEAR(o.OrderDate) AS 'Year', 
           SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalSales
    FROM [dbo].[Orders] o
    JOIN [dbo].[Order Details] od 
	  ON o.OrderID = od.OrderID
    GROUP BY MONTH(o.OrderDate), YEAR(o.OrderDate)
),
LaggedSales AS (
    SELECT ms.Month, ms.Year, 
           TotalSales, 
           LAG(TotalSales) OVER (ORDER BY Year, Month) AS PreviousMonthSales
    FROM MonthlySales ms
)
SELECT ls.Year, ls.Month,
       ((TotalSales - PreviousMonthSales) / PreviousMonthSales) * 100 AS "Growth Rate"
FROM LaggedSales ls;

-- Question 5: Percentage of Sales for Each Category

CREATE VIEW Percentage_Sales_Each_Category AS
WITH CategorySales AS (
    SELECT c.CategoryID, c.CategoryName,
           SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS "Total Sales"
    FROM [dbo].[Categories] c
    JOIN [dbo].[Products] p 
	  ON c.CategoryID = p.CategoryID
    JOIN [dbo].[Order Details] od
	  ON p.ProductID = od.ProductID
    GROUP BY c.CategoryID, c.CategoryName
)
SELECT CategoryID, CategoryName,
       "Total Sales" / SUM("Total Sales") OVER () * 100 AS "Sales Percentage"
FROM CategorySales;

-- Question 6: Top Products Per Category

CREATE VIEW  Top_Products_Per_Category AS
WITH ProductSales AS (
    SELECT p.CategoryID,
           p.ProductID, p.ProductName,
           SUM(p.UnitPrice * Quantity * (1 - Discount)) AS "Total Sales"
    FROM [dbo].[Products] p
    JOIN [dbo].[Order Details] od
	  ON p.ProductID = od.ProductID
    GROUP BY p.CategoryID, p.ProductID, p.ProductName
)
SELECT CategoryID, 
       ProductID, ProductName,
       "Total Sales"
FROM (
    SELECT CategoryID, 
           ProductID, ProductName,
           "Total Sales", 
           ROW_NUMBER() OVER (PARTITION BY CategoryID ORDER BY "Total Sales" DESC) AS rn
    FROM ProductSales
) tmp
WHERE rn <= 3;



-- Question 7: Which Products Should We Order More of or Less of

CREATE VIEW Best_Products AS
WITH 
Low_Stock AS(
SELECT TOP 10 ProductID, ProductName, ROUND(SUM(UnitsInStock-UnitsOnOrder),2) AS Low_Stock
  FROM [dbo].[Products]
 GROUP BY ProductID, ProductName
 ORDER BY Low_Stock
),
Product_Performance AS(
SELECT TOP 10 p.ProductID, sum(od.Quantity*od.UnitPrice*(1-od.Discount)) as Product_Performance
  FROM [dbo].[Products] p
 INNER JOIN [dbo].[Order Details] od
    ON p.ProductID = od.ProductID
 GROUP BY p.ProductID
 ORDER BY Product_Performance
)
SELECT l.ProductName, pp.ProductID, l.Low_Stock, pp.Product_Performance
  FROM Low_Stock l
 INNER JOIN Product_Performance pp
    ON l.ProductID = pp.ProductID;

/* This question refers to inventory reports, including low stock(i.e. product in demand) and product performance. This will optimize the supply and the user experience by preventing the best-selling products from going out-of-stock.
- The low stock represents the quantity of the sum of each the quantity of product in stock subtract by  product ordered . We can consider the ten highest rates. These will be the top ten products that are almost out-of-stock or completely out-of-stock.
- The product performance represents the sum of sales per product.
Priority products for restocking are those with high product performance that are on the brink of being out of stock.*/
