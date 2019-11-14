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

locals {
  environment   = lookup(var.workspace_to_environment_map, terraform.workspace, "preview")
  suffix        = "-${local.environment}"
  common_prefix = "core-infra"
  std_prefix    = "vh-${local.common_prefix}"

  web_apps = [
    {
      name        = "vh-admin-web${local.suffix}",
      fqdn        = ["vh-admin-web${local.suffix}.azurewebsites.net"],
      public_fqdn = "vh-admin-web${local.suffix}.hearings.reform.hmcts.net"
    },
    {
      name        = "vh-service-web${local.suffix}",
      fqdn        = ["vh-service-web${local.suffix}.azurewebsites.net"],
      public_fqdn = "vh-service-web${local.suffix}.hearings.reform.hmcts.net"
    },
    {
      name        = "vh-video-web${local.suffix}",
      fqdn        = ["vh-video-web${local.suffix}.azurewebsites.net"],
      public_fqdn = "vh-video-web${local.suffix}.hearings.reform.hmcts.net"
    }
  ]

  prod_cnames = [
    {
      name        = "video",
      destination = "vh-video-web${local.suffix}.hearings.reform.hmcts.net"
      app         = "vh-video-web${local.suffix}"
      fqdn        = "video.hearings.reform.hmcts.net"
    },
    {
      name        = "admin",
      destination = "vh-admin-web${local.suffix}.hearings.reform.hmcts.net"
      app         = "vh-admin-web${local.suffix}"
      fqdn        = "admin.hearings.reform.hmcts.net"
    },
    {
      name        = "service",
      destination = "vh-service-web${local.suffix}.hearings.reform.hmcts.net"
      app         = "vh-service-web${local.suffix}"
      fqdn        = "service.hearings.reform.hmcts.net"
    }
  ]

  test_endpoints = {
    admin-web-public = {
      public_fqdn = "vh-admin-web${local.suffix}.hearings.reform.hmcts.net"
    }
    service-web-public = {
      public_fqdn = "vh-service-web${local.suffix}.hearings.reform.hmcts.net"
    }
    video-web-public = {
      public_fqdn = "vh-video-web${local.suffix}.hearings.reform.hmcts.net"
    }
    admin-web = {
      public_fqdn = "vh-admin-web${local.suffix}.azurewebsites.net"
    }
    service-web = {
      public_fqdn = "vh-service-web${local.suffix}.azurewebsites.net"
    }
    video-web = {
      public_fqdn = "vh-video-web${local.suffix}.azurewebsites.net"
    }
    bookings-api = {
      public_fqdn = "vh-bookings-api${local.suffix}.azurewebsites.net"
    }
    user-api = {
      public_fqdn = "vh-user-api${local.suffix}.azurewebsites.net"
    }
    video-api = {
      public_fqdn = "vh-video-api${local.suffix}.azurewebsites.net"
    }
  }

  app_definitions = {
    admin-web = {
      name            = "vh-admin-web${local.suffix}"
      websockets      = false
      ip_restriction  = []
      subnet          = "backend"
      audience_subnet = "frontend"
      url             = "https://vh-admin-web${local.suffix}.hearings.reform.hmcts.net"
    }
    service-web = {
      name            = "vh-service-web${local.suffix}"
      websockets      = false
      ip_restriction  = []
      subnet          = "backend"
      audience_subnet = "frontend"
      url             = "https://vh-service-web${local.suffix}.hearings.reform.hmcts.net"
    }
    video-web = {
      name            = "vh-video-web${local.suffix}"
      websockets      = true
      ip_restriction  = []
      subnet          = "backend"
      audience_subnet = "frontend"
      url             = "https://vh-video-web${local.suffix}.hearings.reform.hmcts.net"
    }
    bookings-api = {
      name            = "vh-bookings-api${local.suffix}"
      websockets      = false
      ip_restriction  = var.build_agent_vnet
      subnet          = "backend"
      audience_subnet = "backend"
      url             = "https://vh-bookings-api${local.suffix}.azurewebsites.net"
    }
    user-api = {
      name            = "vh-user-api${local.suffix}"
      websockets      = false
      ip_restriction  = var.build_agent_vnet
      subnet          = "backend"
      audience_subnet = "backend"
      url             = "https://vh-user-api${local.suffix}.azurewebsites.net"
    }
    video-api = {
      name            = "vh-video-api${local.suffix}"
      websockets      = false
      ip_restriction  = var.build_agent_vnet
      subnet          = "backend"
      audience_subnet = "backend"
      url             = "https://vh-video-api${local.suffix}.azurewebsites.net"
    }
  }

  funcapp_definitions = {
    booking-queue-subscriber = {
      name   = "vh-booking-queue-subscriber${local.suffix}"
      subnet = "backend"
      url    = "https://vh-booking-queue-subscriber${local.suffix}.azurewebsites.net"
    }
  }

  app_registrations = merge(
    {
      for def in keys(local.app_definitions) :
      def => {
        name = local.app_definitions[def].name
        url  = local.app_definitions[def].url
      }
    },
    {
      for def in keys(local.funcapp_definitions) :
      def => {
        name = local.funcapp_definitions[def].name
        url  = local.funcapp_definitions[def].url
      }
    }
  )
}
