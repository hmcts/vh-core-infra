locals {
  common_prefix     = "core-infra"
  std_prefix        = "vh-${local.common_prefix}"
  environment       = lookup(var.workspace_to_environment_map, terraform.workspace, "preview")
  suffix            = "-${local.environment}"
  waf_address_space = ["10.254.0.0/25"]
}

data "azurerm_resource_group" "vh-core-infra" {
  name = var.resource_group_name
}

# data "azurerm_network_ddos_protection_plan" "ddos" {
#   name                = "${local.common_prefix}-ddos"
#   resource_group_name = "${local.common_prefix}-ddos"
# }

resource "azurerm_virtual_network" "WAF" {
  name                = "${local.std_prefix}${local.suffix}"
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location
  address_space       = local.waf_address_space

  ddos_protection_plan {
    # id     = data.azurerm_network_ddos_protection_plan.ddos.id
    id     = "/subscriptions/705b2731-0e0b-4df7-8630-95f157f0a347/resourceGroups/core-infra-ddos/providers/Microsoft.Network/ddosProtectionPlans/core-infra-ddos"
    enable = true
  }
}

resource "azurerm_subnet" "backend" {
  name                 = "${local.std_prefix}-waf-back${local.suffix}"
  resource_group_name  = data.azurerm_resource_group.vh-core-infra.name
  virtual_network_name = azurerm_virtual_network.WAF.name
  address_prefix       = "${cidrsubnet(local.waf_address_space[0], 3, 0)}"

  delegation {
    name = "App-Service-Delegation"
    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
      name = "Microsoft.Web/serverFarms"
    }
  }

  service_endpoints = [
    "Microsoft.Web",
    "Microsoft.Sql",
    "Microsoft.KeyVault"
  ]
}

resource "azurerm_subnet" "frontend" {
  name                 = "${local.std_prefix}-waf-front${local.suffix}"
  resource_group_name  = data.azurerm_resource_group.vh-core-infra.name
  virtual_network_name = azurerm_virtual_network.WAF.name
  address_prefix       = "${cidrsubnet(local.waf_address_space[0], 3, 1)}"

  service_endpoints = [
    "Microsoft.Web"
  ]
}

resource "azurerm_public_ip" "waf_ip" {
  name                = "${local.std_prefix}-waf01${local.suffix}"
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

data "azurerm_key_vault_secret" "certificate" {
  name         = "wildcard-hearings-reform-hmcts-net"
  key_vault_id = var.keyvault_id
}

locals {
  frontend_port_name             = "${azurerm_virtual_network.WAF.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.WAF.name}-feip"
}

resource "azurerm_application_gateway" "waf" {
  name                = "${local.std_prefix}${local.suffix}"
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 3
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.1"

    disabled_rule_group {
      rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
      rules = [
        942440
      ]
    }

    disabled_rule_group {
      rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
      rules = [
        920300,
        920440
      ]
    }
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.waf_ip.id
  }

  ssl_certificate {
    name     = "wildcard-hearings-reform-hmcts-net"
    data     = data.azurerm_key_vault_secret.certificate.value
    password = ""
  }

  frontend_port {
    name = "${local.frontend_port_name}"
    port = 443
  }

  backend_address_pool {
    name = "null"
  }

  dynamic "backend_address_pool" {
    for_each = [for b in var.backend_apps : {
      name = "${b.name}-beap"
      fqdn = b.fqdn
    }]

    content {
      name  = backend_address_pool.value.name
      fqdns = backend_address_pool.value.fqdn
    }
  }

  dynamic "backend_http_settings" {
    for_each = [for b in var.backend_apps : {
      name = "${b.name}-be-htst"
    }]

    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = "Disabled"
      affinity_cookie_name                = backend_http_settings.value.name
      path                                = "/"
      port                                = 443
      protocol                            = "Https"
      request_timeout                     = 20
      probe_name                          = backend_http_settings.value.name
      pick_host_name_from_backend_address = true
    }
  }

  dynamic "http_listener" {
    for_each = [for b in var.backend_apps : {
      name = "${b.name}-httplstn"
      fqdn = b.public_fqdn
    }]

    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.frontend_port_name
      protocol                       = "Https"
      ssl_certificate_name           = "wildcard-hearings-reform-hmcts-net"
      host_name                      = http_listener.value.fqdn
    }
  }

  dynamic "http_listener" {
    for_each = [for b in var.redirects : {
      name = "${b.name}-httplstn"
      fqdn = b.fqdn
    }]

    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.frontend_port_name
      protocol                       = "Https"
      ssl_certificate_name           = "wildcard-hearings-reform-hmcts-net"
      host_name                      = http_listener.value.fqdn
    }
  }

  dynamic "request_routing_rule" {
    for_each = [for b in var.backend_apps : {
      name         = "${b.name}-rqrt"
      listener     = "${b.name}-httplstn"
      httpsettings = "${b.name}-be-htst"
      be_pool      = "${b.name}-beap"
      path_map     = "${b.name}-pathmap"
    }]

    content {
      name               = request_routing_rule.value.name
      rule_type          = "PathBasedRouting"
      http_listener_name = request_routing_rule.value.listener
      url_path_map_name  = request_routing_rule.value.path_map
    }
  }

  dynamic "request_routing_rule" {
    for_each = [for b in var.redirects : {
      name         = "${b.name}-rqrt"
      listener     = "${b.name}-httplstn"
      httpsettings = "${b.app}-be-htst"
      be_pool      = "${b.app}-beap"
      path_map     = "${b.app}-pathmap"
    }]

    content {
      name               = request_routing_rule.value.name
      rule_type          = "PathBasedRouting"
      http_listener_name = request_routing_rule.value.listener
      url_path_map_name  = request_routing_rule.value.path_map
    }
  }

  dynamic "url_path_map" {
    for_each = [for b in var.backend_apps : {
      name         = "${b.name}-pathmap"
      listener     = "${b.name}-httplstn"
      httpsettings = "${b.name}-be-htst"
      be_pool      = "${b.name}-beap"
    }]

    content {
      name                               = url_path_map.value.name
      default_backend_address_pool_name  = url_path_map.value.be_pool
      default_backend_http_settings_name = url_path_map.value.httpsettings

      path_rule {
        name                       = "EverythingElse"
        paths                      = ["/*"]
        backend_address_pool_name  = url_path_map.value.be_pool
        backend_http_settings_name = url_path_map.value.httpsettings
      }
    }
  }

  dynamic "probe" {
    for_each = [for b in var.backend_apps : {
      name         = "${b.name}-be-htst"
      listener     = "${b.name}-httplstn"
      httpsettings = "${b.name}-be-htst"
      be_pool      = "${b.name}-beap"
    }]

    content {
      interval                                  = 30
      minimum_servers                           = 0
      name                                      = probe.value.name
      path                                      = "/"
      pick_host_name_from_backend_http_settings = true
      protocol                                  = "Https"
      timeout                                   = 30
      unhealthy_threshold                       = 3

      match {
        status_code = [200, 403]
        body        = ""
      }
    }
  }
}

output "backend_subnet_id" {
  value = azurerm_subnet.backend.id
}

output "frontend_subnet_id" {
  value = azurerm_subnet.frontend.id
}

output "backend_subnet_name" {
  value = azurerm_subnet.backend.name
}

output "frontend_subnet_name" {
  value = azurerm_subnet.frontend.name
}

output "app_gateway_public_ip_id" {
  value = azurerm_public_ip.waf_ip.id
}

output "app_gateway_public_ip" {
  value = azurerm_public_ip.waf_ip.ip_address
}
