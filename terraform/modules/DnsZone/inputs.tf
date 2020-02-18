variable "cnames" {
  type = map(object({name=string, type=string, value=string}))
}

variable "a" {
  type = map(object({name=string, type=string, value=string}))
}

variable "zone_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}
