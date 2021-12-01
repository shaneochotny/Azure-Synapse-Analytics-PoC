#!/bin/bash
#
# This script is in two parts; Synapse Environment Deployment and Post-Deployment Configuration.
#
#   Part 1: Synapse Environment Deployment
#
#       This is simply validation that the Terraform or Bicep deployment was completed before executing the post-deployment 
#       configuration. If the deployment was not completed, it will deploy the Synapse environment for you via Bicep.
#
#   Part 2: Post-Deployment Configuration
#
#       These are post-deployment configurations done at the data plan level which is beyond the scope of what Terraform and 
#       Bicep are capable of managing or would normally manage. Database settings are made, sample data is ingested, and 
#       pipelines are created for the PoC.
#
#   This script should be executed via the Azure Cloud Shell via:
#
#       @Azure:~/Azure-Synapse-Analytics-PoC$ bash deploySynapse.sh
#
# Todo:
#    - Bicep private endpoints
#    - Synapse "Lake Databases"

#
# Part 1: Synapse Environment Deployment
#

# Make sure this configuration script hasn't been executed already
if [ -f "deploySynapse.complete" ]; then
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

# Update a few Terraform and Bicep variables if they aren't configured by the user
sed -i "s/REPLACE_SYNAPSE_AZURE_AD_ADMIN_UPN/${azureUsername}/g" Terraform/terraform.tfvars
sed -i "s/REPLACE_SYNAPSE_AZURE_AD_ADMIN_OBJECT_ID/${azureUsernameObjectId}/g" Bicep/main.parameters.json

# Check if there was a Bicep deployment
bicepDeploymentCheck=$(az deployment sub show --name Azure-Synapse-Analytics-PoC --query properties.provisioningState --output tsv 2>&1)
if [ "$bicepDeploymentCheck" == "Succeeded" ]; then
    deploymentType="bicep"
elif [ "$bicepDeploymentCheck" == "Failed" ] || [ "$bicepDeploymentCheck" == "Canceled" ]; then
    echo "ERROR: It looks like a Bicep deployment was attempted, but failed."
    exit 1;
fi

# Check for Terraform if the deployment wasn't completed by Bicep
if echo "$bicepDeploymentCheck" | grep -q "DeploymentNotFound"; then
    # Check to see if Terraform has already been run
    if [ -f "Terraform/terraform.tfstate" ]; then
        deploymentType="terraform"
    else
        # There was no Bicep or Terraform deployment so we're taking the easy button approach and deploying the Synapse
        # environment on behalf of the user via Terraform.

        echo "Deploying Synapse Analytics environment. This will take several minutes..."

        # Terraform init and validation
        echo "Executing 'terraform -chdir=Terraform init'"
        terraformInit=$(terraform -chdir=Terraform init 2>&1)
        if ! echo "$terraformInit" | grep -q "Terraform has been successfully initialized!"; then
            echo "ERROR: Failed to perform 'terraform -chdir=Terraform init'"
            exit 1;
        fi

        # Terraform plan and validation
        echo "Executing 'terraform -chdir=Terraform plan'"
        terraformPlan=$(terraform -chdir=Terraform plan)
        if echo "$terraformPlan" | grep -q "Error:"; then
            echo "ERROR: Failed to perform 'terraform -chdir=Terraform plan'"
            exit 1;
        fi

        # Terraform apply and validation
        echo "Executing 'terraform -chdir=Terraform apply'"
        terraformApply=$(terraform -chdir=Terraform apply -auto-approve)
        if echo "$terraformApply" | grep -q "Apply complete!"; then
            deploymentType="terraform"
        else
            echo "ERROR: Failed to perform 'terraform -chdir=Terraform apply'"
            exit 1;
        fi
    fi
fi

#
# Part 2: Post-Deployment Configuration
#

# Get the output variables from the Terraform deployment
if [ "$deploymentType" == "terraform" ]; then
    resourceGroup=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_resource_group 2>&1)
    synapseAnalyticsWorkspaceName=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_analytics_workspace_name 2>&1)
    synapseAnalyticsSQLPoolName=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_pool_name 2>&1)
    synapseAnalyticsSQLAdmin=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_administrator_login 2>&1)
    synapseAnalyticsSQLAdminPassword=$(terraform output -state=Terraform/terraform.tfstate -raw synapse_sql_administrator_login_password 2>&1)
    datalakeName=$(terraform output -state=Terraform/terraform.tfstate -raw datalake_name 2>&1)
    datalakeKey=$(terraform output -state=Terraform/terraform.tfstate -raw datalake_key 2>&1)
    privateEndpointsEnabled=$(terraform output -state=Terraform/terraform.tfstate -raw private_endpoints_enabled 2>&1)
