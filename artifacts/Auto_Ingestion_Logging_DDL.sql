-- Logging DDL for logging the Auto Ingestion steps

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = 'logging')
    EXEC ('CREATE SCHEMA [logging]')
GO

IF OBJECT_ID('logging.AutoIngestion', 'U') IS NOT NULL
    DROP TABLE logging.AutoIngestion
;

CREATE TABLE logging.AutoIngestion 
(
	Id INT IDENTITY(1,1) NOT NULL
	,MasterPipelineId VARCHAR(50) NOT NULL
	,MasterPipelineStartDate INT NOT NULL
	,MasterPipelineStartDateTime DATETIME2(0) NOT NULL
	--,MasterPiplineParameters VARCHAR(1000) NOT NULL
	,StorageAccountNameMetadata NVARCHAR(1000) NULL
	,StorageAccountKeyMetadata NVARCHAR(100) NULL
	,StorageAccountKeyData NVARCHAR(100) NULL
	,PipelineRunId VARCHAR(50) NOT NULL
	,PipelineName VARCHAR(100) NOT NULL

	,SchemaNameStaging NVARCHAR(100) NULL
    ,TableNameStaging NVARCHAR(100) NULL
	,FolderPathFull NVARCHAR(1000) NULL
	,SchemaNameTarget NVARCHAR(100) NULL
    ,TableNameTarget NVARCHAR(100) NULL
    ,TableDistributionTarget NVARCHAR(100) NULL
	,TableIndexTarget NVARCHAR(100) NULL

	,ActivityType VARCHAR(50) NOT NULL --ex 'Create Staging Table', 'Copy Into', 'Build Statistics'
	,SqlCommand NVARCHAR(MAX) NOT NULL
    ,RowInsertDateTime DATETIME2(0) NOT NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, CLUSTERED INDEX(MasterPipelineStartDate)
)
GO

/*
DECLARE @CurrentDateTime DATETIME2(0) = GETDATE() 

INSERT INTO logging.AutoLoaderCommands VALUES 
('' /* MasterPipelineId */
,'20210910' /* MasterPipelineStartDate */
,'20210910 10:10:10' /* MasterPipelineStartDateTime */
,'' /* StorageAccountNameMetadata */
,'' /* StorageAccountKeyMetadata */
,'' /* StorageAccountKeyData */
,'' /* BuildStatisticsFlag */
,'' /* PipelineRunId */
,'' /* PipelineName */
,'' /* ActivityType */
,'' /* SchemaName */
,'' /* TableName */
,'' /* SqlCommand */
,@CurrentDateTime /* RowInsertDateTime */
)
*/

IF OBJECT_ID('logging.ServerlessDDL', 'U') IS NOT NULL
    DROP TABLE logging.ServerlessDDL
;

CREATE TABLE logging.ServerlessDDL
(
	Id INT IDENTITY(1,1) NOT NULL
	,MasterPipelineId NVARCHAR(50) NOT NULL
	,MasterPipelineStartDate INT NOT NULL
	,MasterPipelineStartDateTime DATETIME2(0) NOT NULL
	--,PiplineParameters VARCHAR(1000) NOT NULL
	,PipelineRunId VARCHAR(50) NOT NULL
	,StorageAccountNameMetadata NVARCHAR(1000) NOT NULL
	,StorageAccountKeyMetadata NVARCHAR(100) NOT NULL
	,FolderPathFull NVARCHAR(4000) NOT NULL
	,SchemaName NVARCHAR(100) NOT NULL
    ,TableName NVARCHAR(100) NOT NULL
	,SqlCommandCreateExternalTable NVARCHAR(MAX) NOT NULL
	,SqlCommandCreateExternalTableStats NVARCHAR(MAX) NOT NULL
	,SqlCommandCreateView NVARCHAR(MAX) NOT NULL
	,SqlCommandCreateViewStats NVARCHAR(MAX) NOT NULL
    ,RowInsertDateTime DATETIME2(0) NOT NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, CLUSTERED INDEX(MasterPipelineStartDate)
)
GO

/*

DECLARE @CurrentDateTime DATETIME2(0) = GETDATE() 

INSERT INTO logging.ServerlessDDL VALUES 
('' /* MasterPipelineId */
,'20210910' /* MasterPipelineStartDate */
,'20210910 10:10:10' /* MasterPipelineStartDateTime */
,'' /* PipelineRunId */
,'' /* StorageAccountNameMetadata */
,'' /* StorageAccountKeyMetadata */
,'' /* FolderPathFull */
,'' /* SchemaName */
,'' /* TableName */
,'' /* SqlCommandCreateExternalTable */
,'' /* SqlCommandCreateExternalTableStats */
,'' /* SqlCommandCreateView */
,'' /* SqlCommandCreateViewStats */
,@CurrentDateTime /* RowInsertDateTime */
)

*/

IF OBJECT_ID('logging.DataProfile', 'U') IS NOT NULL
    DROP TABLE logging.DataProfile
;

CREATE TABLE logging.DataProfile
(
	Id INT IDENTITY(1,1) NOT NULL
	,MasterPipelineId NVARCHAR(50) NOT NULL
	,MasterPipelineStartDate INT NOT NULL
	,MasterPipelineStartDateTime DATETIME2(0) NOT NULL
    ,SchemaName NVARCHAR(100) NOT NULL
    ,TableName NVARCHAR(100) NOT NULL
	,ColumnName NVARCHAR(100) NOT NULL
	,DataTypeName NVARCHAR(100) NOT NULL
	,DataTypeFull NVARCHAR(100) NOT NULL
	,CharacterLength INT NULL
	,PrecisionValue INT NULL	
	,ScaleValue INT NULL	
	,UniqueValueCount BIGINT NOT NULL
	,NullCount BIGINT NOT NULL
	,TableRowCount BIGINT NOT NULL
	,TableDataSpaceGB NUMERIC(20,2) NOT NULL
	,SqlCommand NVARCHAR(MAX) NOT NULL
    ,RowInsertDateTime DATETIME2(0) NOT NULL
)
WITH (DISTRIBUTION = ROUND_ROBIN, CLUSTERED INDEX(TableName)
)
GO

/*

DECLARE @CurrentDateTime DATETIME2(0) = GETDATE() 

INSERT INTO logging.DataProfile VALUES 
(
'' /* MasterPipelineId */
,'' /* MasterPipelineStartDate */
,'' /* MasterPipelineStartDateTime */
,'stagingTPCH' /* SchemaName */
,'customer' /* TableName */
,'C_ADDRESS' /* ColumnName */
,'' /* DataTypeName */
,'' /* UniqeValueCount */
--,'' /* NullCount */
,'' /* SchemaName */
,'' /* TableName */
,'' /* SqlCommand */
,@CurrentDateTime /* RowInsertDateTime */
)

*/

SELECT 1 AS a