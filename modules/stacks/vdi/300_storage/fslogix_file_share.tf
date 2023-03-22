resource "azurerm_storage_share" "fslogix_file_share" {
  name                 = "fs-vdi-${var.namespace}-01"
  storage_account_name = azurerm_storage_account.this.name
  quota                = var.fslogix_file_share_quota

  acl {
    id = "fs-acl-vdi-${var.namespace}-01"

    access_policy {
      permissions = var.fslogix_file_share_permissions
    }
  }
}
