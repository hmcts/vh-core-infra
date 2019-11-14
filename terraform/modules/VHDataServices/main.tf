data "azurerm_resource_group" "vh-core-infra" {
  name = var.resource_group_name
}

locals {
  environment = lookup(var.workspace_to_environment_map, terraform.workspace, "preview")
}

resource "azurerm_user_assigned_identity" "sqluser" {
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location

  name = "${var.resource_prefix}-sqluser"
}

resource "random_password" "sqlpass" {
  length  = 32
  special = true
  override_special = "_%@"
}

resource "azurerm_sql_server" "vh-core-infra" {
  name                         = var.resource_prefix
  resource_group_name          = data.azurerm_resource_group.vh-core-infra.name
  location                     = data.azurerm_resource_group.vh-core-infra.location
  version                      = "12.0"
  administrator_login          = "hvhearingsapiadmin"
  administrator_login_password = random_password.sqlpass.result

  tags = {
    displayName = "Virtual Courtroom SQL Server"
  }
}

resource "azurerm_template_deployment" "sqlbackup" {
  for_each = if terraform.workspace == "Prod" ? var.databases : {}

  name                = "db-backup-${each.key}"
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name

  template_body = <<DEPLOY
  {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "databaseServerName": {
        "type": "string"
      },
      "database": {
        "type": "array"
      }
    },
    "resources": [
      {
        "type": "Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies",
        "name": "[concat(parameters('databaseServerName'), "/", parameters('database')[copyIndex()], '/Default')]",
        "tags": { "displayName": "Database Backup" },
        "apiVersion": "2017-03-01-preview",
        "location": "UK West",
        "scale": null,
        "properties": {
          "retentionDays": 35
        },
        "copy": {
          "name": "db-short",
          "count": "[length(parameters('database'))]"
        }
      },
      {
        "type": "Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies",
        "name": "[concat(parameters('databaseServerName'), "/", parameters('database')[copyIndex()], '/Default')]",
        "tags": { "displayName": "Database Backup" },
        "apiVersion": "2017-03-01-preview",
        "location": "UK West",
        "scale": null,
        "properties": {
          "weeklyRetention": "P8W",
          "monthlyRetention": "P12M",
          "yearlyRetention": "P5Y",
          "weekOfYear": "1"
        },
        "copy": {
          "name": "db-long",
          "count": "[length(parameters('database'))]"
        }
      }
    ]
  }
DEPLOY

  parameters = {
    databaseServerName = azurerm_sql_server.vh-core-infra.name
    database           = keys(var.databases)
  }

  deployment_mode = "Incremental"
}

resource "azurerm_sql_active_directory_administrator" "sqluser" {
  server_name         = azurerm_sql_server.vh-core-infra.name
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name

  login     = azurerm_user_assigned_identity.sqluser.name
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_user_assigned_identity.sqluser.principal_id
}

resource "azurerm_key_vault_secret" "VhBookingsDatabaseConnectionString" {
  name         = "VhBookingsDatabaseConnectionString"
  value        = "Server=tcp:${azurerm_sql_server.vh-core-infra.name}.database.windows.net,1433;Initial Catalog=vhbookings;Persist Security Info=False;User ID=${azurerm_sql_server.vh-core-infra.administrator_login};Password=${random_password.sqlpass.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.vh-core-infra.id
}

resource "azurerm_key_vault_secret" "VhVideoDatabaseConnectionString" {
  name         = "VhVideoDatabaseConnectionString"
  value        = "Server=tcp:${azurerm_sql_server.vh-core-infra.name}.database.windows.net,1433;Initial Catalog=vhvideo;Persist Security Info=False;User ID=${azurerm_sql_server.vh-core-infra.administrator_login};Password=${random_password.sqlpass.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.vh-core-infra.id
}

resource "azurerm_sql_virtual_network_rule" "sqlvnetrule" {
  count = 3

  name                = keys(var.delegated_networks)[count.index]
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  server_name         = azurerm_sql_server.vh-core-infra.name
  subnet_id           = var.delegated_networks[keys(var.delegated_networks)[count.index]]
}

resource "azurerm_sql_database" "vh-core-infra" {
  for_each = var.databases

  name                = each.key
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location
  server_name         = azurerm_sql_server.vh-core-infra.name

  edition                          = each.value.edition
  collation                        = each.value.collation
  requested_service_objective_name = each.value.performance_level
}

resource "azurerm_servicebus_namespace" "vh-core-infra" {
  name                = var.resource_prefix
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "vh-core-infra" {
  for_each = var.queues

  name                = each.key
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  namespace_name      = azurerm_servicebus_namespace.vh-core-infra.name

  enable_partitioning   = false
  lock_duration         = "PT5M"
  max_size_in_megabytes = 1024
}

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "kvuser" {
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  location            = data.azurerm_resource_group.vh-core-infra.location

  name = "${var.resource_prefix}-kvuser"
}

resource "azurerm_key_vault" "vh-core-infra" {
  name                        = replace(var.resource_prefix, "-", "")
  resource_group_name         = data.azurerm_resource_group.vh-core-infra.name
  location                    = data.azurerm_resource_group.vh-core-infra.location
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  # Azure App Service
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "20a66321-932e-4d33-a316-682849a06d68"

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
    ]

    certificate_permissions = [
      "get",
    ]
  }

  # kv user identity
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.kvuser.principal_id

    certificate_permissions = [
      "get",
    ]

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
      "list",
      "set"
    ]
  }

  # vsts automation
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "1fb13944-cfd1-44e2-96a4-9ee10a1932db"

    certificate_permissions = [
      "get",
    ]

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
      "list",
      "set"
    ]
  }

  # vsts automation
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "655eb910-cf45-403b-b2ff-d8ee40a5cd69"

    certificate_permissions = [
      "get",
    ]

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
      "list",
      "set"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "backup",
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "purge",
      "recover",
      "restore",
      "setissuers",
      "update"
    ]

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey"
    ]

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set"
    ]

    storage_permissions = [
      "backup",
      "delete",
      "deletesas",
      "get",
      "getsas",
      "list",
      "listsas",
      "purge",
      "recover",
      "regeneratekey",
      "restore",
      "set",
      "setsas",
      "update"
    ]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "None"
    ip_rules = []
    virtual_network_subnet_ids = values(var.delegated_networks)
  }
}

output "sqluser" {
  value = azurerm_user_assigned_identity.sqluser.id
}

output "kvuser" {
  value = azurerm_user_assigned_identity.kvuser.id
}

output "service_bus_connstr" {
  value = azurerm_servicebus_namespace.vh-core-infra.default_primary_connection_string
}

output "db_admin_password" {
  value = random_password.sqlpass.result
}

output "db_server_name" {
  value = azurerm_sql_server.vh-core-infra.name
}

output "keyvault_id" {
  value = azurerm_key_vault.vh-core-infra.id
}
