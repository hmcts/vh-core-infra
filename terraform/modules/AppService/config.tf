locals {
  common_tags = {
    "managedBy"          = "Reform Visual Hearings"
    "solutionOwner"      = ""
    "activityName"       = "VH"
    "dataClassification" = "Internal"
    "automation"         = "terraform"
    "costCentre"         = "10245117" // until we get a better one, this is the generic cft contingency one
    "environment"        = lookup(var.workspace_to_environment_map, terraform.workspace, "preview")
    "criticality"        = "Medium"
  }

  live_envs = {
    prod = true
  }

  Kinly_Api_Url = {
    prod    = "https://hearings.hmcts.net/virtual-court/api/v1"
    preprod = "https://preprod.hearings.hmcts.net/virtual-court/api/v1"
    dev     = "https://dev.hearings.hmcts.net/virtual-court/api/v1"
    aat     = "https://preprod.hearings.hmcts.net/virtual-court/api/v1"
    demo    = "https://preprod.hearings.hmcts.net/virtual-court/api/v1"
    preview = "https://preprod.hearings.hmcts.net/virtual-court/api/v1"
    sandbox = "https://preprod.hearings.hmcts.net/virtual-court/api/v1"
    test1   = "https://preprod.hearings.hmcts.net/virtual-court/api/v1"
    test2   = "https://preprod.hearings.hmcts.net/virtual-court/api/v1"
    pilot   = "https://preprod.hearings.hmcts.net/virtual-court/api/v1"
  }

  kinly_selftest_url = {
    prod    = "https://self-test.hearings.hmcts.net/api/v1/testcall"
    preprod = "https://preprod.self-test.hearings.hmcts.net/api/v1/testcall"
    dev     = "https://dev.self-test.hearings.hmcts.net/api/v1/testcall"
    aat     = "https://preprod.self-test.hearings.hmcts.net/api/v1/testcall"
    demo    = "https://preprod.self-test.hearings.hmcts.net/api/v1/testcall"
    preview = "https://preprod.self-test.hearings.hmcts.net/api/v1/testcall"
    sandbox = "https://preprod.self-test.hearings.hmcts.net/api/v1/testcall"
    test1   = "https://preprod.self-test.hearings.hmcts.net/api/v1/testcall"
    test2   = "https://preprod.self-test.hearings.hmcts.net/api/v1/testcall"
    pilot   = "https://preprod.self-test.hearings.hmcts.net/api/v1/testcall"
  }

  kinly_selftest_uri = {
    prod    = "sip.self-test.hearings.hmcts.net"
    preprod = "sip.preprod.self-test.hearings.hmcts.net"
    dev     = "sip.dev.self-test.hearings.hmcts.net"
    aat     = "sip.preprod.self-test.hearings.hmcts.net"
    demo    = "sip.preprod.self-test.hearings.hmcts.net"
    preview = "sip.preprod.self-test.hearings.hmcts.net"
    sandbox = "sip.preprod.self-test.hearings.hmcts.net"
    test1   = "sip.preprod.self-test.hearings.hmcts.net"
    test2   = "sip.preprod.self-test.hearings.hmcts.net"
    pilot   = "sip.preprod.self-test.hearings.hmcts.net"
  }

  app_settings = {
    admin-web = {
      APPINSIGHTS_INSTRUMENTATIONKEY                  = var.app_insights_instrumentation_key
      "ApplicationInsights:InstrumentationKey"        = var.app_insights_instrumentation_key
      APPINSIGHTS_PROFILERFEATURE_VERSION             = "1.0.0"
      APPINSIGHTS_SNAPSHOTFEATURE_VERSION             = "1.0.0"
      ApplicationInsightsAgent_EXTENSION_VERSION      = "~2"
      "AzureAd:Authority"                             = "https://login.microsoftonline.com/${var.idam_tenant_id}"
      "AzureAd:ClientId"                              = var.idam_client_id["admin-web"]
      "AzureAd:ClientSecret"                          = var.idam_client_secret["admin-web"]
      "AzureAd:TenantId"                              = var.idam_tenant_id
      "AzureAd:PostLogoutRedirectUri"                 = var.app_url["admin-web"]
      "AzureAd:RedirectUri"                           = "${var.app_url["admin-web"]}/login"
      DiagnosticServices_EXTENSION_VERSION            = "~3"
      InstrumentationEngine_EXTENSION_VERSION         = false
      IsLive                                          = lookup(local.live_envs, local.common_tags.environment, false)
      MSDEPLOY_RENAME_LOCKED_FILES                    = "1"
      SnapshotDebugger_EXTENSION_VERSION              = "disabled"
      "VhServices:BookingsApiResourceId"              = var.app_url["bookings-api"]
      "VhServices:BookingsApiUrl"                     = var.app_url["bookings-api"]
      "VhServices:UserApiResourceId"                  = var.app_url["user-api"]
      "VhServices:UserApiUrl"                         = var.app_url["user-api"]
      WEBSITE_NODE_DEFAULT_VERSION                    = "6.9.1"
      XDT_MicrosoftApplicationInsights_BaseExtensions = "disabled"
      XDT_MicrosoftApplicationInsights_Mode           = "recommended"
    }
    bookings-api = {
      APPINSIGHTS_INSTRUMENTATIONKEY           = var.app_insights_instrumentation_key
      "ApplicationInsights:InstrumentationKey" = var.app_insights_instrumentation_key
      "AzureAd:TenantId"                       = var.idam_tenant_id
      "AzureAd:VhBookingsApiResourceId"        = var.app_url["bookings-api"]
      MSDEPLOY_RENAME_LOCKED_FILES             = "1"
      "ServiceBusQueue:ConnectionString"       = var.service_bus_connstr
      UseServiceBusFake                        = false
      "UseServiceBusFake:false"                = false
      ServiceBusConnection                     = var.service_bus_connstr
      WEBSITE_NODE_DEFAULT_VERSION             = "6.9.1"
    }
    service-web = {
      APPINSIGHTS_INSTRUMENTATIONKEY             = var.app_insights_instrumentation_key
      "ApplicationInsights:InstrumentationKey"   = var.app_insights_instrumentation_key
      AppInsightsKey                             = var.app_insights_instrumentation_key
      "Authority"                                = "https://login.microsoftonline.com/${var.idam_tenant_id}"
      "AzureAd:Authority"                        = "https://login.microsoftonline.com/${var.idam_tenant_id}"
      "AzureAd:ClientId"                         = var.idam_client_id["service-web"]
      "AzureAd:ClientSecret"                     = var.idam_client_secret["service-web"]
      "AzureAd:TenantId"                         = var.idam_tenant_id
      "AzureAd:PostLogoutRedirectUri"            = var.app_url["service-web"]
      "AzureAd:RedirectUri"                      = "${var.app_url["service-web"]}/login"
      "AzureAd:VhServiceResourceId"              = var.app_url["service-web"]
      "AzureStorage:BaseVideoUrl"                = "https://vhcoreinfra${local.common_tags.environment}.blob.core.windows.net/video"
      ClientId                                   = var.idam_client_id["service-web"]
      ClientSecret                               = var.idam_client_secret["service-web"]
      "CustomToken:Secret"                       = ""
      HearingsApiUrl                             = ""
      IsLive                                     = lookup(local.live_envs, local.common_tags.environment, false)
      MSDEPLOY_RENAME_LOCKED_FILES               = "1"
      TenantId                                   = var.idam_tenant_id
      "VhServices:BookingsApiResourceId"         = var.app_url["bookings-api"]
      "VhServices:BookingsApiUrl"                = var.app_url["bookings-api"]
      "VhServices:KinlySelfTestScoreEndpointUrl" = lookup(local.kinly_selftest_url, local.common_tags.environment, "")
      "VhServices:PexipSelfTestNodeUri"          = lookup(local.kinly_selftest_uri, local.common_tags.environment, "")
      "VhServices:UserApiResourceId"             = var.app_url["user-api"]
      "VhServices:UserApiUrl"                    = var.app_url["user-api"]
      VideoAppUrl                                = var.app_url["video-web"]
      WEBSITE_NODE_DEFAULT_VERSION               = "6.9.1"
    }
    user-api = {
      APPINSIGHTS_INSTRUMENTATIONKEY           = var.app_insights_instrumentation_key
      "ApplicationInsights:InstrumentationKey" = var.app_insights_instrumentation_key
      "AzureAd:ClientId"                       = var.idam_client_id["user-api"]
      "AzureAd:ClientSecret"                   = var.idam_client_secret["user-api"]
      "AzureAd:TenantId"                       = var.idam_tenant_id
      "AzureAd:VhUserApiResourceId"            = var.app_url["user-api"]
      DefaultPassword                          = "Password123!"
      MSDEPLOY_RENAME_LOCKED_FILES             = "1"
      WEBSITE_NODE_DEFAULT_VERSION             = "6.9.1"
    }
    video-api = {
      APPINSIGHTS_INSTRUMENTATIONKEY           = var.app_insights_instrumentation_key
      "ApplicationInsights:InstrumentationKey" = var.app_insights_instrumentation_key
      "AzureAd:ClientId"                       = var.idam_client_id["video-api"]
      "AzureAd:ClientSecret"                   = var.idam_client_secret["video-api"]
      "AzureAd:TenantId"                       = var.idam_tenant_id
      "AzureAd:VhVideoApiResourceId"           = var.app_url["video-api"]
      "AzureAd:VhVideoWebClientId"             = var.idam_client_id["video-web"]
      "CustomToken:Secret"                     = ""
      "CustomToken:ThirdPartySecret"           = ""
      MSDEPLOY_RENAME_LOCKED_FILES             = "1"
      "ServiceBusQueue:ConnectionString"       = var.service_bus_connstr
      "Services:CallbackUri"                   = "${var.app_url["video-api"]}/callback"
      "Services:KinlyApiUrl"                   = lookup(local.Kinly_Api_Url, local.common_tags.environment, "")
      "Services:KinlySelfTestApiUrl"           = lookup(local.kinly_selftest_url, local.common_tags.environment, "")
      "Services:PexipSelfTestNode"             = lookup(local.kinly_selftest_uri, local.common_tags.environment, "")
      "Services:UserApiResourceId"             = var.app_url["user-api"]
      "Services:UserApiUrl"                    = var.app_url["user-api"]
      VideoAppUrl                              = var.app_url["video-web"]
      WEBSITE_NODE_DEFAULT_VERSION             = "6.9.1"
    }
    video-web = {
      APPINSIGHTS_INSTRUMENTATIONKEY           = var.app_insights_instrumentation_key
      "ApplicationInsights:InstrumentationKey" = var.app_insights_instrumentation_key
      "AzureAd:ClientId"                       = var.idam_client_id["video-web"]
      "AzureAd:ClientSecret"                   = var.idam_client_secret["video-web"]
      "AzureAd:TenantId"                       = var.idam_tenant_id
      "AzureAd:PostLogoutRedirectUri"          = var.app_url["video-web"]
      "AzureAd:RedirectUri"                    = "${var.app_url["video-web"]}/login"
      "AzureAd:VhVideoWebResourceId"           = var.app_url["video-web"]
      "CustomToken:Secret"                     = ""
      "CustomToken:ThirdPartySecret"           = ""
      MSDEPLOY_RENAME_LOCKED_FILES             = "1"
      "VhServices:BookingsApiResourceId"       = var.app_url["bookings-api"]
      "VhServices:BookingsApiUrl"              = var.app_url["bookings-api"]
      "VhServices:UserApiResourceId"           = var.app_url["user-api"]
      "VhServices:UserApiUrl"                  = var.app_url["user-api"]
      "VhServices:VideoApiResourceId"          = var.app_url["video-api"]
      "VhServices:VideoApiUrl"                 = var.app_url["video-api"]
      WEBSITE_NODE_DEFAULT_VERSION             = "6.9.1"
    }
  }

  connection_string = {
    admin-web = {}
    bookings-api = {
      "VhBookings" = {
        type  = "SQLAzure"
        value = "Server=tcp:${var.db_server_name}.database.windows.net,1433;Initial Catalog=vhbookings;Persist Security Info=False;User ID=hvhearingsapiadmin;Password=${var.db_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
      }
    }
    service-web = {}
    user-api    = {}
    video-api = {
      "VhVideoApi" = {
        type  = "SQLAzure"
        value = "Server=tcp:${var.db_server_name}.database.windows.net,1433;Initial Catalog=vhvideo;Persist Security Info=False;User ID=hvhearingsapiadmin;Password=${var.db_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
      }
    }
    video-web = {}
  }
}

