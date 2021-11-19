/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Synapse Analytics Workspace
//
//       Create the Synapse Analytics Workspace along with a DWU1000 Dedicated SQL Pool for the Data Warehouse.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param suffix string
param azure_region string
param synapse_sql_pool_name string
param synapse_sql_administrator_login string
param synapse_sql_administrator_login_password string
param synapseStorageAccountDFS string
param logAnalyticsId string
param enable_private_endpoints bool
param private_endpoint_virtual_network string
param private_endpoint_virtual_network_subnet string

// Synapse Workspace
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/overview-what-is
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: 'pocsynapseanalytics-${suffix}'
  location: azure_region
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    publicNetworkAccess: 'Enabled'
    managedVirtualNetwork: 'default'
    defaultDataLakeStorage: {
      accountUrl: synapseStorageAccountDFS
      filesystem: 'config'
    }
    sqlAdministratorLogin: synapse_sql_administrator_login
    sqlAdministratorLoginPassword: synapse_sql_administrator_login_password
  }
}

// Reference to the Storage Account we created
resource synapseStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: 'pocsynapseadls${suffix}'
}

// Azure Data Lake Storage Gen2 Permissions: Give the Synapse Analytics Workspace Managed Identity permissions to Azure Data Lake Storage Gen2
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/roleAssignments
resource synapseStorageWorkspacePermissions 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(synapseWorkspace.id, subscription().subscriptionId, 'Contributor')
  scope: synapseStorageAccount
  properties: {
    principalId: synapseWorkspace.identity.principalId
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }

  dependsOn: [
    synapseWorkspace
  ]
}

// Synapse Workspace Firewall: Allow authenticated access from anywhere if Private Endpoints are disabled
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/firewallrules
resource synapseFirewallAllowAzureServices 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: '${synapseWorkspace.name}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

// Synapse Workspace Firewall: Allow authenticated access from anywhere if Private Endpoints are disabled
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/firewallrules
resource synapseFirewallAllowAll 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: '${synapseWorkspace.name}/AllowAll'
  properties: {
    endIpAddress: '255.255.255.255'
    startIpAddress: '0.0.0.0'
  }
}

// Diagnostic Logs for Synapse
// Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource synapseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: synapseWorkspace
  properties: {
    workspaceId: logAnalyticsId
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
    name: 'DW1000c'
  }

  dependsOn: [
    synapseWorkspace
  ]
}

// Synapse Dedicated SQL Pool Permissions: Give the Synapse Analytics Workspace Managed Identity permissions to pause/resume the Dedicated SQL Pool
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/roleAssignments
resource synapseManagedIdentityPermissions 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(synapseWorkspace.id, subscription().subscriptionId)
  scope: synapseWorkspace
  properties: {
    principalId: synapseWorkspace.identity.principalId
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  } 

  dependsOn: [
    synapseWorkspace
  ]
}

// Synapse Dedicated SQL Pool Diagnostic Logging
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/monitoring/how-to-monitor-using-azure-monitor
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource synapseSQLPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diagnostics'
  scope: synapseSQLPool
  properties: {
    workspaceId: logAnalyticsId
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
  ]
}

// Outputs for reference in the Post-Deployment Configuration
output synapse_analytics_workspace_name string = synapseWorkspace.name
