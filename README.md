# Azure-Synapse-Analytics-PoC

![alt tag](https://raw.githubusercontent.com/shaneochotny/Azure-Synapse-Analytics-PoC\/main/Images/Synapse-Analytics-PoC-Architecture.gif)

# Overview

    Create a Synapse Analytics environment based on best practices to achieve a successful proof of concept. While settings can be adjusted, 
    the major deployment differences are based on whether or not you used Private Endpoints for connectivity. If you do not already use 
    Private Endpoints for other Azure deployments, it's discouraged to use them for a proof of concept as they have many other networking 
    depandancies than what can be configured here.

# How to run

These files should be executed from the Azure Cloud Shell at https://shell.azure.com using bash:
```
git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC  
cd Azure-Synapse-Analytics-PoC  
nano environment.tf  
terraform init  
terraform plan  
terraform apply  
./configure.sh 
```
      
