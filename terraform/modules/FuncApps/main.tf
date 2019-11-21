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

resource "azurerm_template_deployment" "vnetintegration" {
  for_each = var.apps

  name                = each.key
  resource_group_name = azurerm_resource_group.app[each.key].name

  template_body = file("${path.module}/vnetintegration.json")

  parameters = {
    siteName          = azurerm_function_app.app[each.key].name
    subnet_resourceid = each.value.vnet_integ_subnet_id
    null              = uuid()
  }

  deployment_mode = "Incremental"

  depends_on = [
    azurerm_function_app.app,
    azurerm_template_deployment.funcapp-staging
  ]
}

resource "azurerm_template_deployment" "funcapp-staging" {
  for_each = var.apps

  name                = each.key
  resource_group_name = azurerm_resource_group.app[each.key].name

  template_body = file("${path.module}/funcapp-slot.json")

  parameters = {
    siteName = azurerm_function_app.app[each.key].name
    slot     = "staging"
    location = azurerm_resource_group.app[each.key].location
    farm_id  = var.app_service_plan_id
  }

  deployment_mode = "Incremental"
}

resource "azurerm_template_deployment" "vnetintegration-staging" {
  for_each = var.apps

  name                = each.key
  resource_group_name = azurerm_resource_group.app[each.key].name

  template_body = file("${path.module}/vnetintegration-slot.json")

  parameters = {
    siteName          = azurerm_function_app.app[each.key].name
    slot              = "staging"
    subnet_resourceid = each.value.vnet_integ_subnet_id
    null              = uuid()
  }

  deployment_mode = "Incremental"

  depends_on = [
    azurerm_template_deployment.funcapp-staging,
    azurerm_function_app.app
  ]
}
