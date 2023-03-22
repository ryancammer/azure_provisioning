resource "azurerm_key_vault_secret" "duo_api_hostname" {
  name         = "${var.namespace}-duo-api-hostname"
  value        = var.duo_api_hostname
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.provisioner_key_vault_admin]
}

resource "azurerm_key_vault_secret" "duo_integration_key" {
  name         = "${var.namespace}-duo-integration-key"
  value        = var.duo_integration_key
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.provisioner_key_vault_admin]
}

resource "azurerm_key_vault_secret" "duo_secret_key" {
  name         = "${var.namespace}-duo-secret"
  value        = var.duo_secret_key
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.provisioner_key_vault_admin]
}




