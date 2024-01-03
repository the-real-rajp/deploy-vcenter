#  vCenter Server Appliance Deployment Script
This PowerShell script automates the deployment of VMware vCenter Server Appliance (VCSA). 
It prompts the user for configuration details, generates a JSON configuration file, 
and then initiates the deployment of VCSA using the VMware CLI installer.

Before running the script, ensure the following:
*The VMware PowerCLI module is installed and imported in your PowerShell session.
*You have the correct permissions to deploy VCSA on the specified ESXi host.
*The VCSA installer (vcsa-deploy.exe) path is correct and accessible.
*The version number in the JSON ("__version") matches the version expected by your VCSA installer.
*All entered information is accurate, especially network configurations and passwords.
