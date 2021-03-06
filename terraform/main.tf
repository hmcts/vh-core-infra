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
  storage_account_id  = azurerm_storage_account.vh-core-infra.id
}

module AppService {
  source = "./modules/AppService"

  apps = {
    for def in keys(local.app_definitions) :
    def => {
      name                 = local.app_definitions[def].name
      websockets           = local.app_definitions[def].websockets
      ip_restriction       = tolist(concat(length(local.app_definitions[def].ip_restriction) == 0 ? [] : local.app_definitions[def].ip_restriction, [local.app_definitions[def].audience_subnet == "backend" ? module.WebAppSecurity.backend_subnet_id : module.WebAppSecurity.frontend_subnet_id]))
      vnet_integ_subnet_id = local.app_definitions[def].subnet == "backend" ? module.WebAppSecurity.backend_subnet_id : module.WebAppSecurity.frontend_subnet_id
    }
  }
  resource_group_name = azurerm_resource_group.vh-core-infra.name
  resource_prefix     = "${local.std_prefix}${local.suffix}"

  storage_connection_string        = azurerm_storage_account.vh-core-infra.primary_connection_string
  signalr_connection_str           = module.SignalR.signalr_connection_str
  app_insights_instrumentation_key = module.Monitoring.instrumentation_key
  managed_accounts = {
    sqluser = module.VHDataServices.sqluser.id
    kvuser  = module.VHDataServices.kvuser.id
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

  providers = {
    azuread = "azuread.idam"
  }

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
    sqluser = module.VHDataServices.sqluser.id
    kvuser  = module.VHDataServices.kvuser.id
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

  delegated_networks = merge({
    for subnet in var.build_agent_vnet :
    "AccessFromBuildAgent${index(var.build_agent_vnet, subnet)}" => subnet
    },
    {
      AccessFromBackendServices = module.WebAppSecurity.backend_subnet_id
  })
  public_env = local.environment == "dev" ? 1 : 0

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

data azuread_group devs {
  provider = azuread.infra

  name = var.dev_group
}

module InfraSecrets {
  source = "./modules/InfraSecrets"

  resource_group_name = azurerm_resource_group.vh-core-infra.name
  resource_prefix     = local.std_prefix

  apps = {
    for def in keys(local.app_registrations) :
    def => {
      application_id = module.AppRegistrations.app_registrations[def].application_id
      secret         = module.AppRegistrations.app_passwords[def].value
      url            = local.app_registrations[def].url
    }
  }
  secrets = {
    signalr_connection_str         = module.SignalR.signalr_connection_str
    appconfig_connection_str       = module.AppConfiguration.appconfig_connection_str
    appconfig_connection_str_write = module.AppConfiguration.appconfig_connection_str_write
    kv_mi_client_id = module.VHDataServices.kvuser.client_id
    sql_mi_client_id = module.VHDataServices.sqluser.client_id
  }
  delegated_networks = merge({
    for subnet in var.build_agent_vnet :
    "AccessFromBuildAgent${index(var.build_agent_vnet, subnet)}" => subnet
    },
    {
      AccessFromBackendServices = module.WebAppSecurity.backend_subnet_id
  })
  secret_readers = local.environment == "dev" ? {
    kv_user = module.VHDataServices.kvuser.principal_id
    devs    = data.azuread_group.devs.id
    } : {
    kv_user = module.VHDataServices.kvuser.principal_id
  }
  public_env = local.environment == "dev" ? 1 : 0
}

module "SignalR" {
  source = "./modules/SignalR"

  resource_prefix     = "${local.std_prefix}${local.suffix}"
  resource_group_name = azurerm_resource_group.vh-core-infra.name
}

module "AppConfiguration" {
  source = "./modules/AppConfiguration"

  resource_prefix     = "${local.std_prefix}${local.suffix}"
  resource_group_name = azurerm_resource_group.vh-core-infra.name
}

module HearingsDNS {
  source = "./modules/DnsZone"

  providers = {
    azurerm = "azurerm.dns"
  }

  resource_group_name = "vh-hearings-reform-hmcts-net-dns-zone"
  zone_name           = "hearings.reform.hmcts.net"

  a = {
    for def in local.web_apps :
    def.name => {
      name  = def.name
      type  = "a"
      value = module.WebAppSecurity.app_gateway_public_ip
    }
  }
  cnames = {
    for def in(local.environment == "prod" ? local.prod_cnames : []) :
    def.name => {
      name  = def.name
      type  = "c"
      value = def.destination
    }
  }
}

module AMS {
  source = "./modules/AMS"

  resource_prefix     = "${local.std_prefix}${local.suffix}"
  resource_group_name = azurerm_resource_group.vh-core-infra.name
  storage_account_id  = azurerm_storage_account.vh-core-infra.id
}
