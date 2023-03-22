resource "azurerm_storage_blob" "deploy_agent_archive" {
  name                   = "DeployAgent.zip"
  storage_account_name   = var.storage_account_name
  storage_container_name = azurerm_storage_container.vdi_config_storage_container.name
  type                   = "Block"
  source                 = "bits/DeployAgent.zip"
  access_tier            = var.vm_installation_access_tier
  content_md5            = "8c68b21fb87e44e952fe65aeb15a26d4"
}

resource "azurerm_storage_blob" "duo_installer_bits" {
  name                   = "DuoWindowsLogon64.msi"
  storage_account_name   = var.storage_account_name
  storage_container_name = azurerm_storage_container.vdi_config_storage_container.name
  type                   = "Block"
  source                 = "bits/DuoWindowsLogon64.msi"
  access_tier            = var.vm_installation_access_tier
  content_md5            = "27162b0a8f57b82a0366a3811d80b446"
}
