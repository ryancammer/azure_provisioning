resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.namespace}-01"
  location            = var.location
  resource_group_name = var.resource_group_name
}
