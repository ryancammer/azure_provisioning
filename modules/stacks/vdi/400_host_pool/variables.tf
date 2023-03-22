variable "custom_rdp_properties" {
  description = "A string of RDP properties for the host pool"
  type        = string
}

variable "load_balancer_type" {
  description = "Whether to do depth-first or breadth-first additions to VMs when users sign on"
  type        = string
}

variable "location" {
  description = "The geographical location of the resource group"
  type        = string
}

variable "maximum_sessions_allowed" {
  description = "The maximum number of sessions allowed on a VM in the host pool."
  type        = string
}

variable "namespace" {
  description = "The namespace to append to resource names"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that the network resources will belong to"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription id"
  type        = string
}
