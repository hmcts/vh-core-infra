data "azurerm_resource_group" "vh-core-infra" {
  name = var.resource_group_name
}

resource "azurerm_app_configuration" "vh" {
  name                = var.resource_prefix
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = "uksouth"

  sku = local.sku.name
}
