variable "location" {
  description = "The geographical location of the resource group"
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

variable "subnet_address_prefixes" {
  description = "The subnet's address prefixes"
  type        = list(string)
}


variable "subscription_id" {
  description = "The Azure subscription id to provision the resources with"
  type        = string
}
