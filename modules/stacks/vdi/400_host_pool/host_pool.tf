resource "azurerm_virtual_desktop_host_pool" "this" {
  location                 = var.location
  name                     = "vdpool-${var.namespace}-01"
  resource_group_name      = var.resource_group_name
  friendly_name            = "avd-host-pool"
  validate_environment     = true
  start_vm_on_connect      = true
  custom_rdp_properties    = var.custom_rdp_properties
  description              = "Host Pool for AVD"
  type                     = "Pooled"
  maximum_sessions_allowed = var.maximum_sessions_allowed
  load_balancer_type       = var.load_balancer_type
}
