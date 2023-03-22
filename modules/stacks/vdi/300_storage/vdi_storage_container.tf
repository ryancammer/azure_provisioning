resource "azurerm_storage_container" "vdi_config_storage_container" {
  name                  = "st-vdi-${var.namespace}-01"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = var.vdi_config_storage_container_access_type
}