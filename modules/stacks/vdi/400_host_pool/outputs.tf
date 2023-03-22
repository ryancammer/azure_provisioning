output "application_group_association_id" {
  value = azurerm_virtual_desktop_workspace_application_group_association.this.id
}

output "host_pool_id" {
  value = azurerm_virtual_desktop_host_pool.this.id
}

output "host_pool_name" {
  value = azurerm_virtual_desktop_host_pool.this.name
}

output "vdag_id" {
  value = azurerm_virtual_desktop_application_group.this.id
}
