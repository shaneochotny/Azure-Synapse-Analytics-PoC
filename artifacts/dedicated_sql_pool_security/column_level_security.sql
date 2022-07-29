/* Use Case: 
    DataAnalystSFO should not have access to birthdate and phone columns
    on the Customer table
*/

-- Create 2 users for use case demonstration!
CREATE USER DataAnalystSFO WITHOUT LOGIN;
CREATE USER DataAnalystGlobal WITHOUT LOGIN;
--SELECT * FROM sys.sysusers WHERE name in ('DataAnalystGlobal', 'DataAnalystSFO');

-- If users already existed, revoke access to Sample.DimCustomer 
REVOKE SELECT ON Sample.DimCustomer FROM DataAnalystSFO, DataAnalystGlobal;

-- Allow DataAnalystGlobal access to all columns on Sample.DimCustomer Table.
GRANT SELECT ON Sample.DimCustomer TO DataAnalystGlobal;

-- Allow DataAnalystSFO access to a subset of columns on Sample.DimCustomer Table.
GRANT SELECT ON Sample.DimCustomer(
[CustomerKey],[GeographyKey],[CustomerAlternateKey],[Title],[FirstName],[MiddleName],[LastName],[NameStyle]
--,[BirthDate],[Phone]
,[MaritalStatus],[Suffix],[Gender],[EmailAddress],[YearlyIncome],[TotalChildren],[NumberChildrenAtHome],[EnglishEducation]
,[SpanishEducation],[FrenchEducation],[EnglishOccupation],[SpanishOccupation],[FrenchOccupation],[HouseOwnerFlag]
,[NumberCarsOwned],[AddressLine1],[AddressLine2],[DateFirstPurchase],[CommuteDistance]
) TO DataAnalystSFO;

-- Check whether DataAnalystSFO has select access to the all columns
EXECUTE AS USER ='DataAnalystSFO';
select TOP 100 * from Sample.DimCustomer;

-- Check whether DataAnalystSFO has select access to the other columns
EXECUTE AS USER ='DataAnalystSFO';
select TOP 100
[CustomerKey],[GeographyKey],[CustomerAlternateKey],[Title],[FirstName],[MiddleName],[LastName],[NameStyle]
--,[BirthDate],[Phone]
,[MaritalStatus],[Suffix],[Gender],[EmailAddress],[YearlyIncome],[TotalChildren],[NumberChildrenAtHome],[EnglishEducation]
,[SpanishEducation],[FrenchEducation],[EnglishOccupation],[SpanishOccupation],[FrenchOccupation],[HouseOwnerFlag]
,[NumberCarsOwned],[AddressLine1],[AddressLine2],[DateFirstPurchase],[CommuteDistance]
 from Sample.DimCustomer;

-- Check whether DataAnalystGlobal has select access to the all columns
EXECUTE AS USER ='DataAnalystGlobal';
select TOP 100 * from Sample.DimCustomer;

/*
CLEAN UP:
DROP USER DataAnalystSFO;
DROP USER DataAnalystGlobal;
*/