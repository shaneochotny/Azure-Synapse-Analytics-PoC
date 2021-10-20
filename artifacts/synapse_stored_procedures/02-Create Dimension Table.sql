-- Script Name: 02-Create Dimension Table
-- Descriptoin: This script creates the Product Dimension


IF NOT EXISTS (SELECT * FROM sysobjects WHERE NAME = 'DimProduct' AND TYPE = 'U')
CREATE TABLE [dbo].[DimProduct]
( 
	[product_sk] [int]  NULL,
	[product_id] [nvarchar](4000)  NULL,
	[ProductName] [nvarchar](4000)  NULL,
	[ProductSubCategory] [nvarchar](4000)  NULL,
	[ProductCategory] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO