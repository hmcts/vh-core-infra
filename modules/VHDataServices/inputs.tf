variable "resource_group_name" {
  type = "string"
}

variable "resource_prefix" {
  type = "string"
}

variable "delegated_networks" {
  type = "map"
}

variable "databases" {
  type = "map"
}

variable "queues" {
  type = "map"
}
