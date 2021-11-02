variable "workspace_to_environment_map" {
  type = map
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
  type = map
  default = {
    AAT = {
      tier = "Standard"
      size = "S2"
    }
    Demo = {
      tier = "PremiumV2"
      size = "P1v2"
    }
    Dev = {
      tier = "Standard"
      size = "S2"
    }
    Preview = {
      tier = "Standard"
      size = "S2"
    }
    Sandbox = {
      tier = "Standard"
      size = "S2"
    }
    Test1 = {
      tier = "Standard"
      size = "S2"
    }
    Test2 = {
      tier = "Standard"
      size = "S2"
    }
    PreProd = {
      tier = "PremiumV2"
      size = "P1v2"
    }
    Prod = {
      tier = "PremiumV2"
      size = "P1v2"
    }
  }
}

locals {
  sku = lookup(var.environment_to_sku_map, terraform.workspace, {
    tier = "PremiumV2"
    size = "P1v2"
  })
}
