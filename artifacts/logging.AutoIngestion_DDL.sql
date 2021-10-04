-- logging.AutoIngestion DDL for logging the Auto Ingestion steps

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [logging].[AutoIngestion]
( 
	[Id] [int]  NOT NULL,
	[MasterPipelineId] [varchar](50)  NOT NULL,
	[MasterPipelineStartDate] [int]  NOT NULL,
	[MasterPipelineStartDateTime] [datetime2](0)  NOT NULL,
	[StorageAccountNameMetadata] [nvarchar](1000)  NULL,
	[StorageAccountKeyMetadata] [nvarchar](100)  NULL,
	[StorageAccountKeyData] [nvarchar](100)  NULL,
	[PipelineRunId] [varchar](50)  NOT NULL,
	[PipelineName] [varchar](100)  NOT NULL,
	[SchemaNameStaging] [nvarchar](100)  NULL,
	[TableNameStaging] [nvarchar](100)  NULL,
	[FolderPathFull] [nvarchar](1000)  NULL,
	[SchemaNameTarget] [nvarchar](100)  NULL,
	[TableNameTarget] [nvarchar](100)  NULL,
	[TableDistributionTarget] [nvarchar](100)  NULL,
	[TableIndexTarget] [nvarchar](100)  NULL,
	[ActivityType] [varchar](50)  NOT NULL,
	[SqlCommand] [nvarchar](max)  NOT NULL,
	[RowInsertDateTime] [datetime2](0)  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX 
	(
		[MasterPipelineStartDate] ASC
	)
)
GO