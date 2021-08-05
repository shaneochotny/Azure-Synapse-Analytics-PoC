# Azure-Synapse-Analytics-PoC

    Create a Synapse Analytics environment based on best practices to achieve a successful proof of concept. While settings can be adjusted, 
    the major deployment differences are based on whether or not you used Private Endpoints for connectivity. If you do not already use 
    Private Endpoints for other Azure deployments, it's discouraged to use them for a proof of concept as they have many other networking 
    depandancies than what can be configured here.

    These files should be executed from the Azure Cloud Shell at https://shell.azure.com:

      @Azure:~$ git clone https://github.com/shaneochotny/Azure-Synapse-Analytics-PoC
      @Azure:~$ cd Azure-Synapse-Analytics-PoC
      @Azure:~$ nano environment.tf
      @Azure:~$ terraform init
      @Azure:~$ terraform plan
      @Azure:~$ terraform apply
      @Azure:~$ ./configure.sh