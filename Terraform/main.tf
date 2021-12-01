/************************************************************************************************************************************************

  Azure Synapse Analytics Proof of Concept Architecture: Terraform Template

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

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.79.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  use_msi = false
}

data "azurerm_client_config" "current" {}

// Add a random suffix to ensure global uniqueness among the resources created
//   Terraform: https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "suffix" {
  length  = 3
  upper   = false
  special = false
}

/************************************************************************************************************************************************

  Outputs

        We output certain variables that need to be referenced by the configure.sh bash script.

************************************************************************************************************************************************/

output "synapse_sql_pool_name" {
  value = var.synapse_sql_pool_name
}

output "synapse_sql_administrator_login" {
  value = var.synapse_sql_administrator_login
}

output "synapse_sql_administrator_login_password" {
  value = var.synapse_sql_administrator_login_password
}

output "synapse_analytics_workspace_name" {
  value = "pocsynapseanalytics-${random_string.suffix.id}"
}

output "synapse_analytics_workspace_resource_group" {
  value = var.resource_group_name
}

output "datalake_name" {
  value = "pocsynapseadls${random_string.suffix.id}"
}

output "datalake_key" {
  value     = azurerm_storage_account.datalake.primary_access_key
  sensitive = true
}

output "private_endpoints_enabled" {
  value = var.enable_private_endpoints
}

/************************************************************************************************************************************************

  Dependancy Lookups

        Lookups to find Private Link DNS zones and Virtual Networks if you are using Private Endpoints. We can do lookups because these 
        resources are always named the same in every environment and it's easier than manually locating all the resource ID's. If you don't 
        already have Virtual Networks created, a VPN/Express Route in place, and private DNS forwarding enabled, this will add considerable 
        complexity.

************************************************************************************************************************************************/

// Lookup the Azure AD Object ID of the Synapse Admin UPN
//   Azure: https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/add-users-azure-active-directory
//   Terraform: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user
data "azuread_user" "synapse_azure_ad_admin_object_id" {
  user_principal_name = var.synapse_azure_ad_admin_upn
}

// Lookup the Virtual Network where the Private Endpoints will be created
//   Azure: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resources
data "azurerm_resources" "private_endpoint_virtual_network" {
  name = var.private_endpoint_virtual_network
  type = "Microsoft.Network/virtualNetworks"
}

// Lookup the Private DNS Zone for the Azure Data Lake Storage Gen2 Blob endpoint
//   Azure: https://docs.microsoft.com/en-us/azure/dns/private-dns-privatednszone
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resources
data "azurerm_resources" "adls-blob-privatelink-dns" {
  name = "privatelink.blob.core.windows.net"
  type = "Microsoft.Network/privateDnsZones"
}

// Lookup the Private DNS Zone for the Azure Data Lake Storage Gen2 DFS endpoint
//   Azure: https://docs.microsoft.com/en-us/azure/dns/private-dns-privatednszone
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resources
data "azurerm_resources" "adls-dfs-privatelink-dns" {
  name = "privatelink.dfs.core.windows.net"
  type = "Microsoft.Network/privateDnsZones"
}

// Lookup the Private DNS Zone for Azure Synapse Analytics Workspace
//   Azure: https://docs.microsoft.com/en-us/azure/dns/private-dns-privatednszone
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resources
data "azurerm_resources" "synapse-dev-privatelink-dns" {
  name = "privatelink.dev.azuresynapse.net"
  type = "Microsoft.Network/privateDnsZones"
}

// Lookup the Private DNS Zone for Azure Synapse Analytics SQL
//   Azure: https://docs.microsoft.com/en-us/azure/dns/private-dns-privatednszone
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resources
data "azurerm_resources" "synapse-sql-privatelink-dns" {
  name = "privatelink.sql.azuresynapse.net"
  type = "Microsoft.Network/privateDnsZones"
}

/************************************************************************************************************************************************
  Resource Group
        All of the resources will be created in this Resource Group.
************************************************************************************************************************************************/

//  Create the Resource Group
//   Azure: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.azure_region

  tags = {
    Environment = "PoC"
    Application = "Azure Synapse Analytics"
    Purpose     = "Azure Synapse Analytics Proof of Concept"
  }
}

