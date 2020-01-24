variable "location" {
  type    = "string"
  default = "ukwest"
}

variable "build_agent_vnet" {
  type    = list(string)
  default = []
}

variable "idam_tenant_id" {
  type    = "string"
  default = ""
}

variable "idam_client_id" {
  type    = "string"
  default = ""
}

variable "idam_client_secret" {
  type    = "string"
  default = ""
}

variable "dns_tenant_id" {
  type    = "string"
  default = ""
}

variable "dns_client_id" {
  type    = "string"
  default = ""
}

variable "dns_client_secret" {
  type    = "string"
  default = ""
}

variable "dns_subscription_id" {
  type    = "string"
  default = ""
}

variable "dev_group" {
  type = string
  description = "specifies group to which permissions will be assigned when deploying the dev environment"
}
