resource "azurerm_role_assignment" "vm_user_login" {
  count                 = var.vm_count
  scope                 = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Compute/virtualMachines/${azurerm_windows_virtual_machine.vdi_vm[count.index].name}"
  role_definition_name  = "Virtual Machine User Login"
  principal_id          = data.azuread_group.virtual_desktop_users.id
}
