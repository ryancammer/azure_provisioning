resource "azurerm_subnet" "private" {
  name                 = "snet-${var.namespace}-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vdi_vnet.name
  address_prefixes     = var.subnet_address_prefixes
}
