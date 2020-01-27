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

  version = {
    booking-queue-subscriber = "~2"
    scheduler-jobs = "~3"
  }

  app_settings = {
    booking-queue-subscriber = {
      "ApplicationInsights:InstrumentationKey" = var.app_insights_instrumentation_key
      "AzureAd:Authority"                      = "https://login.microsoftonline.com/"
      "AzureAd:ClientId"                       = var.idam_client_id["booking-queue-subscriber"]
      "AzureAd:ClientSecret"                   = var.idam_client_secret["booking-queue-subscriber"]
      "AzureAd:TenantId"                       = var.idam_tenant_id
      "AzureAd:VideoApiResourceId"             = var.app_url["video-api"]
      "VhServices:EnableVideoApiStub"          = "false"
      "VhServices:VideoApiUrl"                 = var.app_url["video-api"]
      AzureWebJobsDashboard                    = var.storage_connection_string
      AzureWebJobsStorage                      = var.storage_connection_string
      FUNCTIONS_EXTENSION_VERSION              = "~2"
      queueName                                = "booking"
      ServiceBusConnection                     = var.service_bus_connstr
      WEBSITE_ENABLE_SYNC_UPDATE_SITE          = true
      WEBSITE_RUN_FROM_PACKAGE                 = "1"
    }
    scheduler-jobs = {
      "ApplicationInsights:InstrumentationKey" = var.app_insights_instrumentation_key
      AzureWebJobsDashboard                    = var.storage_connection_string
      AzureWebJobsStorage                      = var.storage_connection_string
      FUNCTIONS_EXTENSION_VERSION              = "~2"
      WEBSITE_ENABLE_SYNC_UPDATE_SITE          = true
      WEBSITE_RUN_FROM_PACKAGE                 = "1"
    }
    # video-queue-subscriber = {
    #   "ApplicationInsights:InstrumentationKey" = var.app_insights_instrumentation_key
    #   "AzureAd:Authority"                      = "https://login.microsoftonline.com/"
    #   "AzureAd:ClientId"                       = var.idam_client_id["video-queue-subscriber"]
    #   "AzureAd:ClientSecret"                   = var.idam_client_secret["video-queue-subscriber"]
    #   "AzureAd:TenantId"                       = var.idam_tenant_id
    #   "VhServices:BookingsApiResourceId"       = var.app_url["bookings-api"]
    #   "VhServices:BookingsApiUrl"              = var.app_url["bookings-api"]
    #   AzureWebJobsDashboard                    = var.storage_connection_string
    #   AzureWebJobsStorage                      = var.storage_connection_string
    #   FUNCTIONS_EXTENSION_VERSION              = "~2"
    #   queueName                                = "video"
    #   ServiceBusConnection                     = var.service_bus_connstr
    #   WEBSITE_ENABLE_SYNC_UPDATE_SITE          = true
    #   WEBSITE_RUN_FROM_PACKAGE                 = "1"
    # }
  }
}
