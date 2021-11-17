#!/bin/bash
#
# This script is in two parts; Synapse Environment Deployment and Post-Deployment Configuration.
#
#   Part 1: Synapse Environment Deployment
#
#       This simply calls the Terraform or Bicep deployment commands for us. This is only to help make the PoC deployment as
#       simple as possible by giving you a single command to execute. You wouldn't normally invoke a Terraform or Bicep
#       deployment of Synapse via a bash script like this, but we had to balance giving you a simple PoC deployment path along
#       with providing Terraform and Bicep templates for reuse. That said, the terraform and Bicep templates are created using 
#       best practices and can be deployed manually. We realize that some people interested in a Synapse PoC environment, and 
#       some are interested in just having the deployment templates.
#
#    Part 2: Post-Deployment Configuration
#
#       These are post-deployment configurations done at the data plan level which is beyond the scope of what Terraform and 
#       Bicep are capable of managing or would normally manage. Database settings are made, sample data is ingested, and 
#       pipelines are created for the PoC.

#
# Part 1: Synapse Environment Deployment
#

resourceGroup="PoC-Synapse-Analytics-V2"

# Set the default deployment type to Bicep if not specified
deploymentTypeArgument=$1
if [ "$deploymentTypeArgument" != "terraform" ] && [ "$deploymentTypeArgument" != "bicep" ]; then
    deploymentTypeArgument="bicep"
fi

# Make sure this configuration script hasn't been executed already
if [ -f "configure.complete" ]; then
    echo "ERROR: It appears this configuration has already been completed.";
    exit 1;
fi

# Try and determine if we're executing from within the Azure Cloud Shell
if [ ! "${AZUREPS_HOST_ENVIRONMENT}" = "cloud-shell/1.0" ]; then
    echo "ERROR: It doesn't appear like your executing this from the Azure Cloud Shell. Please use the Azure Cloud Shell at https://shell.azure.com";
    exit 1;
fi

