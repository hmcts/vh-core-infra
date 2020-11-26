variable "workspace_to_environment_map" {
  type = map(any)
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
