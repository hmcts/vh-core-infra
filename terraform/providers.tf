provider "azurerm" {
  version = "= 1.41.0"
}

provider "azurerm" {
  version = "= 1.41.0"
  alias   = "dns"

  tenant_id     = var.dns_tenant_id
  client_id     = var.dns_client_id
  client_secret = var.dns_client_secret

  subscription_id = var.dns_subscription_id
}

provider "azuread" {
  version = "~> 1.0.0"

  alias = "idam"

  tenant_id     = var.idam_tenant_id
  client_id     = var.idam_client_id
  client_secret = var.idam_client_secret

}

provider "azuread" {
  version = "~> 1.0.0"

  alias = "infra"
}
