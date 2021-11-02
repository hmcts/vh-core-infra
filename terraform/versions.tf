terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "infra/vh-core-infra.tfstate"
  }

  required_version = ">= 1.0.4"
  required_providers {
    azurerm = ">= 2.82"
    azuread = "~> 2.7"
    null    = ">= 0"
    random  = ">= 2"
  }
}
