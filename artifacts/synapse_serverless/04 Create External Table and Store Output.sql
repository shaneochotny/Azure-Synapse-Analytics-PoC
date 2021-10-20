/* 

Usecase : Capability to handle these type of data :   Querying structured data on ADLS Gen2 (CSV and Parquet) using Synapse Serverless 
    A) Structured   Querying semi structured data (JSON) on ADLS Gen 2 using Synapse Serverless 
    B) Semi Structured (Serverless)     Storing the query results of Synapse Serverless Queries using CTAS. 

*/

-- SQL_Serverless_04.1
-- Run this command if you already created the database and would like to show again 
-- Description : Droping newly created serverless database
-- USE master
-- GO
-- DROP DATABASE  serverlessdb1
-- GO


-- SQL_Serverless_04.2
-- Description : Creating Database in serverless SQL pool for View and External Table
-- Skip below command if you already created serverlessschema1 database
-- CREATE DATABASE  serverlessdb1
-- GO

-- SQL_Serverless_04.3
-- Description : Set newly created database to use
USE  serverlessdb1
GO

-- SQL_Serverless_04.4
-- Description : Data Source to Store Output using Serverless 
-- Run this command if external datasource you already created and want to re-create
-- DROP EXTERNAL DATA SOURCE [MyDataSource]
-- GO


-- SQL_Serverless_04.5
-- Description : Created Data Source to Store Output using Serverless
-- Sub-Folder to Store Output : output_dataset
-- Output : MyDataSource 
CREATE EXTERNAL DATA SOURCE [MyDataSource] WITH (
    LOCATION = 'https://oneclickpocadls.dfs.core.windows.net/synapse/AdventureWorksDW2019/serverlessusecase/output_dataset/SalesLT_Customer'
);
GO

-- SQL_Serverless_04.6
-- Description : Setup External File Format to Parquet and Setup compression Type
CREATE EXTERNAL FILE FORMAT [ParquetFF] WITH (
    FORMAT_TYPE = PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
);
GO

-- SQL_Serverless_04.7
-- Description : Skip if doing first time
-- Drop External Table if already created 
-- External TableName with Data : [dbo].[serverlesscustomerCETAS]
DROP EXTERNAL TABLE [dbo].[serverlesscustomerCETAS]
GO

-- SQL_Serverless_04.8
-- Description : If Dropped the External Table, Need to drop the folder "SalesLT_Customer" also from below path as need to create external table again  
-- Open Synapse Studio -> Select "Data" from left -> "Linked"
-- Path :../tpcds1tb/serverlessusecase/output_dataset/SalesLT_Customer'
-- Folder to Drop "SalesLT_Customer" 

-- SQL_Serverless_04.9
-- Description : Creating External Table and Storing Output 
-- Sub-Folder to Store This Table Output : populationParquet
-- Source : JSON Data File Stored in ABFSS PATH
-- Output : External TableName with Data : [dbo].[serverlesscustomerCETAS]
CREATE EXTERNAL TABLE [dbo].[serverlesscustomerCETAS] WITH (
        LOCATION = 'populationParquet/',
        DATA_SOURCE = [MyDataSource],
        FILE_FORMAT = [ParquetFF]
) AS
select 
    *
from openrowset(
       bulk 'abfss://synapse@oneclickpocadls.dfs.core.windows.net/AdventureWorksDW2019/serverlessusecase/source_datasets_json/SalesLT_Customer_Json/SalesLT_Customer_20200716.json',
        format = 'csv',
        fieldterminator ='0x0b',
        fieldquote = '0x0b'
    ) with (doc nvarchar(max)) as rows
cross apply openjson (doc)
        with (  CustomerID int '$.CustomerID',
                Title varchar(100)  '$.Title',
                FirstName varchar(100) '$.FirstName',
                MiddleName varchar(100) '$.MiddleName',
                LastName varchar(100) '$.LastName',
                Suffix varchar(20) '$.Suffix',
                CompanyName varchar(100) '$.CompanyName',
                SalesPerson varchar(100) '$.SalesPerson',
                EmailAddress varchar(100) '$.EmailAddress',
                Phone varchar(100) '$.Phone'
                )
GO

-- SQL_Serverless_04.10
-- Description : Check in System View if Table Created 
-- Source : [INFORMATION_SCHEMA].[TABLES]
-- Output : List if Tables and View Stored 
SELECT TOP (100) [TABLE_CATALOG]
,[TABLE_SCHEMA]
,[TABLE_NAME]
,[TABLE_TYPE]
 FROM [INFORMATION_SCHEMA].[TABLES];
GO


-- SQL_Serverless_04.11
-- Description : Query External Table
-- Source : [dbo].[serverlesscustomerCETAS]
-- Output : Table - Row/Column format 
SELECT
CustomerID
, Title
, FirstName
, MiddleName
, LastName
, Suffix
, CompanyName
, SalesPerson
, EmailAddress
, Phone 
FROM [dbo].[serverlesscustomerCETAS];
GO
