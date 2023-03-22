output "azure_vdi_provisioning_script_url" {
  value = azurerm_storage_blob.azure_vdi_provisioning_script.url
}

output "vdi_vm_id" {
  value = azurerm_windows_virtual_machine.vdi_vm[*].id
}

output "vdi_vm_principal_id" {
  value = azurerm_windows_virtual_machine.vdi_vm[*].identity[0].principal_id
}

output "vm_count" {
  value = var.vm_count
}
