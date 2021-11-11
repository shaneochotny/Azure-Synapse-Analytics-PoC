/************************************************************************************************************************************************

  Variables

        Default variables used to customize the deployment.

************************************************************************************************************************************************/

variable "azure_region" {
  description = "Region to create all the resources in."
}

variable "resource_group_name" {
  description = "Resource Group for all related Azure services."
}

variable "synapse_sql_pool_name" {
  description = "Name of the SQL pool to create."
}

variable "synapse_sql_administrator_login" {
  description = "Native SQL account for administration."
}

variable "synapse_sql_administrator_login_password" {
  description = "Password for the native SQL admin account above."
}

variable "synapse_azure_ad_admin_upn" {
  description = "UserPrincipcalName (UPN) for the Azure AD administrator of Synapse. This can also be a group, but only one value can be specified. (i.e. shane@microsoft.com)"
}

variable "enable_private_endpoints" {
  description = "If true, create Private Endpoints for Synapse Analytics. This assumes you have other Private Endpoint requirements configured and in place such as virtual networks, VPN/Express Route, and private DNS forwarding."
}

variable "private_endpoint_virtual_network" {
  description = "Name of the Virtual Network where you want to create the Private Endpoints."
}

variable "private_endpoint_virtual_network_subnet" {
  description = "Name of the Subnet within the Virtual Network where you want to create the Private Endpoints."
}