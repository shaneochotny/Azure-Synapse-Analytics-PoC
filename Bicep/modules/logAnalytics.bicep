/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   Log Analytics Workspace
//
//        Create the Log Analytics Workspace to collect logs and metrics from Azure Synapse Analytics and Azure Data Lake Storage Gen2.
//  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param suffix string
param azure_region string

// Create a Log Analytics Workspace
//   Azure: https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-platform-logs
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'poc-synapse-analytics-loganalytics-${suffix}'
  location: azure_region

  properties: { 
    retentionInDays: 180
  }
}

output workspaceId string = logAnalytics.id
