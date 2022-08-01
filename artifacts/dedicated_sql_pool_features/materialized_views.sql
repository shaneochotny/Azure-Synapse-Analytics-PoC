/* Use Case: 
    DataAnalystSFO should not have access to birthdate and phone columns
    on the Customer table
*/

-- Run the Original Query
WITH year_total AS (
SELECT c.customerkey customer_id
       ,c.firstname customer_first_name
       ,c.lastname customer_last_name
       ,c.phone Phone
       ,d.CalendarYear year
       ,sum(isnull(s.UnitPrice-s.TotalProductCost-s.UnitPriceDiscountPct, 0)/2) year_total
       ,'s' sale_type
FROM Sample.dimCustomer c
     ,Sample.factinternetsales s
     ,Sample.dimdate d
WHERE c.customerkey = s.customerkey
   AND s.orderdatekey = d.datekey
GROUP BY c.customerkey
         ,c.firstname
         ,c.lastname
         ,c.phone
         ,d.calendaryear
)
 SELECT
     Customer_id
    ,Customer_First_Name
    ,Customer_Last_Name
    ,avg(year_total) Avg_Year_Total
    ,min(year_total) Min_Total
    ,max(year_total) Max_Total
FROM year_total 
  GROUP BY customer_id
          ,customer_first_name
          ,customer_last_name;
      
-- Use Explain With_Recommendations to get recommendations for Materialized view.
EXPLAIN WITH_RECOMMENDATIONS
WITH year_total AS (
SELECT c.customerkey customer_id
       ,c.firstname customer_first_name
       ,c.lastname customer_last_name
       ,c.phone Phone
       ,d.CalendarYear year
       ,sum(isnull(s.UnitPrice-s.TotalProductCost-s.UnitPriceDiscountPct, 0)/2) year_total
       ,'s' sale_type
FROM Sample.dimCustomer c
     ,Sample.factinternetsales s
     ,Sample.dimdate d
WHERE c.customerkey = s.customerkey
   AND s.orderdatekey = d.datekey
GROUP BY c.customerkey
         ,c.firstname
         ,c.lastname
         ,c.phone
         ,d.calendaryear
)
 SELECT
       Customer_id
      ,Customer_First_Name
      ,Customer_Last_Name
      ,avg(year_total) Avg_Year_Total
      ,min(year_total) Min_Total
      ,max(year_total) Max_Total
FROM year_total 
  GROUP BY customer_id
         ,customer_first_name
         ,customer_last_name;
      

-- Create materialized view based on the recommendation provided
CREATE MATERIALIZED VIEW Sample.MVExample WITH (DISTRIBUTION = HASH([Customer_ID])) AS
SELECT [c].[CustomerKey] AS Customer_ID,
       [c].[FirstName] AS Customer_First_Name,
       [c].[LastName] AS Customer_Last_Name,
       [c].[Phone] AS Phone,
       [d].[CalendarYear] AS CalendarYear,
       SUM(isnull(CONVERT(float(53),[s].[UnitPrice]-[s].[TotalProductCost],0)-[s].[UnitPriceDiscountPct],(0.0000000000000000e+000))/(2.0000000000000000e+000)) AS Year_Total
FROM [Sample].[DimCustomer] [c],
     [Sample].[FactInternetSales] [s],
     [Sample].[DimDate] [d]
WHERE ([s].[OrderDateKey]=[d].[DateKey])
  AND ([c].[CustomerKey]=[s].[CustomerKey])
GROUP BY [c].[CustomerKey],
         [c].[FirstName],
         [c].[LastName],
         [c].[Phone],
         [d].[CalendarYear];

-- Run a query referencing the materialized view
SELECT
                  Customer_id
                 ,Customer_First_Name
                 ,Customer_Last_Name
                 ,avg(year_total) Avg_Year_Total
                 ,min(year_total) Min_Total
                 ,max(year_total) Max_Total
FROM  Sample.MVExample
  GROUP BY customer_id
         ,customer_first_name
         ,customer_last_name;

-- Run a query covered by the materialized view
SELECT [c].[CustomerKey] AS Customer_ID,
       [d].[CalendarYear] AS CalendarYear,
       SUM(isnull(CONVERT(float(53),[s].[UnitPrice]-[s].[TotalProductCost],0)-[s].[UnitPriceDiscountPct],(0.0000000000000000e+000))/(2.0000000000000000e+000)) AS Year_Total
FROM [Sample].[DimCustomer] [c],
     [Sample].[FactInternetSales] [s],
     [Sample].[DimDate] [d]
WHERE ([s].[OrderDateKey]=[d].[DateKey])
  AND ([c].[CustomerKey]=[s].[CustomerKey])
GROUP BY [c].[CustomerKey],
         [d].[CalendarYear];


/*
CLEAN UP:
DROP MATERIALIZED VIEW Sample.MVExample;
*/