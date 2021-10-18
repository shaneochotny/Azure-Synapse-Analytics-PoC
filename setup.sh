#!/bin/bash
#
# This script runs the Terraform commands.
#
#   @Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
#   @Azure:~$ cd Azure-Synapse-Analytics-PoC
#   @Azure:~$ nano terraform.tfvars
#   @Azure:~$ setup.sh
#   @Azure:~$ bash configure.sh
#

# Make sure this configuration script hasn't been executed already
if [ -f "setup.complete" ]; then
    echo "ERROR: It appears this setup has already been completed.";
    exit 1;
fi

# Make sure we have all the required artifacts
terraform init
terraform plan
terraform apply -auto-approve

echo "Setup complete!"
touch setup.complete
