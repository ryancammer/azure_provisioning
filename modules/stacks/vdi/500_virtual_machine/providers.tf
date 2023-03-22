terraform {
  required_version = "~> 1.1"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.19"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.99"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azurerm" {
  subscription_id            = var.subscription_id
  skip_provider_registration = "true"
  features {}
}
