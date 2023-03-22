resource "azurerm_windows_virtual_machine" "vdi_vm" {
  count                    = var.vm_count
  location                 = var.location
  name                     = "${replace(var.namespace, "/(\\w{1})\\w+-?/", "$1")}-${count.index}"
  size                     = var.vm_size
  admin_username           = var.admin_username
  admin_password           = var.admin_password
  network_interface_ids    = [azurerm_network_interface.vm_nic[count.index].id]
  provision_vm_agent       = true
  resource_group_name      = var.resource_group_name
  enable_automatic_updates = true
  secure_boot_enabled      = true
  vtpm_enabled             = true

  identity {
    type = var.vm_identity
  }

  os_disk {
    caching              = var.vm_os_disk_caching
    storage_account_type = var.vm_os_disk_storage_account_type
  }

  source_image_reference {
    publisher = var.vm_publisher
    offer     = var.vm_offer
    sku       = var.vm_sku
    version   = var.vm_version
  }
}
