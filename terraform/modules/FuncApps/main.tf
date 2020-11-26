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

  # identity {
  #   type         = "UserAssigned"
  #   identity_ids = values(var.managed_accounts)
  # }

  app_settings = lookup(local.app_settings, each.key, "")

  client_affinity_enabled = false
  enabled                 = true
  https_only              = true
  version                 = lookup(local.version, each.key, "~3")

  site_config {
    always_on                 = true
    use_32_bit_worker_process = true
    websockets_enabled        = false
    cors {
      allowed_origins     = []
      support_credentials = false
    }
    virtual_network_name = "ignore"
  }

  lifecycle {
    ignore_changes = [
      site_config.0.virtual_network_name,
      app_settings
    ]
  }
}

# resource "azurerm_app_service_slot" "staging" {
#   for_each = var.apps

#   name                = "staging"
#   location            = azurerm_resource_group.app[each.key].location
#   resource_group_name = azurerm_resource_group.app[each.key].name
#   app_service_plan_id = var.app_service_plan_id
#   app_service_name    = each.value.name

#   # dynamic "identity" {
#   #   for_each = var.managed_accounts

#   #   content {
#   #     type         = "UserAssigned"
#   #     identity_ids = each.value
#   #   }
#   # }

#   app_settings = lookup(local.app_settings, each.key, "")

#   client_affinity_enabled = false
#   enabled                 = true
#   https_only              = true

#   site_config {
#     always_on                 = true
#     use_32_bit_worker_process = true
#     websockets_enabled        = false
#     cors {
#       allowed_origins     = []
#       support_credentials = false
#     }
#     virtual_network_name = "ignore"
#   }

#   lifecycle {
#     ignore_changes = [
#       site_config.0.virtual_network_name,
#       app_settings["AzureWebJobsDashboard"],
#       app_settings["AzureWebJobsStorage"],
#       app_settings["FUNCTIONS_EXTENSION_VERSION"]
#     ]
#   }
# }

resource "azurerm_app_service_virtual_network_swift_connection" "vnetintegration" {
  for_each = var.apps

  app_service_id = azurerm_function_app.app[each.key].id
  subnet_id      = each.value.vnet_integ_subnet_id
}
