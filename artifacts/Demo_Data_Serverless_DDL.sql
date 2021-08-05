-- Demo Datasets for Synapse Serverless SQL Pool
-- https://docs.microsoft.com/en-us/azure/open-datasets/overview-what-are-open-datasets

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Pass@word123';
GO

CREATE EXTERNAL DATA SOURCE PandemicDataLake WITH (
    LOCATION = 'https://pandemicdatalake.blob.core.windows.net'
);
GO

CREATE EXTERNAL DATA SOURCE AzureOpenDataStorage WITH (
    LOCATION = 'https://azureopendatastorage.blob.core.windows.net'
);
GO

-- https://docs.microsoft.com/en-us/azure/open-datasets/dataset-bing-covid-19
CREATE VIEW Bing_COVID19
AS SELECT *
FROM
    OPENROWSET(
        BULK '/public/curated/covid-19/bing_covid-19_data/latest/bing_covid-19_data.parquet',
        DATA_SOURCE = 'PandemicDataLake',
        FORMAT='PARQUET'
    ) AS covid;
GO

-- https://docs.microsoft.com/en-us/azure/open-datasets/dataset-public-holidays
CREATE VIEW Public_Holidays
AS SELECT *
FROM
    OPENROWSET(
        BULK '/holidaydatacontainer/Processed/*.parquet',
        DATA_SOURCE = 'AzureOpenDataStorage',
        FORMAT='PARQUET'
    ) AS holidays;
GO

-- https://docs.microsoft.com/en-us/azure/open-datasets/dataset-new-york-city-safety
CREATE VIEW NYC_Safety_Data
AS SELECT *
FROM
    OPENROWSET(
        BULK '/citydatacontainer/Safety/Release/city=NewYorkCity/*.parquet',
        DATA_SOURCE = 'AzureOpenDataStorage',
        FORMAT='PARQUET'
    ) AS nyc;
GO

-- https://docs.microsoft.com/en-us/azure/open-datasets/dataset-us-local-unemployment
CREATE VIEW Local_Area_Unemployment
AS SELECT *
FROM
    OPENROWSET(
        BULK '/laborstatisticscontainer/laus/*.parquet',
        DATA_SOURCE = 'AzureOpenDataStorage',
        FORMAT='PARQUET'
    ) AS unemployment;
GO

-- https://docs.microsoft.com/en-us/azure/open-datasets/dataset-us-state-employment-earnings
CREATE VIEW US_State_Employment
AS SELECT *
FROM
    OPENROWSET(
        BULK '/laborstatisticscontainer/ehe_state/*.parquet',
        DATA_SOURCE = 'AzureOpenDataStorage',
        FORMAT='PARQUET'
    ) AS employment;
GO