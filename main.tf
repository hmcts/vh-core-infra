terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "infra/vh-core-infra.tfstate"
  }
}

provider "azurerm" {
  version = ">= 1.36.0"
}

provider "azuread" {
  version = "~> 0.6"

  tenant_id     = var.idam_tenant_id
  client_id     = var.idam_client_id
  client_secret = var.idam_client_secret

  subscription_id = "not needed"
}

locals {
  environment = lookup(var.workspace_to_environment_map, terraform.workspace, "preview")
  suffix      = "-${local.environment}"
  web_apps = [
    {
      name        = "vh-admin-web${local.suffix}",
      fqdn        = ["vh-admin-web${local.suffix}.azurewebsites.net"],
      public_fqdn = "vh-admin-web${local.suffix}.hearings.reform.hmcts.net"
    },
    {
      name        = "vh-service-web${local.suffix}",
      fqdn        = ["vh-service-web${local.suffix}.azurewebsites.net"],
      public_fqdn = "vh-service-web${local.suffix}.hearings.reform.hmcts.net"
    },
    {
      name        = "vh-video-web${local.suffix}",
      fqdn        = ["vh-video-web${local.suffix}.azurewebsites.net"],
      public_fqdn = "vh-video-web${local.suffix}.hearings.reform.hmcts.net"
    }
  ]

  prod_cnames = [
    {
      name        = "video",
      destination = "vh-video-web${local.suffix}.hearings.reform.hmcts.net"
      app         = "vh-video-web${local.suffix}"
      fqdn        = "video.hearings.reform.hmcts.net"
    },
    {
      name        = "admin",
      destination = "vh-admin-web${local.suffix}.hearings.reform.hmcts.net"
      app         = "vh-admin-web${local.suffix}"
      fqdn        = "admin.hearings.reform.hmcts.net"
    },
    {
      name        = "service",
      destination = "vh-service-web${local.suffix}.hearings.reform.hmcts.net"
      app         = "vh-service-web${local.suffix}"
      fqdn        = "service.hearings.reform.hmcts.net"
    }
  ]

  test_endpoints = {
    admin-web-public = {
      public_fqdn = "vh-admin-web${local.suffix}.hearings.reform.hmcts.net"
    }
    service-web-public = {
      public_fqdn = "vh-service-web${local.suffix}.hearings.reform.hmcts.net"
    }
    video-web-public = {
      public_fqdn = "vh-video-web${local.suffix}.hearings.reform.hmcts.net"
    }
    admin-web = {
      public_fqdn = "vh-admin-web${local.suffix}.azurewebsites.net"
    }
    service-web = {
      public_fqdn = "vh-service-web${local.suffix}.azurewebsites.net"
    }
    video-web = {
      public_fqdn = "vh-video-web${local.suffix}.azurewebsites.net"
    }
    bookings-api = {
      public_fqdn = "vh-bookings-api${local.suffix}.azurewebsites.net"
    }
    user-api = {
      public_fqdn = "vh-user-api${local.suffix}.azurewebsites.net"
    }
    video-api = {
      public_fqdn = "vh-video-api${local.suffix}.azurewebsites.net"
    }
  }

  app_definitions = {
    admin-web = {
      name            = "vh-admin-web${local.suffix}"
      websockets      = false
      ip_restriction  = []
      subnet          = "backend"
      audience_subnet = "frontend"
      url             = "https://vh-admin-web${local.suffix}.hearings.reform.hmcts.net"
    }
    service-web = {
      name            = "vh-service-web${local.suffix}"
      websockets      = false
      ip_restriction  = []
      subnet          = "backend"
      audience_subnet = "frontend"
      url             = "https://vh-service-web${local.suffix}.hearings.reform.hmcts.net"
    }
    video-web = {
      name            = "vh-video-web${local.suffix}"
      websockets      = true
      ip_restriction  = []
      subnet          = "backend"
      audience_subnet = "frontend"
      url             = "https://vh-video-web${local.suffix}.hearings.reform.hmcts.net"
    }
    bookings-api = {
      name            = "vh-bookings-api${local.suffix}"
      websockets      = false
      ip_restriction  = []
      subnet          = "backend"
      audience_subnet = "backend"
      url             = "https://vh-bookings-api${local.suffix}.azurewebsites.net"
    }
    user-api = {
      name            = "vh-user-api${local.suffix}"
      websockets      = false
      ip_restriction  = []
      subnet          = "backend"
      audience_subnet = "backend"
      url             = "https://vh-user-api${local.suffix}.azurewebsites.net"
    }
    video-api = {
      name            = "vh-video-api${local.suffix}"
      websockets      = false
      ip_restriction  = []
      subnet          = "backend"
      audience_subnet = "backend"
      url             = "https://vh-video-api${local.suffix}.azurewebsites.net"
    }
  }

  funcapp_definitions = {
    booking-queue-subscriber = {
      name   = "vh-booking-queue-subscriber${local.suffix}"
      subnet = "backend"
      url    = "https://vh-booking-queue-subscriber${local.suffix}.azurewebsites.net"
    }
  }

  app_registrations = merge(
    {
      for def in keys(local.app_definitions) :
      def => {
        name = local.app_definitions[def].name
        url  = local.app_definitions[def].url
      }
    },
    {
      for def in keys(local.funcapp_definitions) :
      def => {
        name = local.funcapp_definitions[def].name
        url  = local.funcapp_definitions[def].url
      }
    }
  )

  common_prefix = "core-infra"
  std_prefix    = "vh-${local.common_prefix}"
}

