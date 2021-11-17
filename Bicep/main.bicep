/************************************************************************************************************************************************

  Azure Synapse Analytics Proof of Concept Architecture: Bicep Template

    Create a Synapse Analytics environment based on best practices to achieve a successful proof of concept. While settings can be adjusted, 
    the major deployment differences are based on whether or not you used Private Endpoints for connectivity. If you do not already use 
    Private Endpoints for other Azure deployments, it's discouraged to use them for a proof of concept as they have many other networking 
    depandancies than what can be configured here.

    Resources:

      Synapse Analytics Workspace:
          - DW1000 Dedicated SQL Pool
          - Pipelines to automatically pause and resume the Dedicated SQL Pool on a schedule
          - Parquet Auto Ingestion pipeline to help ease and optimize data ingestion using best practices

      Azure Data Lake Storage Gen2:
          - Storage for the Synapse Analytics Workspace configuration data
          - Storage for the data that's going to be queried on-demand or ingested

      Log Analytics:
          - Logging for Synapse Analytics
          - Logging for Azure Data Lake Storage Gen2

************************************************************************************************************************************************/

param azure_region string
param synapse_sql_pool_name string
param synapse_sql_administrator_login string
param synapse_sql_administrator_login_password string
param synapse_azure_ad_admin_object_id string
param enable_private_endpoints string
param private_endpoint_virtual_network string
param private_endpoint_virtual_network_subnet string

var resource_group_name = 'PoC-Synapse-Analytics-V2'

// Add a random suffix to ensure global uniqueness among the resources created
//   Bicep: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#uniquestring
var suffix = '${substring(uniqueString(resourceGroup().id), 0, 3)}'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Outputs
//
//        We output certain variables that need to be referenced by the configure.sh bash script.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output synapse_sql_pool_name string = synapse_sql_pool_name

output synapse_sql_administrator_login string = synapse_sql_administrator_login

output synapse_sql_administrator_login_password string = synapse_sql_administrator_login_password

output synapse_analytics_workspace_name string = synapseWorkspace.name

output datalake_name string = synapseStorageAccount.name

output datalake_key string = listKeys(synapseStorageAccount.id, synapseStorageAccount.apiVersion).keys[0].value

output private_endpoints_enabled bool = enable_private_endpoints

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Dependancy Lookups
//
//        Lookups to find Private Link DNS zones and Virtual Networks if you are using Private Endpoints. We can do lookups because these 
//        resources are always named the same in every environment and it's easier than manually locating all the resource ID's. If you don't 
//        already have Virtual Networks created, a VPN/Express Route in place, and private DNS forwarding enabled, this will add considerable 
//        complexity.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Azure Data Lake Storage Gen2
//
//        Storage for the Synapse Workspace configuration data along with any test data for on-demand querying and ingestion.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Azure Data Lake Storage Gen2: Storage for the Synapse Workspace configuration data and test data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
resource synapseStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: 'pocsynapseadls${suffix}'
  location: azure_region
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
  }
}

// Storage Container for the Synapse Workspace config data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
resource synapseConfigStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${synapseStorageAccount.name}/default/config'

  dependsOn: [
    synapseStorageAccount
  ]
}

// Storage Container for any data to ingest or query on-demand
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
resource synapseDataStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${synapseStorageAccount.name}/default/data'

  dependsOn: [
    synapseStorageAccount
  ]
}

// Azure Data Lake Storage Gen2 Permissions: Give the synapse_azure_ad_admin_object_id user/group permissions to Azure Data Lake Storage Gen2
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/roleAssignments
resource synapseStorageUserPermissions 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(synapseStorageAccount.id, subscription().subscriptionId)
  scope: synapseStorageAccount
  properties: {
    principalId: synapse_azure_ad_admin_object_id
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }

  dependsOn: [
    synapseStorageAccount
    synapseWorkspace
  ]
}

resource synapseStorageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: synapseStorageAccount
  name: 'default'

  dependsOn: [
    synapseStorageAccount
  ]
}

