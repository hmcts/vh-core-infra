variable "apps" {
  type = "map"
}

variable "managed_accounts" {
  type = "map"
}

variable "resource_group_name" {
  type = "string"
}

variable "resource_prefix" {
  type = "string"
}

variable "scaling_notification_email" {
  type    = "list"
  default = []
}

variable "app_insights_instrumentation_key" {
  type = "string"
}

variable "storage_connection_string" {
  type = "string"
}

variable "signalr_connection_str" {
  type = "string"
}

variable "idam_client_id" {
  type = "map"
}

variable "idam_client_secret" {
  type = "map"
}

variable "idam_tenant_id" {
  type = "string"
}

variable "app_url" {
  type = "map"
}

variable "service_bus_connstr" {
  type = "string"
}

variable "db_server_name" {
  type = "string"
}

variable "db_admin_password" {
  type = "string"
}
