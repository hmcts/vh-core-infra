data "azurerm_resource_group" "vh-core-infra" {
  name = var.resource_group_name
}

resource "azurerm_signalr_service" "vh" {
  name                = var.resource_prefix
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location

  sku {
    name     = local.sku.name
    capacity = local.sku.capacity
  }
}
