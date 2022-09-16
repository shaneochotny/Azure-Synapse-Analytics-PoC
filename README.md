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
```bash
git clone https://github.com/Tonio-Lora-Organization/Azure-Synapse-Analytics-PoC
cd Azure-Synapse-Analytics-PoC
bash deploySynapse.sh 
```

### Advanced Deployment: Bicep
You can manually configure the Bicep parameters and update default settings such as the Azure region, database name, credentials, and private endpoint integration. The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```bash
git clone https://github.com/Tonio-Lora-Organization/Azure-Synapse-Analytics-PoC
cd Azure-Synapse-Analytics-PoC
code Bicep/main.parameters.json
az deployment sub create --template-file Bicep/main.bicep --parameters Bicep/main.parameters.json --name Azure-Synapse-Analytics-PoC --location eastus
bash deploySynapse.sh 
```

### Advanced Deployment: Terraform
You can manually configure the Terraform parameters and update default settings such as the Azure region, database name, credentials, and private endpoint integration. The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```bash
git clone https://github.com/Tonio-Lora-Organization/Azure-Synapse-Analytics-PoC
cd Azure-Synapse-Analytics-PoC
code Terraform/terraform.tfvars
terraform -chdir=Terraform init
terraform -chdir=Terraform plan
terraform -chdir=Terraform apply
bash deploySynapse.sh 
```

# What's Deployed

### Azure Synapse Analytics Workspace
- DW1000 Dedicated SQL Pool
- Example scripts for configuring and using:
    - Row Level Security
    - Column Level Security
    - Dynamic Data Masking
    - Materialized Views
    - JSON data parsing
- Example notebooks for testing:
    - Spark and Serverless Metastore integration
    - Spark Delta Lake integration

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
- Lake Database Auto DDL creation (views) for all files used by Ingestion pipeline

# Other Files
- You can find a Synapse_Dedicated_SQL_Pool_Test_Plan.jmx JMeter file under the artifacts folder that is configured to work with your recently deployed Synapse Environment.  

# To Do
- Synapse Data Explorer Pool deployment
- Purview Deployment and Configuration
- Azure ML Services Deployment and Configuration
- Cognitive Services Deployment and Configuration
