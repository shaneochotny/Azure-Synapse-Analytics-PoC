/* Use Case: 
    DataAnalystGlobal should have all data access and
    DataAnalystSFO users should have limited access to
    rows belonging to GeographyKey 360 in Sample.DimCustomer! 
Docs: https://docs.microsoft.com/en-us/sql/relational-databases/security/row-level-security?toc=%2Fazure%2Fsynapse-analytics%2Fsql-data-warehouse%2Ftoc.json&bc=%2Fazure%2Fsynapse-analytics%2Fsql-data-warehouse%2Fbreadcrumb%2Ftoc.json&view=sql-server-ver16
*/

--Create 2 users for use case demonstration!
CREATE USER DataAnalystSFO WITHOUT LOGIN;
CREATE USER DataAnalystGlobal WITHOUT LOGIN;
--SELECT * FROM sys.sysusers WHERE name in ('DataAnalystGlobal', 'DataAnalystSFO');


/* Security Predicate - Inline table-valued function to determine if the Analyst executing the query belongs to the right geography! 
The function returns 1 when a row in the GeographyKey column is the same as the user executing the query 
(@GeographyKey = USER_NAME()) or if the user executing the query is the DataAnalystGlobal user (USER_NAME() = 'DataAnalystGlobal').
*/

GO
CREATE SCHEMA Security
GO
CREATE FUNCTION Security.fn_securitypredicate(@GeographyKey AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result
    WHERE (USER_NAME() = 'DataAnalystSFO' and @GeographyKey = 360) OR USER_NAME() = 'DataAnalystGlobal'
GO

-- Define security policy that adds the filter predicate to the DimCustomer table to filter rows based on login name.
CREATE SECURITY POLICY SalesFilter  
ADD FILTER PREDICATE Security.fn_securitypredicate (GeographyKey)
ON Sample.DimCustomer
WITH (STATE = ON);

-- Allow SELECT permissions to the Table.
GRANT SELECT ON Sample.DimCustomer TO DataAnalystGlobal, DataAnalystSFO;

-- Validate the access!
-- Only one GeographyKey values
EXECUTE AS USER = 'DataAnalystSFO'
SELECT TOP 100 * FROM Sample.DimCustomer;

-- Multiple GeographyKey values
EXECUTE AS USER = 'DataAnalystGlobal';  
SELECT TOP 100 * FROM Sample.DimCustomer;

/*
CLEAN UP:
ALTER SECURITY POLICY SalesFilter WITH (STATE = OFF);
DROP SECURITY POLICY SalesFilter;
DROP FUNCTION Security.fn_securitypredicate;
DROP SCHEMA Security;
DROP USER DataAnalystSFO;
DROP USER DataAnalystGlobal;
*/