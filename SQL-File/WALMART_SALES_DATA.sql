--Creating the Database
CREATE DATABASE WALMART_SALES_DATA
USE WALMART_SALES_DATA


--Creating the Table
CREATE TABLE SALES(
Invoice_ID VARCHAR(10),
Branch VARCHAR(1),
City VARCHAR(40),
Customer_Type VARCHAR(20),
Gender VARCHAR(10),
Product_Line VARCHAR(45),
Unit_Price DECIMAL(6,2),
Quantity VARCHAR(5),
Tax_5_percent DECIMAL(10,4),
Total DECIMAL(10,5),
Date_ DATE,
Time_ TIME,
Payment VARCHAR(20),
COGS DECIMAL(10,2),
Gross_Margin_Percentage DECIMAL(10,6),
Gross_Income DECIMAL(10,4),
Rating DECIMAL(3,1)
)


ALTER TABLE SALES ALTER COLUMN Invoice_ID VARCHAR(30);


--Importing the Dataset
BULK INSERT SALES
FROM "C:\Users\dhruv\Downloads\WalmartSalesData.csv"
WITH(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n'
)


SELECT TOP 10 * FROM SALES


--ALTERING QUESTIONS
-- Can we categorize the transaction time into Morning, Afternoon, and Evening to analyze the time of day when most sales occur?
ALTER TABLE SALES ADD Daytime AS(
CASE 
WHEN DATEPART(HOUR, Time_) >= 5 AND DATEPART(HOUR, Time_) < 12 THEN 'Morning'
WHEN DATEPART(HOUR, Time_) >=12 AND DATEPART(HOUR, Time_) < 17 THEN 'Afternoon'
ELSE 'Evening'
END
)

-- On which day of the week did each transaction take place to understand daily sales trends?
ALTER TABLE SALES ADD Weekday_ as (DATENAME(Weekday,Time_))
ALTER TABLE SALES DROP COLUMN Weekday_

ALTER TABLE SALES ADD Weekday_ as (DATENAME(Weekday,Date_))

-- In which month did each transaction occur to determine monthly sales and profit performance?
ALTER TABLE SALES ADD Month_Name as (DATENAME(Month,Date_))

--GENERIC QUESTIONS
-- How many unique cities are present in the dataset?
SELECT COUNT(DISTINCT City) as Total_Cities FROM SALES

-- Which city is associated with each store branch?
SELECT City, COUNT(DISTINCT Branch) as Unique_Branch FROM SALES
GROUP BY City
HAVING COUNT(DISTINCT Branch) = (SELECT COUNT(DISTINCT Branch) FROM SALES)
ORDER BY City asc

--PRODUCT ANALYSIS QUESTIONS
-- How many unique product lines are available in the dataset?
SELECT COUNT(DISTINCT Product_Line) as Unique_Product_Lines FROM SALES

-- What is the most commonly used payment method?
SELECT TOP 1 Payment, COUNT(Payment) as Number_of_Payments FROM SALES
GROUP BY Payment
ORDER BY COUNT(Payment) desc

-- Which product line has the highest number of units sold?
SELECT TOP 1 Product_Line, SUM(Quantity) as Units_Sold FROM SALES
GROUP BY Product_Line
ORDER BY SUM(Quantity) desc

ALTER TABLE SALES ALTER COLUMN Quantity INT

-- What is the total revenue generated in each month?
SELECT Month_Name, SUM(ISNULL(Total,0)) as Total_Revenue FROM SALES
GROUP BY Month_Name

-- In which month was the cost of goods sold (COGS) the highest?
SELECT TOP 1 Month_Name, SUM(ISNULL(COGS,0)) as COGS FROM SALES
GROUP BY Month_Name
ORDER BY SUM(ISNULL(COGS,0)) desc

-- Which product line generated the most revenue?
SELECT TOP 1 Product_Line, SUM(ISNULL(Total,0)) as Total_Revenue FROM SALES
GROUP BY Product_Line
ORDER BY SUM(ISNULL(Gross_Income,0)) desc

-- Which city recorded the highest total revenue?
SELECT TOP 1 City, SUM(ISNULL(Total,0)) as Total_Revenue FROM SALES
GROUP BY City
ORDER BY SUM(ISNULL(Total,0)) desc

-- Which product line had the highest average VAT percentage?
SELECT TOP 1 Product_Line, AVG(Tax_5_percent) as VAT_Percentage FROM SALES
GROUP BY Product_Line
ORDER BY AVG(Tax_5_percent) desc

-- Can we classify each product line as “Good” or “Bad” based on whether its sales volume is above or below the average?
WITH ProductLineVolumes AS(
SELECT Product_Line, SUM(Quantity) as Sales_Volume
FROM SALES 
GROUP BY Product_Line
)

