data "azurerm_resource_group" "vh-core-infra" {
  name = var.resource_group_name
}

resource "azurerm_resource_group" "app" {
  for_each = var.apps

  name     = each.value.name
  location = data.azurerm_resource_group.vh-core-infra.location
  tags     = local.common_tags
}

resource "azurerm_function_app" "app" {
  for_each = var.apps

  name                      = each.value.name
  location                  = azurerm_resource_group.app[each.key].location
  resource_group_name       = azurerm_resource_group.app[each.key].name
  app_service_plan_id       = var.app_service_plan_id
  storage_connection_string = var.storage_connection_string

  # dynamic "identity" {
  #   for_each = var.managed_accounts

  #   content {
  #     type         = "UserAssigned"
  #     identity_ids = each.value
  #   }
  # }

  app_settings = lookup(local.app_settings, each.key, "")

  client_affinity_enabled = false
  enabled                 = true
  https_only              = true
  version                 = "~2"

  site_config {
    always_on                 = true
    use_32_bit_worker_process = true
    websockets_enabled        = false
    cors {
      allowed_origins     = []
      support_credentials = false
    }
  }
}

resource "azurerm_template_deployment" "vnetintegration" {
  for_each = var.apps

  name                = each.key
  resource_group_name = azurerm_resource_group.app[each.key].name

  template_body = <<DEPLOY
  {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "siteName": {
        "type": "string"
      },
      "subnet_resourceid": {
        "type": "string"
      },
      "null": {
        "type": "string"
      }
    },
    "resources": [
      {
        "type": "Microsoft.Web/sites/config",
        "apiVersion": "2016-08-01",
        "name": "[concat(parameters('siteName'), '/virtualNetwork')]",
        "location": "UK West",
        "properties": {
          "subnetResourceId": "[parameters('subnet_resourceid')]",
          "swiftSupported": true
        }
      }
    ]
  }
DEPLOY

  parameters = {
    siteName          = azurerm_function_app.app["${each.key}"].name
    subnet_resourceid = each.value.vnet_integ_subnet_id
    null = uuid()
  }

  deployment_mode = "Incremental"
}
