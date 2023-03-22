resource "azurerm_storage_blob" "azure_vdi_provisioning_script" {
  name                   = "azure_vdi_provisioning.ps1"
  storage_account_name   = var.storage_account_name
  storage_container_name = var.scripts_storage_container_name
  type                   = var.script_storage_type
  source                 = "scripts/azure_vdi_provisioning.ps1"
}
