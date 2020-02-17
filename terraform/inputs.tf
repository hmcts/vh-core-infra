variable "location" {
  type    = string
  default = "ukwest"
}

variable "build_agent_vnet" {
  type    = list(string)
  default = []
}

variable "idam_tenant_id" {
  type = string
}

variable "idam_client_id" {
  type = string
}

variable "idam_client_secret" {
  type = string
}

variable "dns_tenant_id" {
  type = string
}

variable "dns_client_id" {
  type = string
}

variable "dns_client_secret" {
  type = string
}

variable "dns_subscription_id" {
  type = string
}

variable "aks_tenant_id" {
  type = string
}

variable "aks_client_id" {
  type = string
}

variable "aks_client_secret" {
  type = string
}

variable "aks_subscription_id" {
  type = string
}

variable "aks_public_subnet" {
  type = string
}

variable "aks_vnet" {
  type = string
}

variable "aks_vnet_rg" {
  type = string
}

variable "dev_group" {
  type        = string
  description = "specifies group to which permissions will be assigned when deploying the dev environment"
}
