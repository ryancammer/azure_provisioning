resource "azurerm_virtual_network" "vdi_vnet" {
  location              = var.location
  resource_group_name   = var.resource_group_name
  name                  = "vnet-${var.namespace}-01"
  address_space         = ["10.0.0.0/16"]
}
