variable "apps" {
  type = map(object({public_fqdn=string}))
}

variable "resource_group_name" {
  type = string
}

variable "resource_prefix" {
  type = string
}

