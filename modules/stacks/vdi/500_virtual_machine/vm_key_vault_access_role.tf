resource "azurerm_role_assignment" "vm_host_key_vault_access_role" {
  count                = var.vm_count
  scope                = var.key_vault_id
 role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_windows_virtual_machine.vdi_vm[count.index].identity[0].principal_id
  depends_on           = [azurerm_windows_virtual_machine.vdi_vm]
}
