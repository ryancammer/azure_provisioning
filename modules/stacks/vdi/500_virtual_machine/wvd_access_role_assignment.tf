resource "azurerm_role_assignment" "avd_access" {
  scope                = var.vdag_id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = data.azuread_group.virtual_desktop_users.id
}
