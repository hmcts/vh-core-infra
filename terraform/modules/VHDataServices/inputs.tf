variable "resource_group_name" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "delegated_networks" {
  type = map(any)
}

variable "public_env" {
  type = number
  default = 0
}

variable "databases" {
  type = map(object({collation=string, edition=string, performance_level=string}))
}

variable "queues" {
  type = map(object({collation=string, edition=string, performance_level=string}))
}