fi

# Get the output variables from the Bicep deployment
if [ "$deploymentType" == "bicep" ]; then
    resourceGroup=$(jq -r .parameters.resource_group_name.value Bicep/main.parameters.json 2>&1)
    synapseAnalyticsWorkspaceName=$(az deployment sub show --name Azure-Synapse-Analytics-PoC --query properties.outputs.synapse_analytics_workspace_name.value --output tsv 2>&1)
    synapseAnalyticsSQLPoolName=$(az deployment sub show --name Azure-Synapse-Analytics-PoC --query properties.outputs.synapse_sql_pool_name.value --output tsv 2>&1)
    synapseAnalyticsSQLAdmin=$(az deployment sub show --name Azure-Synapse-Analytics-PoC --query properties.outputs.synapse_sql_administrator_login.value --output tsv 2>&1)
    synapseAnalyticsSQLAdminPassword=$(az deployment sub show --name Azure-Synapse-Analytics-PoC --query properties.outputs.synapse_sql_administrator_login_password.value --output tsv 2>&1)
    datalakeName=$(az deployment sub show --name Azure-Synapse-Analytics-PoC --query properties.outputs.datalake_name.value --output tsv 2>&1)
    datalakeKey=$(az deployment sub show --name Azure-Synapse-Analytics-PoC --query properties.outputs.datalake_key.value --output tsv 2>&1)
    privateEndpointsEnabled=$(az deployment sub show --name Azure-Synapse-Analytics-PoC --query properties.outputs.private_endpoints_enabled.value --output tsv 2>&1)
fi

echo "Deployment Type: ${deploymentType}"
echo "Azure Subscription: ${azureSubscriptionName}"
echo "Azure Subscription ID: ${azureSubscriptionID}"
echo "Azure AD Username: ${azureUsername}"
echo "Synapse Analytics Workspace Resource Group: ${resourceGroup}"
echo "Synapse Analytics Workspace: ${synapseAnalyticsWorkspaceName}"
echo "Synapse Analytics SQL Admin: ${synapseAnalyticsSQLAdmin}"
echo "Data Lake Name: ${datalakeName}"

# If Private Endpoints are enabled, temporarily disable the firewalls so we can copy files and perform additional configuration
if [ "$privateEndpointsEnabled" == "true" ]; then
    az storage account update --name ${datalakeName} --resource-group ${resourceGroup} --default-action Allow --only-show-errors -o none
    az synapse workspace firewall-rule create --name AllowAllWindowsAzureIps --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --only-show-errors -o none
fi

# Enable Result Set Cache
echo "Enabling Result Set Caching..."
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d master -I -Q "ALTER DATABASE ${synapseAnalyticsSQLPoolName} SET RESULT_SET_CACHING ON;"

echo "Creating the Auto Pause and Resume pipeline..."

# Copy the Auto_Pause_and_Resume Pipeline template and update the variables
cp artifacts/Auto_Pause_and_Resume.json.tmpl artifacts/Auto_Pause_and_Resume.json 2>&1
sed -i "s/REPLACE_SUBSCRIPTION/${azureSubscriptionID}/g" artifacts/Auto_Pause_and_Resume.json
sed -i "s/REPLACE_RESOURCE_GROUP/${resourceGroup}/g" artifacts/Auto_Pause_and_Resume.json
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_WORKSPACE_NAME/${synapseAnalyticsWorkspaceName}/g" artifacts/Auto_Pause_and_Resume.json
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_SQL_POOL_NAME/${synapseAnalyticsSQLPoolName}/g" artifacts/Auto_Pause_and_Resume.json

# Create the Auto_Pause_and_Resume Pipeline in the Synapse Analytics Workspace
az synapse pipeline create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name "Auto Pause and Resume" --file @artifacts/Auto_Pause_and_Resume.json

# Create the Pause/Resume triggers in the Synapse Analytics Workspace
az synapse trigger create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name Pause --file @artifacts/triggerPause.json
az synapse trigger create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name Resume --file @artifacts/triggerResume.json

echo "Creating the Parquet Auto Ingestion pipeline..."

