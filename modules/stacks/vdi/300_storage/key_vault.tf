resource "azurerm_key_vault" "this" {
  name                       = "kv-${replace(var.namespace, "/(\\w{3})\\w+-?/", "$1")}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  enabled_for_deployment     = true
  enable_rbac_authorization  = true
  tenant_id                  = var.tenant_id
  soft_delete_retention_days = var.key_vault_soft_deletion_in_days
  purge_protection_enabled   = false
  sku_name                   = var.key_vault_sku_name
}
