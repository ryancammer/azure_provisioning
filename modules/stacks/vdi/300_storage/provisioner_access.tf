
data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "provisioner_key_vault_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_key_vault.this]
}

resource "azurerm_role_assignment" "provisioner_config_storage_container_reader" {
  scope                = azurerm_storage_container.vdi_config_storage_container.resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_storage_container.vdi_config_storage_container]
}

resource "azurerm_role_assignment" "provisioner_config_scripts_storage_container_reader" {
  scope                = azurerm_storage_container.vdi_config_scripts_storage_container.resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_storage_container.vdi_config_scripts_storage_container]
}
