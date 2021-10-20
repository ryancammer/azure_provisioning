# Azure Provisioning
These scripts download [Powershell 7](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-71) 
on a Windows Virtual Machine (VM) running in [Azure](https://azure.microsoft.com/), install the latest version of the 
[Az module](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az), and then join that 
VM to an [Azure Virtual Desktop (AVD)](https://azure.microsoft.com/en-us/services/virtual-desktop/) 
[Session Host Pool (SHP)](https://docs.microsoft.com/en-us/azure/virtual-desktop/create-host-pools-azure-marketplace?tabs=azure-portal). 

# Background
Joining a VM to a SHP requires a Registration Token, which have a configurable Time To Live (TTL) between 1 hour and 30 
days. Since provisioning is done with Terraform, VMs that are provisioned after the SHP is provisioned require a 
mechanism for obtaining a new Registration Token. There doesn't appear to be a great way to do this in Terraform. 
Additionally, Registration Tokens are sensitive, and since the SHP is provisioned in a different layer, the Registration
Token needs to be stored somewhere. This is all obviated by VMs generating a short-lived token.

# Description
The azure_provisioning script downloads and installs Powershell 7, and then 
downloads and executes the host_registration script. 

The host_registration script downloads and updates the Az module, signs into 
Azure, creates a new 
[Registration Token](https://docs.microsoft.com/en-us/powershell/module/az.desktopvirtualization/new-azwvdregistrationinfo)
, and then launches the Azure Virtual Desktop Agent and BootLoader installers, followed by the SxSSStack
installer. These applications then work in conjunction to join the VM to the SHP.

# Resources
- [Azure Virtual Desktop Agent Installer](https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv)
- [Azure Virtual DesktopBootloader Installer](https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH)
