/* 

 Usecase : Capability to handle these type of data :   Querying structured data on ADLS Gen2 (CSV and Parquet) using Synapse Serverless 
    A) Structured   Querying semi structured data (JSON) on ADLS Gen 2 using Synapse Serverless 
    B) Semi Structured (Serverless)     Storing the query results of Synapse Serverless Queries using CTAS. 

*/

-- SQL_Serverless_03.1
-- Run this command if you already created the database and would like to show again 
-- Description : Droping newly created serverless database
-- USE master
-- GO
-- DROP DATABASE serverlessdb1
-- GO


-- SQL_Serverless_03.2
-- Description : Creating Database in serverless SQL pool for View and External Table
CREATE DATABASE  serverlessdb1
GO

-- SQL_Serverless_03.3
-- Description : Set newly created database to use
USE  serverlessdb1
GO


-- SQL_Serverless_03.4
-- Run this command if you already created the view 
-- Description : Droping newly created view in serverless SQL pool
-- DROP VIEW serverlesscustomer
-- GO 


-- SQL_Serverless_03.5
-- Description : Create View in serverless SQL pool
-- Source As ABFSS PATH
-- Output : View (View Name : serverlesscustomer)
CREATE VIEW serverlesscustomer
AS 
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

-- SQL_Serverless_03.6
-- Description : Select Data From serverless view
-- Source : Serverless View (View Name : serverlesscustomer)
-- Output : Table - Row/Column format (Limited Columns)
Select 
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
from serverlesscustomer
GO



-- SQL_Serverless_03.7
-- Description : Select Data From serverless view with WHERE condition
-- Source : Serverless View (View Name : serverlesscustomer)
-- Output : Table - Row/Column format (Limited Rows/Columns)
Select 
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
from serverlesscustomer
where FirstName = 'Brian'
--and Lastname = 'Johnson'
GO


