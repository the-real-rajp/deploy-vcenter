<#
    .SYNOPSIS
    vCenter Server Appliance Deployment Script

    .DESCRIPTION
    This PowerShell script automates the deployment of VMware vCenter Server Appliance (VCSA). 
    It prompts the user for configuration details, generates a JSON configuration file, 
    and then initiates the deployment of VCSA using the VMware CLI installer.

    .NOTES
    Author: Raj Patel
    Created On: Jan 1, 2023
    Version: 1.0

    Before running the script, ensure the following:

    *The VMware PowerCLI module is installed and imported in your PowerShell session.
    *You have the correct permissions to deploy VCSA on the specified ESXi host.
    *The VCSA installer (vcsa-deploy.exe) path is correct and accessible.
    *The version number in the JSON ("__version") matches the version expected by your VCSA installer.
    *All entered information is accurate, especially network configurations and passwords.

    .EXAMPLE
    To run the script, simply execute it in a PowerShell environment with necessary privileges.
    It will guide you through the required steps.
#>

# Check and Install VMware PowerCLI if not present
if (-not (Get-Module -Name VMware.PowerCLI -ListAvailable)) {
    Write-Host "VMware PowerCLI is not installed. Installing now..."
    Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Confirm:$false
    Import-Module VMware.PowerCLI
} else {
    Write-Host "VMware PowerCLI is already installed."
    Import-Module VMware.PowerCLI
}

# Suppress the Customer Experience Improvement Program (CEIP) prompt
Set-PowerCLIConfiguration -Scope User -ParticipateInCeip $false -Confirm:$false

# Step 1: Prompt for VCSA deployment details
$esxiHostname = Read-Host -Prompt "Enter the ESXi hostname or IP"
$datastore = Read-Host -Prompt "Enter the datastore name for vCenter"
$networkName = Read-Host -Prompt "Enter the VSS network name for vCenter"
$deploymentSize = Read-Host -Prompt "Enter the deployment size (tiny, small, medium, large)"
$vcsaName = Read-Host -Prompt "Enter the name for the vCenter VM"
$vcsaRootPassword = Read-Host -Prompt "Enter the root password for vCenter" -AsSecureString
$vcsaNetworkMode = Read-Host -Prompt "Enter the network mode (static or dhcp)"
$vcsaSysName = Read-Host -Prompt "Enter the DNS FQDN for the vCenter (if static)"
$vcsaIPAddress = Read-Host -Prompt "Enter the vCenter IP address (if static)"
$vcsaSubnetMask = Read-Host -Prompt "Enter the subnet mask (24) (if static)"
$vcsaGateway = Read-Host -Prompt "Enter the default gateway (if static)"
$vcsaDNS = Read-Host -Prompt "Enter the DNS servers (comma-separated, if static)"
$vcsaNTP = Read-Host -Prompt "Enter the NTP server (optional)"

# Convert secure string password to plain text
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($vcsaRootPassword)
try {
    $plainVcsaRootPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr)
}

# Step 2: Create JSON object for VCSA deployment
$jsonData = @{
    "__version" = "2.13.0" # Adjust this to match your VCSA version, this is good for 7.0 and 8.0 VCSA versions
    "ceip" = @{
        "settings" = @{
            "ceip_enabled" = $true # Set to $true to participate, $false otherwise
        }
    }
    "new_vcsa" = @{
        "esxi" = @{
            "hostname" = $esxiHostname
            "username" = "root" # Assuming root; change if different
            "password" = $plainVcsaRootPassword
            "deployment_network" = $networkName
            "datastore" = $datastore
        }
        "appliance" = @{
            "deployment_option" = $deploymentSize
            "name" = $vcsaName
            "thin_disk_mode" = $true # Set to $true for thin provisioning, $false for thick
        }
        "network" = @{
            "ip_family" = "ipv4"
            "mode" = $vcsaNetworkMode
            "ip" = $vcsaIPAddress
            "dns_servers" = @($vcsaDNS -split ',') # Assuming comma-separated input
            "prefix" = $vcsaSubnetMask
            "gateway" = $vcsaGateway
            "system_name" = $vcsaSysName
        }
        "os" = @{
            "password" = $plainVcsaRootPassword
            "ntp_servers" = @($vcsaNTP)
            "ssh_enable" = $true # Or $false, depending on your preference
        }
    
    }
}

# Convert to JSON and save to file
$jsonConfig = $jsonData | ConvertTo-Json -Depth 5
$jsonFilePath = "PATH-toFILE\vcsa-deployment-config.json" # Path to where the JSON file will be saved
$jsonConfig | Out-File -FilePath $jsonFilePath

Write-Host "JSON configuration file created at: $jsonFilePath"

# Step 3: Deploy the VCSA
try {
    # Define path to the VCSA installer
    $vcsaInstallerPath = "E:\vcsa-cli-installer\win32\vcsa-deploy.exe" #Path to vcsa-deploy.exe

    # Execute VCSA deployment
    & $vcsaInstallerPath install --accept-eula --acknowledge-ceip --no-esx-ssl-verify $jsonFilePath
    Write-Host "vCenter Server Appliance deployment initiated."
} catch {
    Write-Error "Error deploying vCenter Server Appliance: $_"
}