# Create the Resource Class Logins
cp artifacts/Create_Resource_Class_Logins.sql.tmpl artifacts/Create_Resource_Class_Logins.sql 2>&1
sed -i "s/REPLACE_PASSWORD/${synapseAnalyticsSQLAdminPassword}/g" artifacts/Create_Resource_Class_Logins.sql
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d master -I -i artifacts/Create_Resource_Class_Logins.sql

# Create the Resource Class Users
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}.sql.azuresynapse.net -d ${synapseAnalyticsSQLPoolName} -I -i artifacts/Create_Resource_Class_Users.sql

# Create the LS_Synapse_Managed_Identity Linked Service. This is primarily used for the Auto Ingestion pipeline.
az synapse linked-service create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name LS_Synapse_Managed_Identity --file @artifacts/LS_Synapse_Managed_Identity.json

# Create the DS_Synapse_Managed_Identity Dataset. This is primarily used for the Auto Ingestion pipeline.
az synapse dataset create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name DS_Synapse_Managed_Identity --file @artifacts/DS_Synapse_Managed_Identity.json

# Copy the Parquet Auto Ingestion Pipeline template and update the variables
cp artifacts/Parquet_Auto_Ingestion.json.tmpl artifacts/Parquet_Auto_Ingestion.json 2>&1
sed -i "s/REPLACE_DATALAKE_NAME/${datalakeName}/g" artifacts/Parquet_Auto_Ingestion.json
sed -i "s/REPLACE_SYNAPSE_ANALYTICS_SQL_POOL_NAME/${synapseAnalyticsSQLPoolName}/g" artifacts/Parquet_Auto_Ingestion.json

# Update the Parquet Auto Ingestion Metadata file tamplate with the correct storage account and then upload it
sed -i "s/REPLACE_DATALAKE_NAME/${datalakeName}/g" artifacts/Parquet_Auto_Ingestion_Metadata.csv
az storage copy --only-show-errors -o none --destination https://${datalakeName}.blob.core.windows.net/data/ --source artifacts/Parquet_Auto_Ingestion_Metadata.csv > /dev/null 2>&1

# Copy sample data for the Parquet Auto Ingestion pipeline
sampleDataStorageSAS="?sv=2020-10-02&st=2021-11-23T05%3A00%3A00Z&se=2022-11-24T05%3A00%3A00Z&sr=c&sp=rl&sig=PMi22pEYzw1dHNrOI9gqrwcbi3AJLq%2BxWoSX9SOTLuw%3D"
az storage copy --only-show-errors -o none --destination "https://${datalakeName}.blob.core.windows.net/data/Sample/" --source "https://synapseanalyticspocdata.blob.core.windows.net/sample/AdventureWorks/${sampleDataStorageSAS}" --recursive > /dev/null 2>&1

# Create the Auto_Pause_and_Resume Pipeline in the Synapse Analytics Workspace
az synapse pipeline create --only-show-errors -o none --workspace-name ${synapseAnalyticsWorkspaceName} --name "Parquet Auto Ingestion" --file @artifacts/Parquet_Auto_Ingestion.json

echo "Creating the Demo Data database using Synapse Serverless SQL..."

# Create a Demo Data database using Synapse Serverless SQL
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d master -I -Q "CREATE DATABASE [Demo Data (Serverless)];"

# Create the Views over the external data
sqlcmd -U ${synapseAnalyticsSQLAdmin} -P ${synapseAnalyticsSQLAdminPassword} -S tcp:${synapseAnalyticsWorkspaceName}-ondemand.sql.azuresynapse.net -d "Demo Data (Serverless)" -I -i artifacts/Demo_Data_Serverless_DDL.sql

# Restore the firewall rules on ADLS an Azure Synapse Analytics. That was needed temporarily to apply these settings.
if [ "$privateEndpointsEnabled" == "true" ]; then
    echo "Restoring firewall rules..."
    az storage account update --name ${datalakeName} --resource-group ${resourceGroup} --default-action Deny --only-show-errors -o none
    az resource update --name ${synapseAnalyticsWorkspaceName} --resource-group ${resourceGroup} --resource-type Microsoft.Synapse/workspaces --set Properties.publicNetworkAccess="Disabled" --only-show-errors -o none
    az synapse workspace firewall-rule delete --name AllowAllWindowsAzureIps --resource-group ${resourceGroup} --workspace-name ${synapseAnalyticsWorkspaceName} --only-show-errors -o none --yes
fi

echo "Deployment complete!"
touch deploySynapse.complete