SELECT Product_Line, Sales_Volume,
CASE WHEN Sales_Volume > (SELECT AVG(Sales_Volume) FROM ProductLineVolumes) THEN 'Good'
ELSE 'Bad' 
END as Classification
FROM ProductLineVolumes

-- Which branch sold more products than the overall average number of products sold?
SELECT TOP 1 Branch, SUM(Quantity) as Products_Sold FROM SALES
GROUP BY Branch
HAVING SUM(Quantity) > (SELECT AVG(Quantity) FROM SALES)
ORDER BY SUM(Quantity) desc

-- For each gender, which product line is purchased the most?
SELECT TOP 2 Gender, Product_Line, COUNT(Product_Line) as Product_Line_Sold FROM SALES
GROUP BY Gender, Product_Line
ORDER BY COUNT(Product_Line) desc

--	What is the average customer rating for each product line?
SELECT Product_Line, AVG(Rating) as AVG_Rating FROM SALES
GROUP BY Product_Line
ORDER BY AVG(Rating) desc


--SALES ANALYSIS QUESTIONS
-- How many sales were made during each time of day (Morning, Afternoon, Evening) for every day of the week?
SELECT Weekday_, Daytime, SUM(ISNULL(Gross_Income,0)) as Sales FROM SALES
GROUP BY Weekday_, Daytime
ORDER BY Weekday_ asc, Daytime asc

-- Which customer type contributes the most to the company’s total revenue?
SELECT TOP 1 Customer_Type, SUM(ISNULL(Total,0)) as Total_Revenue FROM SALES
GROUP BY Customer_Type
ORDER BY SUM(ISNULL(Gross_Income,0)) desc

-- Which city has the highest average VAT percentage?
SELECT TOP 1 City, AVG(Tax_5_Percent) as AVG_VAT_percentage FROM SALES
GROUP BY City
ORDER BY AVG(Tax_5_Percent) desc

-- Which customer type pays the most VAT on average?
SELECT TOP 1 Customer_Type, AVG(Tax_5_Percent) as AVG_VAT_percentage FROM SALES
GROUP BY Customer_Type
ORDER BY AVG(Tax_5_Percent) desc

--CUSTOMER ANALYSIS QUESTIONS
-- How many unique customer types are present in the dataset?
SELECT COUNT(DISTINCT Customer_Type) as Unique_Customer_Types FROM SALES

-- How many different payment methods are used by customers?
SELECT COUNT(DISTINCT Payment) as Total_Payment_Methods FROM SALES

-- What is the most common customer type?
SELECT TOP 1 Customer_Type, COUNT(Customer_Type) as Total_Customers FROM SALES
GROUP BY Customer_Type
ORDER BY COUNT(Customer_Type) desc

-- Which customer type makes the most purchases?
SELECT TOP 1 Customer_Type, COUNT(Invoice_ID) as Total_Purchases FROM SALES
GROUP BY Customer_Type
ORDER BY COUNT(Invoice_ID) desc

-- What is the gender distribution among the customers?
SELECT Gender, COUNT(Gender) as Gender_Distribution FROM SALES
GROUP BY Gender

-- How does the gender distribution vary across different store branches?
SELECT Branch, Gender, COUNT(Gender) as Gender_Distribution FROM SALES
GROUP BY Branch, Gender
ORDER BY Branch asc

-- During which time of the day do customers give the highest average ratings?
SELECT TOP 1 Daytime, AVG(Rating) as AVG_Highest_Rating FROM SALES
GROUP BY Daytime
ORDER BY AVG(Rating) desc

-- During which time of the day do customers in each branch give the best ratings?
WITH Ranked_Rating as(
SELECT Branch, Daytime, AVG(Rating) as AVG_Rating,
ROW_NUMBER() OVER (PARTITION BY Branch ORDER BY AVG(Rating) desc) as Rating_Rank
FROM SALES
GROUP BY Branch, Daytime
)

SELECT Branch, Daytime, AVG_Rating FROM Ranked_Rating
WHERE Rating_Rank = 1

-- On which day of the week do customers provide the best average ratings?
SELECT TOP 1 Weekday_, AVG(Rating) as AVG_Highest_Rating FROM SALES
GROUP BY Weekday_
ORDER BY AVG(Rating) desc

-- For each branch, which day of the week receives the highest number of sales?
WITH Ranked_Rating as(
SELECT Branch, Weekday_, AVG(Rating) as AVG_Rating,
ROW_NUMBER() OVER (PARTITION BY Branch ORDER BY AVG(Rating) desc) as Rating_Rank
FROM SALES
GROUP BY Branch, Weekday_
)

SELECT Branch, Weekday_, AVG_Rating FROM Ranked_Rating
WHERE Rating_Rank = 1
