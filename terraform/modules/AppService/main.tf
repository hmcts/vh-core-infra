data "azurerm_resource_group" "vh-core-infra" {
  name = var.resource_group_name
}

resource "azurerm_app_service_plan" "appplan" {
  name                = var.resource_prefix
  location            = data.azurerm_resource_group.vh-core-infra.location
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name

  kind = "app"

  sku {
    tier = local.sku.tier
    size = local.sku.size
  }

  per_site_scaling = false
  reserved         = false
}

resource "azurerm_monitor_autoscale_setting" "appplan" {
  name                = "${var.resource_prefix}-appService"
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location
  target_resource_id  = azurerm_app_service_plan.appplan.id

  profile {
    name = "Scale with Memory Utilisation"

    capacity {
      default = 1
      minimum = 1
      maximum = 1
    }

    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_app_service_plan.appplan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_app_service_plan.appplan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 50
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      custom_emails = var.scaling_notification_email
    }
  }
}

resource "azurerm_resource_group" "web" {
  for_each = var.apps

  name     = each.value.name
  location = data.azurerm_resource_group.vh-core-infra.location
  tags     = local.common_tags
}

locals {
  monitoring_ips = [
    "51.105.9.128/28",
    "51.105.9.144/28",
    "51.105.9.160/28",
    "20.40.104.96/28",
    "20.40.104.112/28",
    "20.40.104.128/28",
    "20.40.104.144/28"
  ]
}

resource "azurerm_app_service" "app" {
  for_each = var.apps

  name                = each.value.name
  location            = azurerm_resource_group.web[each.key].location
  resource_group_name = azurerm_resource_group.web[each.key].name
  app_service_plan_id = azurerm_app_service_plan.appplan.id

  https_only = true

  app_settings = lookup(local.app_settings, each.key, "")

  dynamic "connection_string" {
    for_each = local.connection_string[each.key]

    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = values(var.managed_accounts)
  }

  site_config {
    dotnet_framework_version  = "v4.0"
    always_on                 = true
    websockets_enabled        = each.value.websockets
    use_32_bit_worker_process = false

    default_documents = []

    dynamic "ip_restriction" {
      for_each = each.value.ip_restriction

      content {
        virtual_network_subnet_id = ip_restriction.value
      }
    }

    dynamic "ip_restriction" {
      for_each = terraform.workspace == "Dev" ? concat(["0.0.0.0/0"], local.monitoring_ips) : local.monitoring_ips

      content {
        ip_address  = cidrhost(ip_restriction.value, 0)
        subnet_mask = cidrnetmask(ip_restriction.value)
      }
    }

    cors {
      allowed_origins     = []
      support_credentials = false
    }

    virtual_network_name = "ignore"
  }

  auth_settings {
    enabled = false
  }

  lifecycle {
    ignore_changes = [
      site_config.0.virtual_network_name,
      site_config.0.scm_type,
      app_settings,
      connection_string
    ]
  }
}

resource "azurerm_app_service_slot" "staging" {
  for_each = var.apps

  name                = "staging"
  location            = azurerm_resource_group.web[each.key].location
  resource_group_name = azurerm_resource_group.web[each.key].name
  app_service_plan_id = azurerm_app_service_plan.appplan.id
  app_service_name    = each.value.name

  https_only = true

  app_settings = lookup(local.app_settings, each.key, "")

  dynamic "connection_string" {
    for_each = local.connection_string[each.key]

    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = values(var.managed_accounts)
  }

  site_config {
    dotnet_framework_version  = "v4.0"
    always_on                 = true
    websockets_enabled        = each.value.websockets
    use_32_bit_worker_process = false

    default_documents = []

    dynamic "ip_restriction" {
      for_each = each.value.ip_restriction

      content {
        virtual_network_subnet_id = ip_restriction.value
      }
    }

    dynamic "ip_restriction" {
      for_each = local.monitoring_ips

      content {
        ip_address  = cidrhost(ip_restriction.value, 0)
        subnet_mask = cidrnetmask(ip_restriction.value)
      }
    }

    cors {
      allowed_origins     = []
      support_credentials = false
    }

    virtual_network_name = "ignore"
  }

  auth_settings {
    enabled = false
  }

  lifecycle {
    ignore_changes = [
      site_config.0.virtual_network_name,
      site_config.0.scm_type,
      app_settings,
      connection_string
    ]
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnetintegration" {
  for_each = var.apps

  app_service_id = azurerm_app_service.app[each.key].id
  subnet_id      = each.value.vnet_integ_subnet_id
}

output "appservice_id" {
  value = azurerm_app_service_plan.appplan.id
}
