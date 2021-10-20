/* 

Usecase : Capability to handle these type of data :   Querying structured data on ADLS Gen2 (CSV and Parquet) using Synapse Serverless 
    A) Structured   Querying semi structured data (JSON) on ADLS Gen 2 using Synapse Serverless 
    B) Semi Structured (Serverless)     Storing the query results of Synapse Serverless Queries using CTAS. 

*/

-- SQL_Serverless_01.1
-- IMPORTNT : Please set "Connect to" to 'Build-in'
-- This usecase can run in master database also
-- Description : Query Parquet data file using serverless SQL pool (All nested datafiles in customer folder)
-- Source As URL
-- Output : Table - Row/Column format
select top 10 *
from openrowset(
    bulk 'https://oneclickpocadls.dfs.core.windows.net/synapse/AdventureWorksDW2019/dbo/DimCustomer/**',
    format = 'parquet') as rows
GO


-- SQL_Serverless_01.2
-- Description : Query Parquet data file using serverless SQL pool (All nested datafiles in customer folder)
-- Source As ABFSS PATH
-- Output : Table - Row/Column format
select top 10 *
from openrowset(
    bulk 'abfss://synapse@oneclickpocadls.dfs.core.windows.net/AdventureWorksDW2019/dbo/DimCustomer/**',
    format = 'parquet') as rows
GO

