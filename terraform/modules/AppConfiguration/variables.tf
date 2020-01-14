variable "workspace_to_environment_map" {
  type = "map"
  default = {
    AAT     = "aat"
    Demo    = "demo"
    Dev     = "dev"
    Preview = "preview"
    Sandbox = "sandbox"
    Test1   = "test1"
    Test2   = "test2"
    Pilot   = "pilot"
    PreProd = "preprod"
    Prod    = "prod"
  }
}

variable "environment_to_sku_map" {
  type = "map"
  default = {
    AAT     = "free"
    Demo    = "free"
    Dev     = "free"
    Preview = "free"
    Sandbox = "free"
    Test1   = "free"
    Test2   = "free"
    PreProd = "free"
    Prod    = "free"
  }
}

locals {
  environment = lookup(var.workspace_to_environment_map, terraform.workspace, "preview")
  sku         = lookup(var.environment_to_sku_map, terraform.workspace, "free")
}
