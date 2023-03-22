resource "azurerm_storage_share_directory" "fslogix_share_directory" {
  name                 = var.fslogix_file_share_directory_name
  share_name           = azurerm_storage_share.fslogix_file_share.name
  storage_account_name = azurerm_storage_account.this.name
}
