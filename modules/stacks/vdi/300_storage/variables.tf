variable "azure_ad_key_vault_users_group_name" {
  description = "The name of the Azure Ad group with access to Key Vault"
  type        = string
}

variable "duo_api_hostname" {
  description = "The hostname that Duo uses for validation"
  type        = string
}

variable "duo_integration_key" {
  description = "The integration key that Duo uses for validation"
  type        = string
}

variable "duo_secret_key" {
  description = "The secret key that Duo uses for validation"
  type        = string
}

variable "fslogix_file_share_directory_name" {
  description = "The name of the fslogix file share directory"
  type        = string
}

variable "fslogix_file_share_permissions" {
  description = "The permissions for the operations allowed on the file share"
  type        = string
}

variable "fslogix_file_share_quota" {
  description = "The maximum size in GB of the file share"
  type        = number
}

variable "key_vault_sku_name" {
  default     = "standard"
  description = "The name of the key vault sku."
  type        = string
}

variable "key_vault_soft_deletion_in_days" {
  default     = 7
  description = "The number of days until items are deleted for good"
  type        = number
}

variable "location" {
  description = "The geographical location of the resource group"
  type        = string
}

variable "namespace" {
  description = "The namespace to append to resource names"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that the network resources will belong to"
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account used by the VDI services"
  type        = string
}

variable "storage_account_replication_type" {
  default     = "GRS"
  description = "The data in the storage account is always replicated to ensure durability and high availability. Options are: Geo-redundant storage (GRS), Locally redundant storage (LRS), Zone-redundant storage (ZRS), and Geo-Zone Redundant storage (GZRS)."
  type        = string
}

variable "storage_account_tier" {
  default     = "Standard"
  description = "Determines whether the account has premium performance for block blobs, file shares, or page blobs. Options are Standard or Premium."
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription id to provision the resources with"
  type        = string
}

variable "tenant_id" {
  description = "The tenant id of the Azure Active Directory"
  type        = string
}

variable "vdi_config_storage_container_access_type" {
  default     = "private"
  description = "Determines whether the container has public or private access. NOTE: If the storage account is private, the container must also be private."
  type        = string
}

variable "vm_installation_access_tier" {
  default     = "Hot"
  description = "The type of storage to be used for a storage blob. Possible values are Archive, Cold, and Hot."
  type        = string
}
