resource "azurerm_virtual_desktop_application_group" "this" {
  location            = var.location
  name                = "vdag-${var.namespace}-01"
  resource_group_name = var.resource_group_name
  description         = "Azure VD Application Group"
  friendly_name       = "avd-application-group"
  host_pool_id        = azurerm_virtual_desktop_host_pool.this.id
  type                = "Desktop"
}
