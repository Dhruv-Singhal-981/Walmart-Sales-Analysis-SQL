# Walmart Sales Performance Analysis (SQL)

## 📌 Project Overview
This project focuses on analyzing historical sales data from Walmart to isolate high-performing branches, evaluate consumer purchasing behaviors across different demographic segments, and optimize inventory and marketing strategies based on peak transaction times. 

The primary goal of this repository is to demonstrate production-grade **T-SQL proficiency**, showcasing advanced relational database techniques, data-cleansing strategies, and actionable business intelligence modeling.

---

## 💾 Dataset Access
The underlying dataset utilized for this analysis is sourced from Kaggle. 
* **Raw Data Source:** https://www.kaggle.com/datasets/dhruvsinghalanalyst/walmart-sales-data


---

## 🛠️ Technical SQL Skills Showcased
* **Data Definition & Manipulation (DDL/DML):** Advanced schema definition, data type constraints, and post-load column modifications using `ALTER TABLE`.
* **Deterministic Computed Columns:** Optimizing database storage engine overhead by generating dynamic fields (`Daytime`, `Weekday_`) on-the-fly rather than executing heavy, manual `UPDATE` cycles.
* **Advanced Window Functions:** Utilizing `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` inside Common Table Expressions (CTEs) to solve complex relational ranking problems.
* **Defensive Aggregations:** Mitigating hidden data anomalies using `ISNULL()` wrappers to protect arithmetic calculations from unexpected null states.
* **Data Type Tuning:** Re-aligning imported structural constraints (e.g., converting text-based `Quantity` fields into strict integer formats for computational accuracy).

---

## 📊 Database Architecture & Setup

```sql
-- Creating the Target Database Infrastructure
CREATE DATABASE WALMART_SALES_DATA;
USE WALMART_SALES_DATA;

-- Core Sales Schema Definition
CREATE TABLE SALES(
    Invoice_ID VARCHAR(30),
    Branch VARCHAR(1),
    City VARCHAR(40),
    Customer_Type VARCHAR(20),
    Gender VARCHAR(10),
    Product_Line VARCHAR(45),
    Unit_Price DECIMAL(6,2),
    Quantity INT,
    Tax_5_percent DECIMAL(10,4),
    Total DECIMAL(10,5),
    Date_ DATE,
    Time_ TIME,
    Payment VARCHAR(20),
    COGS DECIMAL(10,2),
    Gross_Margin_Percentage DECIMAL(10,6),
    Gross_Income DECIMAL(10,4),
    Rating DECIMAL(3,1)
);

-- Optimization of Temporal Dimensions via Computed Columns
ALTER TABLE SALES ADD Daytime AS (
    CASE 
        WHEN DATEPART(HOUR, Time_) >= 5 AND DATEPART(HOUR, Time_) < 12 THEN 'Morning'
        WHEN DATEPART(HOUR, Time_) >= 12 AND DATEPART(HOUR, Time_) < 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
);

ALTER TABLE SALES ADD Weekday_ AS (DATENAME(Weekday, Date_));
ALTER TABLE SALES ADD Month_Name AS (DATENAME(Month, Date_));
```

---
## Key Business Insights & Advanced Querying
**1. High-Density Customer Segmentation Matrix**
Answering the business question: For each gender, which product line is purchased the most? This approach leverages window functions inside a CTE to seamlessly isolate the top spot for both categories without using blunt TOP hacks.
```
WITH RankedGenderProducts AS (
    SELECT 
        Gender, 
        Product_Line, 
        COUNT(*) as Units_Sold,
        ROW_NUMBER() OVER(PARTITION BY Gender ORDER BY COUNT(*) DESC) as Rank_Num
    FROM SALES
    GROUP BY Gender, Product_Line
)
SELECT Gender, Product_Line, Units_Sold 
FROM RankedGenderProducts 
WHERE Rank_Num = 1;
```
**2. Identifying Peak Revenue Days per Branch**
Answering the business question: For each branch, which day of the week receives the highest number of sales?
```
WITH RankedSalesDays AS (
    SELECT 
        Branch, 
        Weekday_, 
        SUM(Total) as Total_Revenue,
        ROW_NUMBER() OVER(PARTITION BY Branch ORDER BY SUM(Total) DESC) as Sales_Rank
    FROM SALES
    GROUP BY Branch, Weekday_
)
SELECT Branch, Weekday_, Total_Revenue 
FROM RankedSalesDays
WHERE Sales_Rank = 1;
```
**3. Dynamic Product Performance Classification**
Classifying product lines as "Good" or "Bad" by dynamically isolating whether their total sales volume sits above or below the true aggregate average across all categories.
```
WITH ProductLineVolumes AS (
    SELECT Product_Line, SUM(Quantity) as Sales_Volume
    FROM SALES 
    GROUP BY Product_Line
)
SELECT Product_Line, Sales_Volume,
       CASE WHEN Sales_Volume > (SELECT AVG(Sales_Volume) FROM ProductLineVolumes) THEN 'Good'
            ELSE 'Bad' 
       END as Classification
FROM ProductLineVolumes;
```
---
## Refactoring & Optimization Log
A vital component of a production analyst's workflow is the regular auditing of scripts for logical accuracy. Below are the core refactoring milestones completed to ensure data integrity:

**Revenue Logic Alignment:** Discovered a business definition mismatch where Gross_Income (representing localized tax margin entries) was initially aggregated as revenue. Refactored all core financial questions to track the Total gross sales column, correcting a ~95% metric underreporting variance.

**Aggregative Boundary Correction:** Fixed a critical scoping bug in the product classification subquery. Replaced a row-level transaction average comparison with an explicit category-volume matrix via a CTE. This resolved a logical error where every product line was incorrectly flagged as "Good".

**Temporal Parameter Fix:** Resolved a temporal calculation error where passing a strict TIME column to a date-dependent DATENAME(Weekday) function caused structural failures. Shifted target telemetry explicitly to the Date_ field to restore chronological analysis tracking.

**COGS Sorting Hierarchy:** Corrected the peak Cost of Goods Sold (COGS) evaluation query by flipping the sorting mechanism from ASC to DESC, ensuring the query extracts true peak monthly outlays rather than baseline minimums.
