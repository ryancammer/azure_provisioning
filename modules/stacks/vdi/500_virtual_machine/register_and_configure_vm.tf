resource "azurerm_role_assignment" "provisioner_scripts_storage_container_reader" {
  count               = var.vm_count
  scope               = var.scripts_storage_container_resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id        = azurerm_windows_virtual_machine.vdi_vm[count.index].identity[0].principal_id
}

resource "azurerm_virtual_machine_extension" "register_and_configure_vm" {
  count                      = var.vm_count
  name                       = "register_vm_with_session_host"
  virtual_machine_id         = element(azurerm_windows_virtual_machine.vdi_vm.*.id, count.index)
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  depends_on                 = [
    azurerm_role_assignment.vm_host_pool_contributor_role,
    azurerm_storage_blob.azure_vdi_provisioning_script,
    azurerm_virtual_machine_extension.aad,
    azurerm_role_assignment.provisioner_scripts_storage_container_reader
  ]

  settings = <<SETTINGS
    {
      "fileUris": [
        "${azurerm_storage_blob.azure_vdi_provisioning_script.url}",
        "${var.deploy_agent_archive_url}",
        "${var.duo_installer_bits_url}"
      ],
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -exec bypass -File .\\azure_vdi_provisioning.ps1 -Execute -DuoIntegrationKeyName ${var.duo_integration_key_name} -DuoSecretKeyName ${var.duo_secret_key_name} -DuoApiHostnameKey ${var.duo_api_hostname_key_name} -SubscriptionId ${var.subscription_id} -TenantId ${var.tenant_id} -ResourceGroupName ${var.resource_group_name} -HostPoolName ${var.host_pool_name} -KeyVaultName ${var.key_vault_name} -fslogixProfilePath '' -AzureStorageDownloadUrls $null"
    }
  SETTINGS

  protected_settings = <<SETTINGS
    {
        "storageAccountName": "${var.storage_account_name}",
        "storageAccountKey": "${var.storage_account_primary_access_key}"
    }
  SETTINGS


  lifecycle {
    ignore_changes = [settings]
  }
}