# Try and get a token to validate that we're logged into Azure CLI
aadToken=$(az account get-access-token --resource=https://dev.azuresynapse.net --query accessToken --output tsv 2>&1)
if echo "$aadToken" | grep -q "ERROR"; then
    echo "ERROR: You don't appear to be logged in to Azure CLI. Please login to the Azure CLI using 'az login'";
    exit 1;
fi

# Get environment details
azureSubscriptionName=$(az account show --query name --output tsv 2>&1)
azureSubscriptionID=$(az account show --query id --output tsv 2>&1)
azureUsername=$(az account show --query user.name --output tsv 2>&1)
azureUsernameObjectId=$(az ad user show --id $azureUsername --query objectId --output tsv 2>&1)
echo "Azure Subscription: ${azureSubscriptionName}"
echo "Azure Subscription ID: ${azureSubscriptionID}"
echo "Azure AD Username: ${azureUsername}"

# Update a few Terraform and Bicep variables if they aren't configured by the user
sed -i "s/REPLACE_SYNAPSE_AZURE_AD_ADMIN_UPN/${azureUsername}/g" Terraform/terraform.tfvars.json
sed -i "s/REPLACE_SYNAPSE_AZURE_AD_ADMIN_OBJECT_ID/${azureUsernameObjectId}/g" Bicep/main.parameters.json

# 'bash deploy.sh terraform' = Execute Part 2 only. User executed Terraform manually.
# 'bash deploy.sh bicep' = Execute Part 2 only. User executed Bicep manually.
# 'bash deploy.sh' = Run the Bicep deployment and then execute Part 2 (Easy Button).

# If a Terraform deployment is specified, check to see if Terraform was actually run
if [ "$deploymentTypeArgument" == "terraform" ] && [ ! -f "Terraform/terraform.tfstate" ]; then
    echo "ERROR: You specified a 'terraform' deployment but it does not appear that you have run the terraform deployment commands.";
    exit 1;
fi

# If a deployment type wasn't specified, default to Bicep and deploy the environment for them
bicepDeployment=$(az deployment group show --resource-group ${resourceGroup} --name PoC 2>&1)
if [ "$1" == "" ] && [ echo "$bicepDeployment" | grep -q "could not be found" ]; then
    az deployment group create --template-file Bicep/main.bicep --parameters Bicep/main.parameters.json --resource-group ${resourceGroup} --name PoC
fi

#
# Part 2: Post-Deployment Configuration
#

# Get the output variables from Terraform
if [ "$deploymentTypeArgument" == "terraform" ]; then
    synapseAnalyticsWorkspaceName=$(terraform output -raw synapse_analytics_workspace_name 2>&1)
    synapseAnalyticsSQLPoolName=$(terraform output -raw synapse_sql_pool_name 2>&1)
    synapseAnalyticsSQLAdmin=$(terraform output -raw synapse_sql_administrator_login 2>&1)
    synapseAnalyticsSQLAdminPassword=$(terraform output -raw synapse_sql_administrator_login_password 2>&1)
    datalakeName=$(terraform output -raw datalake_name 2>&1)
    datalakeKey=$(terraform output -raw datalake_key 2>&1)
    privateEndpointsEnabled=$(terraform output -raw private_endpoints_enabled 2>&1)
fi

# Get the output variables from Bicep
if [ "$deploymentTypeArgument" == "bicep" ]; then
    synapseAnalyticsWorkspaceName=$(az deployment group show --resource-group ${resourceGroup} --name PoC --query properties.outputs.synapse_analytics_workspace_name.value 2>&1)
    synapseAnalyticsSQLPoolName=$(az deployment group show --resource-group ${resourceGroup} --name PoC --query properties.outputs.synapse_sql_pool_name.value 2>&1)
    synapseAnalyticsSQLAdmin=$(az deployment group show --resource-group ${resourceGroup} --name PoC --query properties.outputs.synapse_sql_administrator_login.value 2>&1)
    synapseAnalyticsSQLAdminPassword=$(az deployment group show --resource-group ${resourceGroup} --name PoC --query properties.outputs.synapse_sql_administrator_login_password.value 2>&1)
    datalakeName=$(az deployment group show --resource-group ${resourceGroup} --name PoC --query properties.outputs.datalake_name.value 2>&1)
    datalakeKey=$(az deployment group show --resource-group ${resourceGroup} --name PoC --query properties.outputs.datalake_key.value 2>&1)
    privateEndpointsEnabled=$(az deployment group show --resource-group ${resourceGroup} --name PoC --query properties.outputs.private_endpoints_enabled.value 2>&1)
fi

echo "Synapse Analytics Workspace Resource Group: ${resourceGroup}"
echo "Synapse Analytics Workspace: ${synapseAnalyticsWorkspaceName}"
echo "Synapse Analytics SQL Admin: ${synapseAnalyticsSQLAdmin}"
echo "Data Lake Name: ${datalakeName}"

# If Private Endpoints are enabled, temporarily disable the firewalls so we can copy files and perform additional configuration
if echo "$privateEndpointsEnabled" | grep -q "true"; then
    az storage account update --name ${datalakeName} --resource-group ${resourceGroup} --default-action Allow --only-show-errors -o none
    az synapse workspace firewall-rule create --name AllowAllWindowsAzureIps --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --only-show-errors -o none
fi

# Enable Result Set Cache
echo "Enabling Result Set Caching..."
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d master -I -Q "ALTER DATABASE ${synapseAnalyticsSQLPoolName} SET RESULT_SET_CACHING ON;"

echo "Creating the auto pause/resume pipeline..."

# Copy the Auto_Pause_and_Resume Pipeline template and update the variables
cp artifacts/Auto_Pause_and_Resume.json.tmpl artifacts/Auto_Pause_and_Resume.json 2>&1
sed -i "s/REPLACE_SUBSCRIPTION/${azureSubscriptionID}/g" artifacts/Auto_Pause_and_Resume.json
sed -i "s/REPLACE_RESOURCE_GROUP/${resourceGroup}/g" artifacts/Auto_Pause_and_Resume.json
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_WORKSPACE_NAME/${synapseAnalyticsWorkspaceName}/g" artifacts/Auto_Pause_and_Resume.json
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_SQL_POOL_NAME/${synapseAnalyticsSQLPoolName}/g" artifacts/Auto_Pause_and_Resume.json

# Create the Auto_Pause_and_Resume Pipeline in the Synapse Analytics Workspace
az synapse pipeline create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name "Auto Pause and Resume" --file @artifacts/Auto_Pause_and_Resume.json

# Create the Pause/Resume triggers in the Synapse Analytics Workspace
az synapse trigger create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name Pause --file @artifacts/triggerPause.json.tmpl
az synapse trigger create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name Resume --file @artifacts/triggerResume.json.tmpl

echo "Creating the parquet auto ingestion pipeline..."

# Create the logging schema and tables for the Auto Ingestion pipeline
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d ${synapseAnalyticsSQLPoolName} -I -i artifacts/Auto_Ingestion_Logging_DDL.sql > /dev/null 2>&1

# Create the Resource Class Logins
cp artifacts/Create_Resource_Class_Logins.sql.tmpl artifacts/Create_Resource_Class_Logins.sql 2>&1
sed -i "s/REPLACE_PASSWORD/${synapseAnalyticsSQLAdminPassword}/g" artifacts/Create_Resource_Class_Logins.sql
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d master -I -i artifacts/Create_Resource_Class_Logins.sql

# Create the Resource Class Users
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_SQL_POOL_NAME/${synapseAnalyticsSQLPoolName}/g" artifacts/Create_Resource_Class_Users.sql
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d ${synapseAnalyticsSQLPoolName} -I -i artifacts/Create_Resource_Class_Users.sql

# Create the LS_Synapse_Managed_Identity Linked Service. This is primarily used for the Auto Ingestion pipeline.
cp artifacts/LS_Synapse_Managed_Identity.json.tmpl artifacts/LS_Synapse_Managed_Identity.json 2>&1
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_WORKSPACE_NAME/${synapseAnalyticsWorkspaceName}/g" artifacts/LS_Synapse_Managed_Identity.json
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_SQL_POOL_NAME/${synapseAnalyticsSQLPoolName}/g" artifacts/LS_Synapse_Managed_Identity.json
az synapse linked-service create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name LS_Synapse_Managed_Identity --file @artifacts/LS_Synapse_Managed_Identity.json

# Create the DS_Synapse_Managed_Identity Dataset. This is primarily used for the Auto Ingestion pipeline.
cp artifacts/DS_Synapse_Managed_Identity.json.tmpl artifacts/DS_Synapse_Managed_Identity.json 2>&1
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_WORKSPACE_NAME/${synapseAnalyticsWorkspaceName}/g" artifacts/DS_Synapse_Managed_Identity.json
az synapse dataset create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name DS_Synapse_Managed_Identity --file @artifacts/DS_Synapse_Managed_Identity.json

# Copy the Parquet Auto Ingestion Pipeline template and update the variables
cp artifacts/Parquet_Auto_Ingestion.json.tmpl artifacts/Parquet_Auto_Ingestion.json 2>&1
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_WORKSPACE_NAME/${synapseAnalyticsWorkspaceName}/g" artifacts/Parquet_Auto_Ingestion.json
sed -i "s/REPLACE_DATALAKE_NAME/${datalakeName}/g" artifacts/Parquet_Auto_Ingestion.json
sed -i "s#REPLACE_DATALAKE_KEY#${datalakeKey}#g" artifacts/Parquet_Auto_Ingestion.json
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_SQL_POOL_NAME/${synapseAnalyticsSQLPoolName}/g" artifacts/Parquet_Auto_Ingestion.json

# Update the Parquet Auto Ingestion Metadata file tamplate with the correct storage account and then upload it
sed -i "s/REPLACE_DATALAKE_NAME/${datalakeName}/g" artifacts/Parquet_Auto_Ingestion_Metadata.csv
az storage copy --only-show-errors -o none --destination https://${datalakeName}.blob.core.windows.net/data/ --source artifacts/Parquet_Auto_Ingestion_Metadata.csv > /dev/null 2>&1

# Copy sample data for the Parquet Auto Ingestion pipeline
az storage copy --only-show-errors -o none --destination https://${datalakeName}.blob.core.windows.net/data/Sample/Bing_COVID19/ --source https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/bing_covid-19_data/latest/bing_covid-19_data.parquet > /dev/null 2>&1
az storage copy --only-show-errors -o none --destination https://${datalakeName}.blob.core.windows.net/data/Sample/Public_Holidays/ --source https://azureopendatastorage.blob.core.windows.net/holidaydatacontainer/Processed/* > /dev/null 2>&1

# Create the Auto_Pause_and_Resume Pipeline in the Synapse Analytics Workspace
az synapse pipeline create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name "Parquet Auto Ingestion" --file @artifacts/Parquet_Auto_Ingestion.json

echo "Creating the Demo Data database using Synapse Serverless SQL..."

# Create a Demo Data database using Synapse Serverless SQL
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d master -I -Q "CREATE DATABASE [Demo Data (Serverless)];"

# Create the Views over the external data
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d "Demo Data (Serverless)" -I -i artifacts/Demo_Data_Serverless_DDL.sql

# Restore the firewall rules on ADLS an Azure Synapse Analytics. That was needed temporarily to apply these settings.
if echo "$privateEndpointsEnabled" | grep -q "true"; then
    echo "Restoring firewall rules..."
    az storage account update --name ${datalakeName} --resource-group ${resourceGroup} --default-action Deny --only-show-errors -o none
    az synapse workspace firewall-rule delete --name AllowAllWindowsAzureIps --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --only-show-errors -o none --yes
fi

echo "Deployment complete!"
touch configure.complete