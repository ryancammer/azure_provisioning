resource "azurerm_role_assignment" "vm_host_pool_contributor_role" {
  count                = var.vm_count
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.DesktopVirtualization/hostPools/${var.host_pool_name}"
  role_definition_name = "Desktop Virtualization Host Pool Contributor"
  principal_id         = azurerm_windows_virtual_machine.vdi_vm[count.index].identity[0].principal_id
  depends_on           = [azurerm_windows_virtual_machine.vdi_vm]
}