// Azure Data Lake Storage Gen2 Diagnostic Logging
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/monitor-blob-storage
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource synapseStorageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: synapseStorageAccountBlob
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }

  dependsOn: [
    synapseStorageAccount
    logAnalytics
  ]
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Synapse Analytics Workspace
//
//       Create the Synapse Analytics Workspace along with a DWU1000 Dedicated SQL Pool for the Data Warehouse.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Synapse Workspace
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/overview-what-is
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01-preview' = {
  name: 'pocsynapseanalytics-${suffix}'
  location: azure_region
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    publicNetworkAccess: 'Enabled'
    managedVirtualNetwork: 'default'
    defaultDataLakeStorage: {
      accountUrl: synapseStorageAccount.properties.primaryEndpoints.dfs
      filesystem: 'config'
    }
    sqlAdministratorLogin: synapse_sql_administrator_login
    sqlAdministratorLoginPassword: synapse_sql_administrator_login_password
  }

  dependsOn: [
    synapseStorageAccount
  ]
}

// Azure Data Lake Storage Gen2 Permissions: Give the Synapse Analytics Workspace Managed Identity permissions to Azure Data Lake Storage Gen2
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/roleAssignments
resource synapseStorageWorkspacePermissions 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(synapseWorkspace.id, subscription().subscriptionId)
  scope: synapseStorageAccount
  properties: {
    principalId: synapseWorkspace.identity.principalId
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }

  dependsOn: [
    synapseStorageAccount
    synapseWorkspace
  ]
}

// Synapse Workspace Firewall: Allow authenticated access from anywhere if Private Endpoints are disabled
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/firewallrules
resource synapseFirewallAllowAzureServices 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01-preview' = {
  name: '${synapseWorkspace.name}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

// Diagnostic Logs for Synapse
// Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource synapseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: synapseWorkspace
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'SynapseRbacOperations'
        enabled: true
      }
      {
        category: 'GatewayApiRequests'
        enabled: true
      }
      {
        category: 'BuiltinSqlReqsEnded'
        enabled: true
      }
      {
        category: 'IntegrationPipelineRuns'
        enabled: true
      }
      {
        category: 'IntegrationActivityRuns'
        enabled: true
      }
      {
        category: 'IntegrationTriggerRuns'
        enabled: true
      } 
    ]
  }

  dependsOn: [
    synapseWorkspace
    logAnalytics
  ]
}

// Synapse Dedicated SQL Pool: Create the initial SQL Pool for the Data Warehouse
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/quickstart-create-sql-pool-studio
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/sqlpools
resource synapseSQLPool 'Microsoft.Synapse/workspaces/sqlPools@2021-06-01' = {
  name: synapse_sql_pool_name
  parent: synapseWorkspace
  location: azure_region
  sku: {
    name: 'DW100c'
  }

  dependsOn: [
    synapseWorkspace
  ]
}

// Synapse Dedicated SQL Pool Permissions: Give the Synapse Analytics Workspace Managed Identity permissions to pause/resume the Dedicated SQL Pool
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/roleAssignments
//resource synapseManagedIdentityPermissions 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
//  name: guid(synapseWorkspace.id, subscription().subscriptionId)
//  scope: synapseWorkspace
//  properties: {
//    principalId: synapseWorkspace.identity.principalId
//    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
//  }

//  dependsOn: [
//    synapseWorkspace
//  ]
//}

// Synapse Dedicated SQL Pool Diagnostic Logging
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/monitoring/how-to-monitor-using-azure-monitor
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource synapseSQLPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: synapseSQLPool
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'SqlRequests'
        enabled: true
      }
      {
        category: 'RequestSteps'
        enabled: true
      }
      {
        category: 'ExecRequests'
        enabled: true
      }
      {
        category: 'DmsWorkers'
        enabled: true
      }
      {
        category: 'Waits'
        enabled: true
      }
    ]
  }

  dependsOn: [
    synapseSQLPool
    logAnalytics
  ]
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   Log Analytics Workspace
//
//        Create the Log Analytics Workspace to collect logs and metrics from Azure Synapse Analytics and Azure Data Lake Storage Gen2.
//  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
