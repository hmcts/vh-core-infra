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
      name     = "Standard_S1"
      capacity = 1
    }
    Demo = {
      name     = "Standard_S1"
      capacity = 1
    }
    Dev = {
      name     = "Free_F1"
      capacity = 1
    }
    Preview = {
      name     = "Free_F1"
      capacity = 1
    }
    Sandbox = {
      name     = "Standard_S1"
      capacity = 1
    }
    Test1 = {
      name     = "Free_F1"
      capacity = 1
    }
    Test2 = {
      name     = "Free_F1"
      capacity = 1
    }
    PreProd = {
      name     = "Standard_S1"
      capacity = 1
    }
    Prod = {
      name     = "Standard_S1"
      capacity = 1
    }
  }
}

locals {
  environment = lookup(var.workspace_to_environment_map, terraform.workspace, "preview")
  sku = lookup(var.environment_to_sku_map, terraform.workspace, {
    name     = "Standard_S1"
    capacity = 1
  })
}
