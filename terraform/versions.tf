terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "infra/vh-core-infra.tfstate"
  }

  required_version = ">= 0.12"
  required_providers {
    azurerm = ">= 1.36"
    azuread = "~> 0.6"
    null    = ">= 0"
    random  = ">= 2"
  }
}
