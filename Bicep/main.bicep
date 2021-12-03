/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Azure Synapse Analytics Proof of Concept Architecture: Bicep Template
//
//    Create a Synapse Analytics environment based on best practices to achieve a successful proof of concept. While settings can be adjusted, 
//    the major deployment differences are based on whether or not you used Private Endpoints for connectivity. If you do not already use 
//    Private Endpoints for other Azure deployments, it's discouraged to use them for a proof of concept as they have many other networking 
//    depandancies than what can be configured here.
//
//    Resources:
//
//      Synapse Analytics Workspace:
//          - DW1000 Dedicated SQL Pool
//          - Pipelines to automatically pause and resume the Dedicated SQL Pool on a schedule
//          - Parquet Auto Ingestion pipeline to help ease and optimize data ingestion using best practices
//
//      Azure Data Lake Storage Gen2:
//          - Storage for the Synapse Analytics Workspace configuration data
//          - Storage for the data that's going to be queried on-demand or ingested
//
//      Log Analytics:
//          - Logging for Synapse Analytics
//          - Logging for Azure Data Lake Storage Gen2
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope='subscription'

@description('Region to create all the resources in.')
param azure_region string

@description('Resource Group for all related Azure services.')
param resource_group_name string

@description('Name of the SQL pool to create.')
param synapse_sql_pool_name string

@description('Native SQL account for administration.')
param synapse_sql_administrator_login string

@description('Password for the native SQL admin account above.')
@secure()
param synapse_sql_administrator_login_password string

@description('Object ID (GUID) for the Azure AD administrator of Synapse. This can also be a group, but only one value can be specified. (i.e. XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXXXXXXX). "az ad user show --id "sochotny@microsoft.com" --query objectId --output tsv"')
param synapse_azure_ad_admin_object_id string

@description('If true, create Private Endpoints for Synapse Analytics. This assumes you have other Private Endpoint requirements configured and in place such as virtual networks, VPN/Express Route, and private DNS forwarding.')
param enable_private_endpoints bool

@description('Name of the Virtual Network where you want to create the Private Endpoints. (i.e. vnet-data-platform)')
param private_endpoint_virtual_network string

@description('Name of the Subnet within the Virtual Network where you want to create the Private Endpoints. (i.e. private-endpoint-subnet)')
param private_endpoint_virtual_network_subnet string

@description('Name of the Resource Group that contains the Virtual Network where you want to create the Private Endpoints. (i.e. prod-network)')
param private_endpoint_virtual_network_resource_group string

@description('Name of the Resource Group that contains the Private DNS Zones for Storage and Synapse if Private Endpoints are enabled. (i.e. prod-network)')
param private_endpoint_private_dns_zone_resource_group string

// Add a random suffix to ensure global uniqueness among the resources created
//   Bicep: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#uniquestring
var suffix = '${substring(uniqueString(subscription().subscriptionId, deployment().name), 0, 3)}'

// Create the Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resource_group_name
  location: azure_region
  tags: {
    Environment: 'PoC'
    Application: 'Azure Synapse Analytics'
    Purpose: 'Azure Synapse Analytics Proof of Concept'
  }
}

// Create a Log Analytics Workspace
module logAnalyticsWorkspace 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsWorkspace'
  scope: resourceGroup
  params: {
    suffix: suffix
    azure_region: azure_region
  }
}

// Create the Azure Data Lake Storage Gen2 Account
module synapseStorageAccount 'modules/storageAccount.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup
  params: {
    suffix: suffix
    azure_region: azure_region
    synapse_azure_ad_admin_object_id: synapse_azure_ad_admin_object_id
    logAnalyticsId: logAnalyticsWorkspace.outputs.workspaceId
    enable_private_endpoints: enable_private_endpoints
    private_endpoint_virtual_network: private_endpoint_virtual_network
    private_endpoint_virtual_network_subnet: private_endpoint_virtual_network_subnet
    private_endpoint_virtual_network_resource_group: private_endpoint_virtual_network_resource_group
    private_endpoint_private_dns_zone_resource_group: private_endpoint_private_dns_zone_resource_group
  }

  dependsOn: [
    logAnalyticsWorkspace
  ]
}

// Create the Synapse Analytics Workspace
module synapseAnalytics 'modules/synapseAnalytics.bicep' = {
  name: 'synapseAnalytics'
  scope: resourceGroup
  params: {
    suffix: suffix
    azure_region: azure_region
    synapse_sql_pool_name: synapse_sql_pool_name
    synapse_sql_administrator_login: synapse_sql_administrator_login
    synapse_sql_administrator_login_password: synapse_sql_administrator_login_password
    synapseStorageAccountDFS: synapseStorageAccount.outputs.synapseStorageAccountDFS
    logAnalyticsId: logAnalyticsWorkspace.outputs.workspaceId
    enable_private_endpoints: enable_private_endpoints
    private_endpoint_virtual_network: private_endpoint_virtual_network
    private_endpoint_virtual_network_subnet: private_endpoint_virtual_network_subnet
    private_endpoint_virtual_network_resource_group: private_endpoint_virtual_network_resource_group
    private_endpoint_private_dns_zone_resource_group: private_endpoint_private_dns_zone_resource_group
  }

  dependsOn: [
    logAnalyticsWorkspace
    synapseStorageAccount
  ]
}

// Outputs for reference in the Post-Deployment Configuration
output synapse_sql_pool_name string = synapse_sql_pool_name
output synapse_sql_administrator_login string = synapse_sql_administrator_login
output synapse_sql_administrator_login_password string = synapse_sql_administrator_login_password
output synapse_analytics_workspace_name string = synapseAnalytics.outputs.synapse_analytics_workspace_name
output datalake_name string = synapseStorageAccount.outputs.datalake_name
output datalake_key string = synapseStorageAccount.outputs.datalake_key
output private_endpoints_enabled bool = enable_private_endpoints