/************************************************************************************************************************************************

  Azure Data Lake Storage Gen2

        Storage for the Synapse Workspace configuration data along with any test data for on-demand querying and ingestion.

************************************************************************************************************************************************/

// Azure Data Lake Storage Gen2: Storage for the Synapse Workspace configuration data and test data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account
resource "azurerm_storage_account" "datalake" {
  name                     = "pocsynapseadls${random_string.suffix.id}"
  resource_group_name      = var.resource_group_name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"

  depends_on = [ azurerm_resource_group.resource_group ]
}

// Azure Data Lake Storage Gen2 Permissions: Give the synapse_azure_ad_admin_upn user/group permissions to Azure Data Lake Storage Gen2
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
resource "azurerm_role_assignment" "adls-user-permissions" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_user.synapse_azure_ad_admin_object_id.id

  depends_on = [ azurerm_storage_account.datalake ]
}

// Storage Container for the Synapse Workspace config data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_data_lake_gen2_filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "datalake-config" {
  name               = "config"
  storage_account_id = azurerm_storage_account.datalake.id
  
  depends_on = [ azurerm_storage_account.datalake, azurerm_role_assignment.adls-user-permissions ]
}

// Storage Container for any data to ingest or query on-demand
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_data_lake_gen2_filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "datalake-data" {
  name               = "data"
  storage_account_id = azurerm_storage_account.datalake.id
  
  depends_on = [ azurerm_storage_account.datalake, azurerm_role_assignment.adls-user-permissions ]
}

// Azure Data Lake Storage Gen2 Diagnostic Logging
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/monitor-blob-storage
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting
resource "azurerm_monitor_diagnostic_setting" "adlsdiagnostics" {
  name                       = "Diagnostics"
  target_resource_id         = "${azurerm_storage_account.datalake.id}/blobServices/default/"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.loganalytics.id

  log {
    category = "StorageRead"
  }

  log {
    category = "StorageWrite"
  }

  log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
  }

  depends_on = [ azurerm_storage_account.datalake, azurerm_log_analytics_workspace.loganalytics ]
}

// Create a Private Endpoint for Blob
//   Azure: https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
resource "azurerm_private_endpoint" "adlspe-blob" {
  count               = var.enable_private_endpoints == true ? 1 : 0
  name                = "pocsynapsestorage-blob-endpoint"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  subnet_id           = "${data.azurerm_resources.private_endpoint_virtual_network.resources[0].id}/subnets/${var.private_endpoint_virtual_network_subnet}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [ data.azurerm_resources.adls-blob-privatelink-dns.resources[0].id ]
  }

  private_service_connection {
    name                           = "pocsynapsestorage-blob-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.datalake.id
    subresource_names              = [ "blob" ]
    is_manual_connection           = false
  }

  depends_on = [ azurerm_role_assignment.adls-user-permissions ]
}

// Create a Private Endpoint for DFS
//   Azure: https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
resource "azurerm_private_endpoint" "adlspe-dfs" {
  count               = var.enable_private_endpoints == true ? 1 : 0
  name                = "pocsynapsestorage-dfs-endpoint"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  subnet_id           = "${data.azurerm_resources.private_endpoint_virtual_network.resources[0].id}/subnets/${var.private_endpoint_virtual_network_subnet}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [ data.azurerm_resources.adls-dfs-privatelink-dns.resources[0].id ]
  }

  private_service_connection {
    name                           = "pocsynapsestorage-dfs-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.datalake.id
    subresource_names              = [ "dfs" ]
    is_manual_connection           = false
  }

  depends_on = [ azurerm_role_assignment.adls-user-permissions ]
}