resource "azurerm_resource_group" "vh-core-infra" {
  name     = "${local.std_prefix}${local.suffix}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "vh-core-infra" {
  name                = replace(lower("${local.std_prefix}${local.suffix}"), "-", "")
  resource_group_name = azurerm_resource_group.vh-core-infra.name
  location            = azurerm_resource_group.vh-core-infra.location

  access_tier                       = "Hot"
  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  enable_blob_encryption            = true
  enable_file_encryption            = true
  enable_https_traffic_only         = true
  account_encryption_source         = "Microsoft.Storage"
  enable_advanced_threat_protection = true
}

module WebAppSecurity {
  source = "./modules/WAF"

  backend_apps        = local.web_apps
  redirects           = local.environment == "prod" ? local.prod_cnames : []
  resource_group_name = azurerm_resource_group.vh-core-infra.name
  keyvault_id         = module.VHDataServices.keyvault_id
}

module AppService {
  source = "./modules/AppService"

  apps = {
    for def in keys(local.app_definitions) :
    def => {
      name                 = local.app_definitions[def].name
      websockets           = local.app_definitions[def].websockets
      ip_restriction       = concat(local.app_definitions[def].ip_restriction, [local.app_definitions[def].audience_subnet == "backend" ? module.WebAppSecurity.backend_subnet_id : module.WebAppSecurity.frontend_subnet_id])
      vnet_integ_subnet_id = local.app_definitions[def].subnet == "backend" ? module.WebAppSecurity.backend_subnet_id : module.WebAppSecurity.frontend_subnet_id
    }
  }
  resource_group_name = azurerm_resource_group.vh-core-infra.name
  resource_prefix     = "${local.std_prefix}${local.suffix}"

  storage_connection_string        = azurerm_storage_account.vh-core-infra.primary_connection_string
  app_insights_instrumentation_key = module.Monitoring.instrumentation_key
  managed_accounts = {
    sqluser = module.VHDataServices.sqluser
    kvuser  = module.VHDataServices.kvuser
  }
  idam_client_id      = zipmap(keys(module.AppRegistrations.app_registrations), values(module.AppRegistrations.app_registrations)[*].application_id)
  idam_client_secret  = zipmap(keys(module.AppRegistrations.app_passwords), values(module.AppRegistrations.app_passwords)[*].value)
  idam_tenant_id      = var.idam_tenant_id
  app_url             = zipmap(keys(local.app_definitions), values(local.app_definitions)[*].url)
  service_bus_connstr = module.VHDataServices.service_bus_connstr
  db_server_name      = module.VHDataServices.db_server_name
  db_admin_password   = module.VHDataServices.db_admin_password
}

