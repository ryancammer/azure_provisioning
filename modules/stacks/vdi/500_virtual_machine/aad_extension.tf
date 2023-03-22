resource "azurerm_virtual_machine_extension" "aad" {
  count                      = var.vm_count
  name                       = "aad-vm"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  virtual_machine_id         = element(azurerm_windows_virtual_machine.vdi_vm.*.id, count.index)
}
