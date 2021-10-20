/* 

Usecase : Capability to handle these type of data :   Querying structured data on ADLS Gen2 (CSV and Parquet) using Synapse Serverless 
    A) Structured   Querying semi structured data (JSON) on ADLS Gen 2 using Synapse Serverless 
    B) Semi Structured (Serverless)     Storing the query results of Synapse Serverless Queries using CTAS. 

*/

-- SQL_Serverless_02.1
-- Description : Query JSON data file using serverless SQL pool (data folder SalesLT_Customer_Json)
-- Source As URL PATH
-- Output : JSON format
select top 10 *
from openrowset(
        bulk 'https://oneclickpocadls.dfs.core.windows.net/synapse/AdventureWorksDW2019/serverlessusecase/source_datasets_json/SalesLT_Customer_Json/SalesLT_Customer_20200716.json',
        format = 'csv',
        fieldterminator ='0x0b',
        fieldquote = '0x0b'
    ) with (doc nvarchar(max)) as rows
go

-- SQL_Serverless_02.2
-- Description : Query JSON data file using serverless SQL pool (data folder SalesLT_Customer_Json)
-- Source As URL PATH
-- Output : Table - Row/Column format (Limited Columns)
select 
    JSON_VALUE(doc, '$.CustomerID') AS CustomerID,
    JSON_VALUE(doc, '$.Title') AS Title,
    JSON_VALUE(doc, '$.FirstName') as FistName,
    JSON_VALUE(doc, '$.MiddleName') as MiddleName,
    JSON_VALUE(doc, '$.LastName') as LastName,
    JSON_VALUE(doc, '$.Suffix') as Suffix,
    JSON_VALUE(doc, '$.CompanyName') as CompanyName,
    JSON_VALUE(doc, '$.SalesPerson') as SalesPerson,
    doc
from openrowset(
        bulk 'https://oneclickpocadls.dfs.core.windows.net/synapse/AdventureWorksDW2019/serverlessusecase/source_datasets_json/SalesLT_Customer_Json/SalesLT_Customer_20200716.json',
        format = 'csv',
        fieldterminator ='0x0b',
        fieldquote = '0x0b'
    ) with (doc nvarchar(max)) as rows
go

-- SQL_Serverless_02.3
-- Description : Query JSON data file using serverless SQL pool (data folder SalesLT_Customer_Json)
-- Source As ABFSS PATH
-- Output : Table - Row/Column format (Limited Columns)
select 
    JSON_VALUE(doc, '$.CustomerID') AS CustomerID,
    JSON_VALUE(doc, '$.Title') AS Title,
    JSON_VALUE(doc, '$.FirstName') as FistName,
    JSON_VALUE(doc, '$.MiddleName') as MiddleName,
    JSON_VALUE(doc, '$.LastName') as LastName,
    JSON_VALUE(doc, '$.Suffix') as Suffix,
    JSON_VALUE(doc, '$.CompanyName') as CompanyName,
    JSON_VALUE(doc, '$.SalesPerson') as SalesPerson,
    doc
from openrowset(
        bulk 'abfss://synapse@oneclickpocadls.dfs.core.windows.net/AdventureWorksDW2019/serverlessusecase/source_datasets_json/SalesLT_Customer_Json/SalesLT_Customer_20200716.json',
        format = 'csv',
        fieldterminator ='0x0b',
        fieldquote = '0x0b'
    ) with (doc nvarchar(max)) as rows
go

