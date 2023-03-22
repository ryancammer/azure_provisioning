# azure_provisioning
azure_provisioning is an open source Azure Virtual Desktop Infrastructure (VDI) provisioning platform.

# Getting Started

## Prerequisites
* [Terraform](https://www.terraform.io/)
  * Install [the terraform binary](https://www.terraform.io/downloads.html).
* [Terragrunt](https://terragrunt.gruntwork.io/)
  * Install [the terragrunt binary](https://github.com/gruntwork-io/terragrunt/releases).
* [Azure](https://azure.microsoft.com/)
  * Install [the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/).

## Steps
1. Clone this repo using SSH: `git clone git@github.com:ryancammer/azure_provisioning.git`
2. [Log into Azure using the CLI](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli): `az login`
3. __NOTE__: Bootstrapping is only necessary once, when the project is initialized. 
   Bootstrap the project. From the project's root directory: `$ cd bootstrap && terraform init`
4. Verify the tests pass from the root directory: `pwsh -c "invoke-pester"`
5. Plan the chosen deployment using `terragrunt`. As an example, 
   from the project's root directory: `cd deployments/vdi/dev && terragrunt run-all plan`
6. Apply the provisioning to each of the stacks. As an example, from the project's root 
   directory: `cd deployments/vdi/dev && terragrunt run-all apply`

# Concepts

## Terragrunt stacks
vdi-terraform consists of stacks such as `100_azure_setup`, `200_network`. and so on. Each stack is
built atop the previous stacks. For instance, the `500_virtual_machine` uses the Azure Key Vault
provisioned in `300_storage`.

## Session Host Pools
Joining a VM to a SHP requires a Registration Token, which have a configurable Time To Live (TTL) between 1 hour and 30
days. Since provisioning is done with Terraform, VMs that are provisioned after the SHP provisioning require a
mechanism for obtaining a new Registration Token. These are generated using the 
[`New-AzWvdRegistrationInfo` command](https://docs.microsoft.com/en-us/powershell/module/az.desktopvirtualization/new-azwvdregistrationinfo?view=azps-7.3.2)
that is provided by the [Az.DesktopVirtualization](https://docs.microsoft.com/en-us/powershell/module/az.desktopvirtualization/?view=azps-7.3.2) 
module.

The azure_provisioning script downloads and installs PowerShell 7, and then downloads and executes the host_registration 
script. The azure_provisioning script currently resides in a 
[non-Dfinity repository](https://github.com/ryancammer/azure_provisioning/), but will be moving to a Dfinity
repository very soon.

## Desired State Configuration
[Microsoft Desired State Configuration](https://docs.microsoft.com/en-us/powershell/dsc/getting-started/wingettingstarted?view=dsc-1.1&viewFallbackFrom=dsc-3.0)
was initially the preferred mechanism for configuring newly provisioned VMs, but its installation was quite problematic.
[Dot-sourcing operations](https://docs.microsoft.com/en-us/powershell/dsc/configurations/configurations?view=dsc-1.1&viewFallbackFrom=dsc-3.0)
would hang, and [`Start-DscConfiguration`](https://docs.microsoft.com/en-us/powershell/module/psdesiredstateconfiguration/start-dscconfiguration?view=dsc-1.1&viewFallbackFrom=dsc-3.0)
would throw errors due to some other DSC configuration process occurring simultaneously.

# Stacks

## 100_azure_setup
The Azure Setup stack provisions a resource group and sets up the namespace that's used by the other
stacks.

## 200_network
The Network stack set up the virtual network, subnet, and network security group.

## 300_storage
The Storage stack provisions the Key Vault, file shares, and uploads secrets and bits for later use.

## 400_virtual_desktop
The Virtual Desktop stack provisions Azure Virtual Desktop, and creates a host pool.

## 500_virtual_machine
The Virtual Machine stack provisions VMs by installing required software using the
`azure_vdi_provisioning.ps1` script, which installs and configures:
* [Duo](https://help.duo.com/s/article/1090?language=en_US)

