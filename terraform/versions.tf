terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "infra/vh-core-infra.tfstate"
  }

  required_version = ">= 0.12"
  required_providers {
    azurerm = ">= 1.40"
    azuread = "~> 1.0.0"
    null    = ">= 0"
    random  = ">= 2"
  }
}
