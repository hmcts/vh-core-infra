locals {
  localhostreply = ["https://localhost", "https://localhost/login", "https://localhost/home"]
  prodreply = {
    "admin-web"   = ["https://admin.hearings.reform.hmcts.net", "https://admin.hearings.reform.hmcts.net/login", "https://admin.hearings.reform.hmcts.net/home"],
    "service-web" = ["https://service.hearings.reform.hmcts.net", "https://service.hearings.reform.hmcts.net/login", "https://service.hearings.reform.hmcts.net/home"],
    "video-web"   = ["https://video.hearings.reform.hmcts.net", "https://video.hearings.reform.hmcts.net/login", "https://video.hearings.reform.hmcts.net/home"]
  }
}

resource "azuread_application" "vh" {
  for_each = var.apps

  name            = each.value.name
  homepage        = each.value.url
  identifier_uris = [each.value.url]
  reply_urls = terraform.workspace == "Dev" ? concat(
    local.localhostreply,
    [
      each.value.url,
      "${each.value.url}/login",
      "${each.value.url}/home",
      "https://${each.value.name}-staging.${each.value.audience == "backend" ? "azurewebsites.net" : "hearings.reform.hmcts.net"}",
      "https://${each.value.name}-staging.${each.value.audience == "backend" ? "azurewebsites.net" : "hearings.reform.hmcts.net"}/login",
      "https://${each.value.name}-staging.${each.value.audience == "backend" ? "azurewebsites.net" : "hearings.reform.hmcts.net"}/home"
    ]
    ) : terraform.workspace == "Prod" ? concat(
    lookup(local.prodreply, each.key, []),
    [
      each.value.url,
      "${each.value.url}/login",
      "${each.value.url}/home",
      "https://${each.value.name}-staging.${each.value.audience == "backend" ? "azurewebsites.net" : "hearings.reform.hmcts.net"}",
      "https://${each.value.name}-staging.${each.value.audience == "backend" ? "azurewebsites.net" : "hearings.reform.hmcts.net"}/login",
      "https://${each.value.name}-staging.${each.value.audience == "backend" ? "azurewebsites.net" : "hearings.reform.hmcts.net"}/home"
    ]) : [
    each.value.url,
    "${each.value.url}/login",
    "${each.value.url}/home",
    "https://${each.value.name}-staging.${each.value.audience == "backend" ? "azurewebsites.net" : "hearings.reform.hmcts.net"}",
    "https://${each.value.name}-staging.${each.value.audience == "backend" ? "azurewebsites.net" : "hearings.reform.hmcts.net"}/login",
    "https://${each.value.name}-staging.${each.value.audience == "backend" ? "azurewebsites.net" : "hearings.reform.hmcts.net"}/home"
  ]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = lookup(local.oauth2_allow_implicit_flow, each.key, false)
  type                       = "webapp/api"
  public_client              = false
  group_membership_claims    = "None"

  dynamic "required_resource_access" {
    for_each = lookup(local.app_permissions, each.key, {})

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
  dynamic "app_role" {
    for_each = local.app_roles[each.key]

    content {
      allowed_member_types  = app_role.value.allowed_member_types
      description           = app_role.value.description
      display_name          = app_role.value.display_name
      is_enabled            = app_role.value.is_enabled
      value                 = app_role.value.value
    }
  }
}

# resource "azuread_application_app_role" "appRoles" {
#   for_each = {
#     # for app, roles in local.app_roles: {
#     #     for role in roles : {
#     #       "${app}-${role.value}" = {appname=app}
#     #     }
#     # } 

#     for app, roles in local.app_roles : 
#       for role in roles : {
#         appName   = app
#         role = role
#       }
    
#   }

#   application_object_id = azuread_application.vh[each.value.appname].object_id
#   allowed_member_types  = each.value.allowed_member_types
#   description           = each.value.description
#   display_name          = each.value.display_name
#   is_enabled            = each.value.is_enabled
#   value                 = each.value.value
# }

resource "random_password" "password" {
  for_each = var.apps

  length  = 32
  special = true
}

resource "azuread_application_password" "vh" {
  for_each = var.apps

  key_id                = uuidv5("url", each.value.url)
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
