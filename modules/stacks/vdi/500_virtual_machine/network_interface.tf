resource "azurerm_network_interface" "vm_nic" {
  count               = var.vm_count
  name                = "nic-${var.namespace}-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_private_id
    private_ip_address_allocation = "Dynamic"
  }
}
