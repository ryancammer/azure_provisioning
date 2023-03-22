output "environment" {
  value = var.environment
}

output "namespace" {
  value = local.namespace
}

output "resource_group_name" {
  value = azurerm_resource_group.vdi.name
}
