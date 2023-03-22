variable "admin_username" {
  description = "This is the username of the VM admin user."
  type        = string
}

variable "admin_password" {
  description = "This is the password of the password of the VM admin user."
  type        = string
}

variable "azure_ad_group_name" {
  description = "This is the name of the group that contains users who can log into the Azure Virtual Desktops."
  type        = string
}

variable "azure_provisioning_script_download_url" {
  default     = ""
  description = "This is the download url fo the azure provisioning script."
  type        = string
}

variable "deploy_agent_archive_url" {
  description = "This is the Azure Storage url of the deploy agent archive, which contains scripts and executables to join a VM to a session host pool."
  type        = string
}

variable "duo_api_hostname_key_name" {
  description = "This is the name of the api host used by Duo that is stored in Key Vault."
  type        = string
}

variable "duo_installer_bits_url" {
  description = "This is the Azure Storage url where the Duo installer bits are located."
  type        = string
}

variable "duo_integration_key_name" {
  description = "This is the name of the integration key used by Duo that is stored in Key Vault"
  type        = string
}

variable "duo_secret_key_name" {
  description = "This is the name of the secret key used by Duo that is stored in Key Vault."
  type        = string
}

variable "environment" {
  default     = "dev"
  description = "This is the name of environment the virtual machines will live in."
  type        = string
}

variable "host_pool_name" {
  description = "This is the name of the AVD host pool to add the VMs to."
  type        = string
}

variable "key_vault_id" {
  description = "This is the id of the key vault that's used for Duo secrets."
  type        = string
}

variable "key_vault_name" {
  description = "This is the name of the key vault that's used for Duo secrets."
  type        = string
}

variable "location" {
  description = "This is the geographical location of the resource group."
  type        = string
}

variable "namespace" {
  description = "This is the namespace to append to resource names."
  type        = string
}

variable "resource_group_name" {
  description = "This is the name of the resource group that the network resources will belong to."
  type        = string
}

variable "script_storage_type" {
  default     = "Block"
  description = "This is the type of storage that scripts use. Options are Block, Page, and Append."
  type        = string
}

variable "scripts_storage_container_resource_manager_id" {
  default     = "Block"
  description = "This is the id of the scripts storage container."
  type        = string
}

variable "scripts_storage_container_name" {
  description = "This is the name of the storage container scripts are stored in."
  type        = string
}

variable "storage_account_name" {
  description = "This is the name of the storage account to use for accessing storage containers, blobs, and so forth."
  type        = string
}

variable "storage_account_primary_access_key" {
  description = "This is the sensitive access key for accessing the storage account."
  type        = string
}

variable "subnet_private_id" {
  description = "This is the id of the subnet that the VMs will belong to."
  type        = string
}

variable "subscription_id" {
  description = "This is the id of the Azure subscription id that the provisioned resources will belong to."
  type        = string
}

variable "tenant_id" {
  description = "This is the tenant id of the Azure Active Directory that the provisioned resources will reside in."
  type        = string
}

variable "vdag_id" {
  default     = ""
  description = "The id of the virtual desktop application group"
  type        = string
}

variable "vdi_config_storage_container_resource_manager_id" {
  default     = "Block"
  description = "This is the id of the storage container."
  type        = string
}

variable "vm_count" {
  description = "The number of VMs to provision"
  type        = number
}

variable "vm_identity" {
  description = "How the identity of the VM is assigned"
  type        = string
}

variable "vm_offer" {
  description = "The offer of the VM"
  type        = string
}

variable "vm_os_disk_caching" {
  description = "The Azure subscription id"
  type        = string
}

variable "vm_os_disk_storage_account_type" {
  description = "The Azure subscription id"
  type        = string
}

variable "vm_publisher" {
  description = "The publisher of the VM"
  type        = string
}

variable "vm_size" {
  description = "The size of the VM to use"
  type        = string
}

variable "vm_sku" {
  description = "The sku of the VM to use"
  type        = string
}

variable "vm_version" {
  default     = "latest"
  description = "The version of the vm. The 'latest' default is most likely fine in most cases."
  type        = string
}
