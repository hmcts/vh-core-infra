data "azurerm_resource_group" "vh-core-infra" {
  name = var.resource_group_name
}

resource "azurerm_media_services_account" "vh-core-infra" {
  name                = replace(var.resource_prefix,"-","")
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location

  storage_account {
    id         = var.storage_account_id
    is_primary = true
  }
}
