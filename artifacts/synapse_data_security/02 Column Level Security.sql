--Use Case: DataAnalystSFO should not have access to birthdate and phone columns of the Customer table
EXECUTE AS USER = 'DataAnalystSFO';  
SELECT TOP 100 * FROM dbo.DimCustomer;

--  Revoke access of DataAnalystSFO to birthdate and phone columns 

REVOKE SELECT ON dbo.DimCustomer FROM DataAnalystSFO;

GRANT SELECT ON dbo.DimCustomer(
[CustomerKey],[GeographyKey],[CustomerAlternateKey],[Title],[FirstName],[MiddleName],[LastName],[NameStyle]
--,[BirthDate],[Phone]
,[MaritalStatus],[Suffix],[Gender],[EmailAddress],[YearlyIncome],[TotalChildren],[NumberChildrenAtHome],[EnglishEducation]
,[SpanishEducation],[FrenchEducation],[EnglishOccupation],[SpanishOccupation],[FrenchOccupation],[HouseOwnerFlag]
,[NumberCarsOwned],[AddressLine1],[AddressLine2],[DateFirstPurchase],[CommuteDistance]
) TO DataAnalystSFO;

-- Check whether DataAnalystSFO has select access to the all columns
EXECUTE AS USER ='DataAnalystSFO';
select TOP 100 * from dbo.DimCustomer;

-- Check whether DataAnalystSFO has select access to the other columns
EXECUTE AS USER ='DataAnalystSFO';
select
[CustomerKey],[GeographyKey],[CustomerAlternateKey],[Title],[FirstName],[MiddleName],[LastName],[NameStyle]
--,[BirthDate],[Phone]
,[MaritalStatus],[Suffix],[Gender],[EmailAddress],[YearlyIncome],[TotalChildren],[NumberChildrenAtHome],[EnglishEducation]
,[SpanishEducation],[FrenchEducation],[EnglishOccupation],[SpanishOccupation],[FrenchOccupation],[HouseOwnerFlag]
,[NumberCarsOwned],[AddressLine1],[AddressLine2],[DateFirstPurchase],[CommuteDistance]
 from dbo.DimCustomer;

-- Check whether DataAnalystGlobal has select access to the all columns
EXECUTE AS USER ='DataAnalystGlobal';
select TOP 100 * from dbo.DimCustomer;

--GRANT SELECT ON dbo.DimCustomer TO DataAnalystSFO;