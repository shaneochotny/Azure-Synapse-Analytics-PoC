# Azure-Synapse-Analytics-PoC

![alt tag](https://raw.githubusercontent.com/shaneochotny/Azure-Synapse-Analytics-PoC\/main/Images/Synapse-Analytics-PoC-Architecture.gif)

# Overview

Create a Synapse Analytics environment based on best practices to achieve a successful proof of concept. While settings can be adjusted, 
the major deployment differences are based on whether or not you used Private Endpoints for connectivity. If you do not already use 
Private Endpoints for other Azure deployments, it's discouraged to use them for a proof of concept as they have many other networking 
depandancies than what can be configured here.


# How to Run

These files should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC  
cd Azure-Synapse-Analytics-PoC  
nano environment.tf  
terraform init  
terraform plan  
terraform apply  
bash configure.sh 
```

- There are a few variables in <b>environment.tf</b> which should be updated to reflect your environment, but at a minimum <b>synapse_azure_ad_admin_upn</b> needs updated to deploy.
- <b>environment.tf</b> is the Terraform template which deploys the environment. <b>configure.sh</b> performs post deployment configuration that cannot be done with Terraform.


# What's Deployed

### Azure Synapse Analytics Workspace
- DW1000 Dedicated SQL Pool

### Azure Data Lake Storage Gen2
- <b>config</b> container for Azure Synapse Analytics Workspace
- <b>data</b> container for queried/ingested data

### Azure Log Analytics
- Logging and telemetry for Azure Synapse Analytics
- Logging and telemetry for Azure Data Lake Storage Gen2


# What's Configured
- Enable Result Set Caching
- Create a pipeline to auto pause/resume the Dedicated SQL Pool
- Feature flag to enable/disable Private Endpoints
- Serverless SQL Demo Data Database
- Proper service and user permissions for Azure Synapse Analytics Workspace and Azure Data Lake Storage Gen2

# To Do
- Example script for configuring Row Level Security
- Example script for configuring Dynamic Data Masking
- Data ingestion best practices