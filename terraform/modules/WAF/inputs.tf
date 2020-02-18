variable "backend_apps" {
  type = list(object({name=string, fqdn=list(string), public_fqdn=string}))
}

variable "redirects" {
  type = list(object({name=string, destination=string, app=string, fqdn=string}))
}

variable "resource_group_name" {
  type = string
}

variable "keyvault_id" {
  type = string
}

variable "la_workspace_id" {
  type = string
}
