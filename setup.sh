#!/bin/bash
#
# This script runs the Terraform commands.
#
#   @Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
#   @Azure:~$ cd Azure-Synapse-Analytics-PoC
#   @Azure:~$ setup.sh
#   @Azure:~$ bash configure.sh
#

# Make sure this configuration script hasn't been executed already
if [ -f "setup.complete" ]; then
    echo "ERROR: It appears this setup has already been completed.";
    exit 1;
fi

# Get environment details
azureUsername=$(az account show --query "user.name" --output tsv 2>&1)

# Update terraform.tfvars with Admin AD UPN
sed -i "s/REPLACE_AD_ADMIN_UPN/${azureUsername}/g" ./terraform.tfvars

# Make sure we have all the required artifacts
terraform init
terraform plan
terraform apply -auto-approve

echo "Setup complete!"
touch setup.complete
