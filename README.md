# Azure Synapse Analytics PoC Accelerator

![alt tag](https://raw.githubusercontent.com/shaneochotny/Azure-Synapse-Analytics-PoC\/main/Images/Synapse-Analytics-PoC-Architecture.gif)

# Description

Create a Synapse Analytics environment based on best practices to achieve a successful proof of concept. While settings can be adjusted, 
the major deployment differences are based on whether or not you used Private Endpoints for connectivity. If you do not already use 
Private Endpoints for other Azure deployments, it's discouraged to use them for a proof of concept as they have many other networking 
depandancies than what can be configured here.


# How to Run

### "Easy Button" Deployment
The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
@Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
@Azure:~$ cd Azure-Synapse-Analytics-PoC
@Azure:~$ bash deploySynapse.sh 
```

### Advanced Deployment: Bicep
You can manually configure the Bicep parameters and update default settings such as the Azure region, database name, credentials, and private endpoint integration. The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
@Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
@Azure:~$ cd Azure-Synapse-Analytics-PoC
@Azure:~$ code Bicep/main.parameters.json
@Azure:~$ az deployment sub create --template-file Bicep/main.bicep --parameters Bicep/main.parameters.json --name Azure-Synapse-Analytics-PoC --location eastus
@Azure:~$ bash deploySynapse.sh 
```

### Advanced Deployment: Terraform
You can manually configure the Terraform parameters and update default settings such as the Azure region, database name, credentials, and private endpoint integration. The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
@Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
@Azure:~$ cd Azure-Synapse-Analytics-PoC
@Azure:~$ code Terraform/terraform.tfvars
@Azure:~$ terraform -chdir=Terraform init
@Azure:~$ terraform -chdir=Terraform plan
@Azure:~$ terraform -chdir=Terraform apply
@Azure:~$ bash deploySynapse.sh 
```

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
- Parquet Auto Ingestion pipeline to optimize data ingestion using best practices

# To Do
- Example script for configuring Row Level Security
- Example script for configuring Dynamic Data Masking
