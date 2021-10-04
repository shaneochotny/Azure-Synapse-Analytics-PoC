-- logging.DataProfile DDL for logging the Auto Ingestion steps

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [logging].[DataProfile]
( 
	[Id] [int]  NOT NULL,
	[MasterPipelineId] [nvarchar](50)  NOT NULL,
	[MasterPipelineStartDate] [int]  NOT NULL,
	[MasterPipelineStartDateTime] [datetime2](0)  NOT NULL,
	[SchemaName] [nvarchar](100)  NOT NULL,
	[TableName] [nvarchar](100)  NOT NULL,
	[ColumnName] [nvarchar](100)  NOT NULL,
	[DataTypeName] [nvarchar](100)  NOT NULL,
	[DataTypeFull] [nvarchar](100)  NOT NULL,
	[CharacterLength] [int]  NULL,
	[PrecisionValue] [int]  NULL,
	[ScaleValue] [int]  NULL,
	[UniqueValueCount] [bigint]  NOT NULL,
	[NullCount] [bigint]  NOT NULL,
	[TableRowCount] [bigint]  NOT NULL,
	[TableDataSpaceGB] [numeric](20,2)  NOT NULL,
	[SqlCommand] [nvarchar](max)  NOT NULL,
	[RowInsertDateTime] [datetime2](0)  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX 
	(
		[TableName] ASC
	)
)
GO