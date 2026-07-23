CREATE DATABASE Capstone_Project;

USE Capstone_Project;
GO

--Explore the data
SELECT * FROM Capstone_Customers;

SELECT * FROM Capstone_Orders;
--Find missing values
--Customers:

SELECT *
FROM Capstone_Customers
WHERE Region IS NULL
   OR Segment IS NULL;

--Orders:

SELECT *
FROM Capstone_Orders
WHERE Sales IS NULL
   OR Profit IS NULL;

 --Find duplicate records

--Customers:

SELECT CustomerID, COUNT(*) AS DuplicateCount
FROM Capstone_Customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;

--Orders:

SELECT OrderID, COUNT(*) AS DuplicateCount
FROM Capstone_Orders
GROUP BY OrderID
HAVING COUNT(*) > 1;

-- clean Missing values
-- Replace NULL segment
UPDATE Capstone_Customers
SET Segment = 'Unknown'
WHERE Segment IS NULL;

-- Remove duplicate orders  standard sql server approch
WITH DuplicateOrders AS
(
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY OrderID ORDER BY OrderID) AS rn
    FROM  Capstone_Orders
)
DELETE FROM DuplicateOrders
WHERE rn > 1;


--Replace missing values (sales)

UPDATE Capstone_Orders
SET Sales =
(
    SELECT AVG(Sales)
    FROM Capstone_Orders
    WHERE Sales IS NOT NULL
)
WHERE Sales IS NULL;


--Replace missing values for Profit:

UPDATE Capstone_Orders
SET Profit =
(   
    SELECT AVG(Profit)
    FROM Capstone_Orders
    WHERE Profit IS NOT NULL
)
WHERE Profit IS NULL;


--Create Clean Tables


--already exists
EXEC sp_help  Capstone_Customers_Clean;
EXEC sp_help  Capstone_Orders_Clean;

--1. JOIN
--Display customer details along with their orders.

SELECT
    c.CustomerID,
    c.CustomerName,
    c.Region,
    c.Segment,
    o.OrderID,
    o.OrderDate,
    o.Category,
    o.Sales,
    o.Profit
FROM Capstone_Customers_Clean c
INNER JOIN Capstone_Orders_Clean o
ON c.CustomerID = o.CustomerID;

--2. GROUP BY
--Find total sales and profit by category.

SELECT
    Category,
    SUM(Sales) AS TotalSales,
    SUM(Profit) AS TotalProfit
FROM Capstone_Orders_Clean
GROUP BY Category;

--3. HAVING
--Show categories whose total sales exceed 50,000.

SELECT
    Category,
    SUM(Sales) AS TotalSales
FROM Capstone_Orders_Clean
GROUP BY Category
HAVING SUM(Sales) > 50000;

--4. CASE WHEN
--Categorize each order based on sales.

SELECT
    OrderID,
    Sales,
    CASE
        WHEN Sales >= 500 THEN 'High Value'
        WHEN Sales >= 200 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS OrderCategory
FROM Capstone_Orders_Clean;


--5. Subquery
--Display orders whose sales are greater than the average sales.

SELECT
    OrderID,
    CustomerID,
    Sales
FROM Capstone_Orders_Clean
WHERE Sales >
(
    SELECT AVG(Sales)
    FROM Capstone_Orders_Clean
);

--6. Common Table Expression (CTE)
--Calculate total sales for each customer.

WITH CustomerSales AS
(
    SELECT
        CustomerID,
        SUM(Sales) AS TotalSales
    FROM Capstone_Orders_Clean
    GROUP BY CustomerID
)

SELECT
    CustomerID,
    TotalSales
FROM CustomerSales
ORDER BY TotalSales DESC;

--7. Window Function – ROW_NUMBER()
--Assign a row number based on highest sales.

SELECT
    OrderID,
    CustomerID,
    Sales,
    ROW_NUMBER() OVER(ORDER BY Sales DESC) AS RowNum
FROM Capstone_Orders_Clean;

--Running Total
SELECT
    OrderDate,
    OrderID,
    Sales,
    SUM(Sales) OVER
    (
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM Capstone_Orders_Clean;