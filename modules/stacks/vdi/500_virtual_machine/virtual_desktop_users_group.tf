data "azuread_group" "virtual_desktop_users" {
  display_name = var.azure_ad_group_name
}