// Storage Firewall: Give the Synapse Analytics Workspace network access to Azure Data Lake Storage Gen2 if Private Endpoints are enabled
//   Azure: https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal#grant-access-from-azure-resource-instances-preview
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules
resource "azurerm_storage_account_network_rules" "firewall" {
  count                = var.enable_private_endpoints == true ? 1 : 0
  storage_account_id   = azurerm_storage_account.datalake.id
  default_action       = "Deny"
  bypass               = [ "None" ]

  private_link_access { 
    endpoint_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourcegroups/${var.resource_group_name}/providers/Microsoft.Synapse/workspaces/*"
    endpoint_tenant_id   = data.azurerm_client_config.current.tenant_id
 }

  depends_on = [ azurerm_private_endpoint.adlspe-blob, azurerm_private_endpoint.adlspe-dfs ]
}

/************************************************************************************************************************************************

  Synapse Analytics Workspace

        Create the Synapse Analytics Workspace along with a DWU1000 Dedicated SQL Pool for the Data Warehouse.

************************************************************************************************************************************************/

// Synapse Workspace
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/overview-what-is
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/synapse_workspace
resource "azurerm_synapse_workspace" "synapsews" {
  name                                 = "pocsynapseanalytics-${random_string.suffix.id}"
  resource_group_name                  = var.resource_group_name
  location                             = var.azure_region
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.datalake-config.id
  sql_identity_control_enabled         = true
  sql_administrator_login              = var.synapse_sql_administrator_login
  sql_administrator_login_password     = var.synapse_sql_administrator_login_password
  managed_virtual_network_enabled      = true

  aad_admin {
    login     = var.synapse_azure_ad_admin_upn
    object_id = data.azuread_user.synapse_azure_ad_admin_object_id.id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }

  depends_on = [ azurerm_storage_account.datalake ]
}

// Azure Data Lake Storage Gen2 Permissions: Give the Synapse Analytics Workspace Managed Identity permissions to Azure Data Lake Storage Gen2
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
resource "azurerm_role_assignment" "adls-synapse-managed-identity" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapsews.identity[0].principal_id

  depends_on = [ azurerm_storage_account.datalake, azurerm_synapse_workspace.synapsews ]
}

// Synapse Workspace Firewall: Allow Azure services and resources to access this workspace if Private Endpoints are disabled
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/synapse_firewall_rule
resource "azurerm_synapse_firewall_rule" "synapse-workspace-firewall-allow-azure" {
  count                = var.enable_private_endpoints == true ? 0 : 1
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.synapsews.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

// Synapse Workspace Firewall: Allow authenticated access from anywhere if Private Endpoints are disabled
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/synapse_firewall_rule
resource "azurerm_synapse_firewall_rule" "synapse-workspace-firewall-allow-all" {
  count                = var.enable_private_endpoints == true ? 0 : 1
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.synapsews.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

// Synapse Workspace Diagnostic Logging
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/monitoring/how-to-monitor-using-azure-monitor
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting
resource "azurerm_monitor_diagnostic_setting" "synapse-workspace-diagnostics" {
  name                       = "Diagnostics"
  target_resource_id         = azurerm_synapse_workspace.synapsews.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.loganalytics.id

  log {
    category = "SynapseRbacOperations"
  }

  log {
    category = "GatewayApiRequests"
  }

  log {
    category = "BuiltinSqlReqsEnded"
  }

  log {
    category = "IntegrationPipelineRuns"
  }

  log {
    category = "IntegrationActivityRuns"
  }

  log {
    category = "IntegrationTriggerRuns"
  }

  depends_on = [ azurerm_log_analytics_workspace.loganalytics, azurerm_synapse_workspace.synapsews ]
}

// Synapse Dedicated SQL Pool: Create the initial SQL Pool for the Data Warehouse
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/quickstart-create-sql-pool-studio
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/synapse_sql_pool
resource "azurerm_synapse_sql_pool" "synapsesqlpool" {
  name                 = var.synapse_sql_pool_name
  synapse_workspace_id = azurerm_synapse_workspace.synapsews.id
  sku_name             = "DW1000c"
  create_mode          = "Default"

  depends_on = [ azurerm_synapse_workspace.synapsews ]
}

// Synapse Dedicated SQL Pool Permissions: Give the Synapse Analytics Workspace Managed Identity permissions to pause/resume the Dedicated SQL Pool
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
resource "azurerm_role_assignment" "synapse-managed-identity" {
  scope                = azurerm_synapse_workspace.synapsews.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_synapse_workspace.synapsews.identity[0].principal_id

  depends_on = [ azurerm_synapse_workspace.synapsews ]
}

// Synapse Dedicated SQL Pool Diagnostic Logging
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/monitoring/how-to-monitor-using-azure-monitor
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting
resource "azurerm_monitor_diagnostic_setting" "synapse-dedicated-sql-pool-diagnostics" {
  name                       = "Diagnostics"
  target_resource_id         = azurerm_synapse_sql_pool.synapsesqlpool.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.loganalytics.id

  log {
    category = "SqlRequests"
  }

  log {
    category = "RequestSteps"
  }

  log {
    category = "ExecRequests"
  }

  log {
    category = "DmsWorkers"
  }

  log {
    category = "Waits"
  }

  depends_on = [ azurerm_log_analytics_workspace.loganalytics, azurerm_synapse_sql_pool.synapsesqlpool ]
}

// Create a Private Endpoint for SQL Dedicated Pools
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-connect-to-workspace-with-private-links
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
resource "azurerm_private_endpoint" "synapse-sql" {
  count               = var.enable_private_endpoints == true ? 1 : 0
  name                = "pocsynapseanalytics-sql-endpoint"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  subnet_id           = "${data.azurerm_resources.private_endpoint_virtual_network.resources[0].id}/subnets/${var.private_endpoint_virtual_network_subnet}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [ data.azurerm_resources.synapse-sql-privatelink-dns.resources[0].id ]
  }

  private_service_connection {
    name                           = "pocsynapseanalytics-sql-privateserviceconnection"
    private_connection_resource_id = azurerm_synapse_workspace.synapsews.id
    subresource_names              = [ "Sql" ]
    is_manual_connection           = false
  }
}

// Create a Private Endpoint for SQL Serverless
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-connect-to-workspace-with-private-links
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
resource "azurerm_private_endpoint" "synapse-sqlondemand" {
  count               = var.enable_private_endpoints == true ? 1 : 0
  name                = "pocsynapseanalytics-sqlondemand-endpoint"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  subnet_id           = "${data.azurerm_resources.private_endpoint_virtual_network.resources[0].id}/subnets/${var.private_endpoint_virtual_network_subnet}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [ data.azurerm_resources.synapse-sql-privatelink-dns.resources[0].id ]
  }

  private_service_connection {
    name                           = "pocsynapseanalytics-sqlondemand-privateserviceconnection"
    private_connection_resource_id = azurerm_synapse_workspace.synapsews.id
    subresource_names              = [ "SqlOnDemand" ]
    is_manual_connection           = false
  }
}

// Create a Private Endpoint for Synapse Workspace
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-connect-to-workspace-with-private-links
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
resource "azurerm_private_endpoint" "synapse-dev" {
  count               = var.enable_private_endpoints == true ? 1 : 0
  name                = "pocsynapseanalytics-dev-endpoint"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  subnet_id           = "${data.azurerm_resources.private_endpoint_virtual_network.resources[0].id}/subnets/${var.private_endpoint_virtual_network_subnet}"

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [ data.azurerm_resources.synapse-dev-privatelink-dns.resources[0].id ]
  }

  private_service_connection {
    name                           = "pocsynapseanalytics-dev-privateserviceconnection"
    private_connection_resource_id = azurerm_synapse_workspace.synapsews.id
    subresource_names              = [ "Dev" ]
    is_manual_connection           = false
  }
}

/************************************************************************************************************************************************

   Log Analytics Workspace

        Create the Log Analytics Workspace to collect logs and metrics from Azure Synapse Analytics and Azure Data Lake Storage Gen2.
  
************************************************************************************************************************************************/

// Create a Log Analytics Workspace
//   Azure: https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-platform-logs
//   Terraform: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace
resource "azurerm_log_analytics_workspace" "loganalytics" {
  name                = "poc-synapse-analytics-loganalytics-${random_string.suffix.id}"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  sku                 = "PerGB2018"
  retention_in_days   = 180

  depends_on = [ azurerm_resource_group.resource_group ]
}
