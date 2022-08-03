/* Use Case: 
    Using Materialized Views in Synapse Dedicated SQL Pools
    to improve performance.
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- First, create table to store JSON data
CREATE TABLE [dbo].[User_Data]
( 
	[jsondata] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

-- Then, use COPY INTO statement to load the data from the lake into SQL pool table
COPY INTO Sample.User_Data
(jsonData 1)
FROM 'https://REPLACE_SYNAPSE_ANALYTICS_WORKSPACE_NAME.dfs.core.windows.net/data/user_data.json.gz'
WITH
(
		FILE_TYPE = 'CSV'
		,fieldterminator ='0x0b'
        ,fieldquote = '0x0b'
		,COMPRESSION = 'Gzip'
)
--END
GO

-- Select to verify data loaded correctly
SELECT TOP 100 * FROM Sample.User_Data
GO

 --Use the JSON Extractor to parse the complex JSON data 
SELECT   TOP 10
       JSON_VALUE( jsondata,'$.name') AS Name, 
       JSON_VALUE( jsonData,'$.username') AS Username, 
       JSON_VALUE( jsonData,'$.email') AS Email, 
       JSON_VALUE( jsonData,'$.address.streetA') AS Street1,
       JSON_VALUE( jsonData,'$.address.streetB') AS Street2,
       JSON_VALUE( jsonData,'$.address.city') AS City
FROM Sample.[user_data] 
WHERE
    ISJSON(jsonData) > 0 

-- The query below fetches JSON data and filters it by username.
-- Note, this extracts specific columns in a structured format
SELECT   
       JSON_VALUE( jsondata,'$.name') AS Name, 
       JSON_VALUE( jsonData,'$.username') AS Username, 
       JSON_VALUE( jsonData,'$.email') AS Email, 
       JSON_VALUE( jsonData,'$.address.streetA') AS Street1,
       JSON_VALUE( jsonData,'$.address.streetB') AS Street2,
       JSON_VALUE( jsonData,'$.address.city') AS City
FROM Sample.[user_data] 
WHERE    
    ISJSON(jsonData) > 0  AND
    JSON_VALUE( jsonData,'$.username')='Jeffrey77'


-- This example show s you how to deal with JSON arrays
SELECT   
       JSON_VALUE( jsondata,'$.name') AS Name, 
       JSON_VALUE( jsonData,'$.username') AS Username, 
       JSON_VALUE( jsonData,'$.email') AS Email, 
       JSON_VALUE( jsonData,'$.address.streetA') AS Street1,
       JSON_VALUE( jsonData,'$.address.streetB') AS Street2,
       JSON_VALUE( jsonData,'$.address.city') AS City
       ,accountHistory.amount, accountHistory.name
FROM Sample.[user_data]
    CROSS APPLY 
        OPENJSON(jsondata,'lax $.accountHistory') 
        WITH ( amount nvarchar(500) '$.amount' , name nvarchar(500) )
        AS accountHistory
WHERE
    ISJSON(jsonData) > 0  AND
    JSON_VALUE( jsonData,'$.username')='Jeffrey77'
       
/*
CLEAN UP:
DROP TABLE [dbo].[User_Data];
*/