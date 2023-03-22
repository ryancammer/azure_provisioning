data "azuread_group" "key_vault_users" {
  display_name = var.azure_ad_key_vault_users_group_name
}
