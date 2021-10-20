-- Script Name: 01-Table Operations
-- Description : This script contains creation scripts of stored procedures to drop and truncate tables

-- Create a procedure to drop a table based on the argument
CREATE PROCEDURE sp_DropTable (@tableName VARCHAR(255))
AS
BEGIN

    DECLARE @SQL VARCHAR(MAX);

    SET @SQL = 'IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N''' + @tableName + ''') AND type = (N''U'')) DROP TABLE [' + @tableName + ']'

    --if write EXEC @SQL without parentheses  sql says Error: is not a valid identifier

    EXEC (@SQL);

END

exec sp_DropTable 'StgFactSalesByCountry'



-- Create a procedure to truncate a table based on the argument
CREATE PROCEDURE sp_TruncateTable (@tableName VARCHAR(255))
AS
BEGIN

    DECLARE @SQL VARCHAR(MAX);

    SET @SQL = 'IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N''' + @tableName + ''') AND type = (N''U'')) TRUNCATE TABLE [' + @tableName + ']'

    --if write EXEC @SQL without parentheses  sql says Error: is not a valid identifier

    EXEC (@SQL);

END

exec sp_TruncateTable 'DimCustomer'


-- Create a procedure load into Customer Dimension
--DROP PROCEDURE sp_LoadDimProduct
CREATE PROCEDURE sp_LoadDimProduct
AS
BEGIN  
    SET NOCOUNT ON;  

    INSERT INTO DimProduct
    SELECT * FROM StgProduct;

END
GO

exec sp_LoadDimProduct;

