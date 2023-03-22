resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
}

resource "azurerm_key_vault_secret" "storage_primary_access_key" {
  name         = "${var.namespace}-storage-primary-access-key"
  value        = azurerm_storage_account.this.primary_access_key
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.provisioner_key_vault_admin]
}

resource "azurerm_key_vault_secret" "storage_secondary_access_key" {
  name         = "${var.namespace}-storage-secondary-access-key"
  value        = azurerm_storage_account.this.secondary_access_key
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.provisioner_key_vault_admin]
}