module AppRegistrations {
  source = "./modules/AppRegistrations"

  apps = local.app_registrations
}

module FuncApps {
  source = "./modules/FuncApps"

  apps = {
    for def in keys(local.funcapp_definitions) :
    def => {
      name                 = local.funcapp_definitions[def].name
      vnet_integ_subnet_id = local.funcapp_definitions[def].subnet == "backend" ? module.WebAppSecurity.backend_subnet_id : module.WebAppSecurity.frontend_subnet_id
    }
  }
  resource_group_name = azurerm_resource_group.vh-core-infra.name
  resource_prefix     = "${local.std_prefix}${local.suffix}"

  app_service_plan_id              = module.AppService.appservice_id
  storage_connection_string        = azurerm_storage_account.vh-core-infra.primary_connection_string
  app_insights_instrumentation_key = module.Monitoring.instrumentation_key
  managed_accounts = {
    sqluser = module.VHDataServices.sqluser
    kvuser  = module.VHDataServices.kvuser
  }
  idam_client_id      = zipmap(keys(module.AppRegistrations.app_registrations), values(module.AppRegistrations.app_registrations)[*].application_id)
  idam_client_secret  = zipmap(keys(module.AppRegistrations.app_passwords), values(module.AppRegistrations.app_passwords)[*].value)
  idam_tenant_id      = var.idam_tenant_id
  app_url             = zipmap(keys(local.app_definitions), values(local.app_definitions)[*].url)
  service_bus_connstr = module.VHDataServices.service_bus_connstr
}

module Monitoring {
  source = "./modules/Monitoring"

  apps                = local.test_endpoints
  resource_group_name = azurerm_resource_group.vh-core-infra.name
  resource_prefix     = "${local.std_prefix}${local.suffix}"
}

module VHDataServices {
  source = "./modules/VHDataServices"

  delegated_networks = {
    AccessFromBackendServices = module.WebAppSecurity.backend_subnet_id
    AccessFromBuildAgent      = var.build_agent_vnet
  }
  databases = {
    hearing = {
      collation         = "SQL_Latin1_General_CP1_CI_AS"
      edition           = "Standard"
      performance_level = "S0"
    }
    vhbookings = {
      collation         = "SQL_Latin1_General_CP1_CI_AS"
      edition           = "Standard"
      performance_level = "S0"
    }
    vhvideo = {
      collation         = "SQL_Latin1_General_CP1_CI_AS"
      edition           = "Standard"
      performance_level = "S0"
    }
  }
  queues = {
    booking = {
      collation         = "SQL_Latin1_General_CP1_CI_AS"
      edition           = "Standard"
      performance_level = "S0"
    }
    video = {
      collation         = "SQL_Latin1_General_CP1_CI_AS"
      edition           = "Standard"
      performance_level = "S0"
    }
  }
  resource_group_name = azurerm_resource_group.vh-core-infra.name
  resource_prefix     = "${local.std_prefix}${local.suffix}"
}

module InfraSecrets {
  source = "./modules/InfraSecrets"

  resource_group_name = azurerm_resource_group.vh-core-infra.name
  resource_prefix     = local.std_prefix

  apps = {
    for def in keys(local.app_definitions) :
    def => {
      application_id = module.AppRegistrations.app_registrations[def].application_id
      secret         = module.AppRegistrations.app_passwords[def].value
      url            = local.app_definitions[def].url
    }
  }
  delegated_networks = {
    AccessFromBuildAgent = var.build_agent_vnet
  }
}

# module HearingsDNS {
#   source = "./modules/DnsZone"

#   resource_group_name = "vh-hearings-reform-hmcts-net-dns-zone"
#   zone_name           = "hearings.reform.hmcts.net"

#   a = {
#     for def in local.web_apps :
#     def.name => {
#       name  = def.name
#       type  = "a"
#       value = module.WebAppSecurity.app_gateway_public_ip
#     }
#   }
#   cnames = {
#     for def in(local.environment == "prod" ? local.prod_cnames : []) :
#     def.name => {
#       name  = def.name
#       type  = "c"
#       value = def.destination
#     }
#   }
# }
