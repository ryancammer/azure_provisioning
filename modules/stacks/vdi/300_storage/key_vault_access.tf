resource "azurerm_role_assignment" "vm_host_pool_contributor_role" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azuread_group.key_vault_users.id
  depends_on           = [azurerm_key_vault.this]
}
