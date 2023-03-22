resource "azurerm_resource_group" "vdi" {
  name     = "rg-${local.namespace}"
  location = var.location
}
