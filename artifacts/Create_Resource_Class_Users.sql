-- Parquet Auto Ingestion
-- Create Users for different Resource Classes

CREATE USER Userstaticrc10 FOR LOGIN Userstaticrc10; 
GO 
EXEC sp_addrolemember 'db_owner', 'Userstaticrc10';
GO
EXEC sp_addrolemember 'staticrc10', Userstaticrc10
GO

CREATE USER Userstaticrc20 FOR LOGIN Userstaticrc20; 
GO 
EXEC sp_addrolemember 'db_owner', 'Userstaticrc20';
GO
EXEC sp_addrolemember 'staticrc20', Userstaticrc20
GO

CREATE USER Userstaticrc30 FOR LOGIN Userstaticrc30; 
GO 
EXEC sp_addrolemember 'db_owner', 'Userstaticrc30';
GO
EXEC sp_addrolemember 'staticrc30', Userstaticrc30
GO

CREATE USER Userstaticrc40 FOR LOGIN Userstaticrc40; 
GO 
EXEC sp_addrolemember 'db_owner', 'Userstaticrc40';
GO
EXEC sp_addrolemember 'staticrc40', Userstaticrc40
GO

CREATE USER Userstaticrc50 FOR LOGIN Userstaticrc50; 
GO 
EXEC sp_addrolemember 'db_owner', 'Userstaticrc50';
GO
EXEC sp_addrolemember 'staticrc50', Userstaticrc50
GO

CREATE USER Userstaticrc60 FOR LOGIN Userstaticrc60; 
GO 
EXEC sp_addrolemember 'db_owner', 'Userstaticrc60';
GO
EXEC sp_addrolemember 'staticrc60', Userstaticrc60
GO

CREATE USER Userstaticrc70 FOR LOGIN Userstaticrc70; 
GO 
EXEC sp_addrolemember 'db_owner', 'Userstaticrc70';
GO
EXEC sp_addrolemember 'staticrc70', Userstaticrc70
GO

CREATE USER Userstaticrc80 FOR LOGIN Userstaticrc80; 
GO 
EXEC sp_addrolemember 'db_owner', 'Userstaticrc80';
GO
EXEC sp_addrolemember 'staticrc80', Userstaticrc80
GO
