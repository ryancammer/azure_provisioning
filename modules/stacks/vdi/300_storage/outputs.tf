output "deploy_agent_archive_url" {
  value = azurerm_storage_blob.deploy_agent_archive.url
}

output "duo_api_hostname_key_name" {
  value = azurerm_key_vault_secret.duo_api_hostname.name
}

output "duo_installer_bits_url" {
  value = azurerm_storage_blob.duo_installer_bits.url
}

output "duo_integration_key_name" {
  value = azurerm_key_vault_secret.duo_integration_key.name
}

output "duo_secret_key_name" {
  value = azurerm_key_vault_secret.duo_secret_key.name
}

output "fslogix_share_directory_id" {
  value = azurerm_storage_share_directory.fslogix_share_directory.id
}

output "fslogix_share_directory_name" {
  value = azurerm_storage_share_directory.fslogix_share_directory.name
}

output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "scripts_storage_container_id" {
  value = azurerm_storage_container.vdi_config_scripts_storage_container.id
}

output "scripts_storage_container_name" {
  value = azurerm_storage_container.vdi_config_scripts_storage_container.name
}

output "scripts_storage_container_resource_manager_id" {
  value = azurerm_storage_container.vdi_config_scripts_storage_container.resource_manager_id
}

output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_account_primary_access_key" {
  sensitive = true
  value = azurerm_storage_account.this.primary_access_key
}

output "vdi_config_storage_container_id" {
  value = azurerm_storage_container.vdi_config_storage_container.id
}

output "vdi_config_storage_container_name" {
  value = azurerm_storage_container.vdi_config_storage_container.name
}

output "vdi_config_storage_container_resource_manager_id" {
  value = azurerm_storage_container.vdi_config_storage_container.resource_manager_id
}
