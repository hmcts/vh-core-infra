locals {
  localhostreply = ["https://localhost", "https://localhost/login", "https://localhost/home"]
}

resource "azuread_application" "vh" {
  for_each = var.apps

  name                       = each.value.name
  homepage                   = each.value.url
  identifier_uris            = [each.value.url]
  reply_urls                 = terraform.workspace == "Dev" ? concat(local.localhostreply, [each.value.url, "${each.value.url}/login", "${each.value.url}/home"]) : [each.value.url, "${each.value.url}/login", "${each.value.url}/home"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
  type                       = "webapp/api"
  public_client              = false
  group_membership_claims    = "None"

  dynamic "required_resource_access" {
    for_each = lookup(local.app_permissions, each.key, "")

    content {
      resource_app_id = required_resource_access.value.id

      dynamic "resource_access" {
        for_each = required_resource_access.value.access

        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }
}

resource "random_password" "password" {
  for_each = var.apps

  length  = 32
  special = true
}

resource "azuread_application_password" "vh" {
  for_each = var.apps

  key_id                = uuidv5("url",each.value.url)
  application_object_id = azuread_application.vh[each.key].object_id
  value                 = random_password.password[each.key].result
  end_date_relative     = "8760h"
}

output "app_registrations" {
  value = azuread_application.vh
}

output "app_passwords" {
  value = azuread_application_password.vh
}
