/* Use Case: 
    Mask & Unmask the EmailAddress and BirthDate columns of the 
    Customer table to DataAnalystSFO
*/

-- Create 2 users for use case demonstration!
CREATE USER DataAnalystSFO WITHOUT LOGIN;
CREATE USER DataAnalystGlobal WITHOUT LOGIN;
--SELECT * FROM sys.sysusers WHERE name in ('DataAnalystGlobal', 'DataAnalystSFO');

-- Grant SELECT permission to 'DataAnalystSFO' on the Customer table
GRANT SELECT ON Sample.DimCustomer TO DataAnalystSFO;  

-- Run a query as 'DataAnalystSFO' to verify the access 
EXECUTE AS USER = 'DataAnalystSFO';  
SELECT TOP 100 * FROM Sample.DimCustomer;

-- Optionally, Check for existing Dynamic Data Masking applied on columns
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl
    ON c.[object_id] = tbl.[object_id]  
WHERE is_masked = 1
    AND tbl.name = 'DimCustomer';

-- Mask 'EmailAddress' and 'BirthDate' columns of Customer table
ALTER TABLE Sample.DimCustomer
ALTER COLUMN EmailAddress ADD MASKED WITH (FUNCTION = 'email()');
GO
ALTER TABLE Sample.DimCustomer
ALTER COLUMN BirthDate ADD MASKED WITH (FUNCTION = 'default()');
GO



-- Validate the data for DataAnalystSFO
EXECUTE AS USER = 'DataAnalystSFO';  
SELECT TOP 100 * FROM Sample.DimCustomer;

-- Perform the Unmask operation
GRANT UNMASK TO DataAnalystSFO;
EXECUTE AS USER = 'DataAnalystSFO';  
SELECT TOP 100 * FROM Sample.DimCustomer;

/*
CLEAN UP:
DROP USER DataAnalystSFO;
DROP USER DataAnalystGlobal;
ALTER TABLE Sample.DimCustomer ALTER COLUMN EmailAddress DROP MASKED;
ALTER TABLE Sample.DimCustomer ALTER COLUMN BirthDate DROP MASKED;
*/