variable "environment" {
  description = "The environment that resources will be provisioned in"
  type        = string
}

variable "location" {
  description = "The geographical location of the resource group"
  type        = string
}

variable "organization" {
  description = "The organization provisioning these resources"
  type        = string
}

variable "postfix" {
  default     = ""
  description = "A suffix to append to resource names in order to disambiguate resources"
  type        = string
}

variable "project" {
  description = "The name of the project that the resources are associated with"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription id to provision the resources with"
  type        = string
}

variable "tenant_id" {
  description = "The tenant id of the Azure Active Directory"
  type        = string
}
