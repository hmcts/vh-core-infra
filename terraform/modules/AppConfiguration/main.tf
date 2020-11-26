data "azurerm_resource_group" "vh-core-infra" {
  name = var.resource_group_name
}

resource "azurerm_app_configuration" "vh" {
  name                = var.resource_prefix
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = "uksouth"

  sku = local.sku
}

resource "azurerm_role_assignment" "appconfig_readers" {
  for_each = var.config_readers

  name                 = "00000000-0000-0000-0000-000000000000"
  scope                = azurerm_app_configuration.vh.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = each.value
}
