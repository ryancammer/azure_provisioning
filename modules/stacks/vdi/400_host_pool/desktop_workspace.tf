resource "azurerm_virtual_desktop_workspace" "this" {
  name                = "Windows Virtual Desktop Workspace"
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = "Windows Virtual Desktop Workspace"
  description         = "Windows Virtual Desktop Workspace"
}
