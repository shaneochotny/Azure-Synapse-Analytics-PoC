--Use Case: Mask & Unmask the EmailAddress and BirthDate columns of the Customer table to DataAnalystSFO
EXECUTE AS USER = 'DataAnalystSFO';  
SELECT TOP 100 * FROM dbo.DimCustomer;

--Check for existing Dynamic Data Masking applied on columns
SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS tbl
    ON c.[object_id] = tbl.[object_id]  
WHERE is_masked = 1
    AND tbl.name = 'DimCustomer';

-- Mask 'EmailAddress' and 'BirthDate' columns of Customer table
ALTER TABLE dbo.DimCustomer
ALTER COLUMN EmailAddress ADD MASKED WITH (FUNCTION = 'email()');
GO
ALTER TABLE dbo.DimCustomer
ALTER COLUMN BirthDate ADD MASKED WITH (FUNCTION = 'default()');
GO

-- Grant SELECT permission to 'DataAnalystSFO' on the Customer table
GRANT SELECT ON dbo.DimCustomer TO DataAnalystSFO;  

-- Validate the data for DataAnalystSFO
EXECUTE AS USER = 'DataAnalystSFO';  
SELECT TOP 100 * FROM dbo.DimCustomer;

-- Perform the Unmask operation
GRANT UNMASK TO DataAnalystSFO;
EXECUTE AS USER = 'DataAnalystSFO';  
SELECT TOP 100 * FROM dbo.DimCustomer;

/*
ALTER TABLE dbo.DimCustomer
ALTER COLUMN EmailAddress DROP MASKED;
GO
ALTER TABLE dbo.DimCustomer
ALTER COLUMN BirthDate DROP MASKED;
GO
*/