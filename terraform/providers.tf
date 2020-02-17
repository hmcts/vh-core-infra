provider "azurerm" {
  version = ">= 1.44.0"
}

provider "azurerm" {
  version = ">= 1.36.0"
  alias   = "dns"

  tenant_id     = var.dns_tenant_id
  client_id     = var.dns_client_id
  client_secret = var.dns_client_secret

  subscription_id = var.dns_subscription_id
}

provider "azurerm" {
  version = ">= 1.44.0"
  alias   = "aks"

  tenant_id     = var.aks_tenant_id
  client_id     = var.aks_client_id
  client_secret = var.aks_client_secret

  subscription_id = var.aks_subscription_id
}

provider "azuread" {
  version = "~> 0.6"

  alias = "idam"

  tenant_id     = var.idam_tenant_id
  client_id     = var.idam_client_id
  client_secret = var.idam_client_secret

  subscription_id = "not needed"
}

provider "azuread" {
  version = "~> 0.6"

  alias = "infra"
}
