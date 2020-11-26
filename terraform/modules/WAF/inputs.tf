variable "backend_apps" {
  type = list(any)
}

variable "redirects" {
  type = list(any)
}

variable "resource_group_name" {
  type = string
}

variable "keyvault_id" {
  type = string
}

variable "storage_account_id" {
  type = string
}
