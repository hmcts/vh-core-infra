variable "resource_group_name" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "apps" {
  type = map(any)
}

variable "secrets" {
  type = map(string)
}

variable "delegated_networks" {
  type = map(string)
}