/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Azure Data Lake Storage Gen2
//
//        Storage for the Synapse Workspace configuration data along with any test data for on-demand querying and ingestion.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param suffix string
param azure_region string
param synapse_azure_ad_admin_object_id string
param logAnalyticsId string
param enable_private_endpoints bool
param private_endpoint_virtual_network string
param private_endpoint_virtual_network_subnet string
param private_endpoint_virtual_network_resource_group string
param private_endpoint_private_dns_zone_resource_group string

// Azure Data Lake Storage Gen2: Storage for the Synapse Workspace configuration data and test data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
resource synapseStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'pocsynapseadls${suffix}'
  location: azure_region
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
    networkAcls: {
      bypass: (enable_private_endpoints) ? 'None' : 'AzureServices'
      defaultAction: (enable_private_endpoints) ? 'Deny' : 'Allow'
      resourceAccessRules: [
        {
          resourceId: '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Synapse/workspaces/*'
          tenantId: subscription().tenantId
        }
      ]
    }
    publicNetworkAccess: (enable_private_endpoints) ? 'Disabled' : 'Enabled'
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
  ]
}

// Reference to the Storage Account Blob we created
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
    workspaceId: logAnalyticsId
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
}

// Reference to the existing Virtual Network if Private Endpoints we're enabling Private Endpoints
resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-08-01' existing = if (enable_private_endpoints) {
  name: private_endpoint_virtual_network
  scope: resourceGroup(private_endpoint_virtual_network_resource_group)
}

// Reference to the existing Virtual Network Subnet to create the Private Endpoints if we're enabling them
resource existingVirtualNetworkSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-04-01' existing = if (enable_private_endpoints) {
  parent: existingVirtualNetwork
  name: private_endpoint_virtual_network_subnet
}

// Azure Data Lake Storage Gen2 Blob Private Endpoint
//   Azure: https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.network/privateendpoints
resource synapseStorageAccountBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = if (enable_private_endpoints) {
  name: 'pocsynapsestorage-blob-endpoint'
  location: azure_region
  properties: {
    subnet: {
      id: existingVirtualNetworkSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'pocsynapsestorage-blob-privateserviceconnection'
        properties: {
          privateLinkServiceId: synapseStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// Azure Data Lake Storage Gen2 DFS Private Endpoint
//   Azure: https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.network/privateendpoints
resource synapseStorageAccountDfsPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = if (enable_private_endpoints) {
  name: 'pocsynapsestorage-dfs-endpoint'
  location: azure_region
  properties: {
    subnet: {
      id: existingVirtualNetworkSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'pocsynapsestorage-dfs-privateserviceconnection'
        properties: {
          privateLinkServiceId: synapseStorageAccount.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
  }
}

// Reference to the existing Storage Blob Private DNS Zone if Private Endpoints are enabled so we can auto-register
resource privateDnsZoneBlob 'Microsoft.Network/privateDnsZones@2020-01-01' existing = if (enable_private_endpoints) {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  scope: resourceGroup(private_endpoint_private_dns_zone_resource_group)
}

// Reference to the existing Storage DFS Private DNS Zone if Private Endpoints are enabled so we can auto-register
resource privateDnsZoneDfs 'Microsoft.Network/privateDnsZones@2020-01-01' existing = if (enable_private_endpoints) {
  name: 'privatelink.dfs.${environment().suffixes.storage}'
  scope: resourceGroup(private_endpoint_private_dns_zone_resource_group)
}

// Azure Data Lake Storage Gen2 Blob Private Endpoint DNS Registration
//   Azure: 
//   Bicep: 
resource blobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = if (enable_private_endpoints) {
  parent: synapseStorageAccountBlobPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateDnsZoneBlob.id
        }
      }
    ]
  }
}

// Azure Data Lake Storage Gen2 DFS Private Endpoint DNS Registration
//   Azure: 
//   Bicep: 
resource dfsPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = if (enable_private_endpoints) {
  parent: synapseStorageAccountDfsPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateDnsZoneDfs.id
        }
      }
    ]
  }
}

// Outputs for reference in the Post-Deployment Configuration
output synapseStorageAccountDFS string = synapseStorageAccount.properties.primaryEndpoints.dfs
output datalake_name string = synapseStorageAccount.name
output datalake_key string = listKeys(synapseStorageAccount.id, synapseStorageAccount.apiVersion).keys[0].value
