data "azurerm_resource_group" "vh-core-infra" {
  name = var.resource_group_name
}

resource "azurerm_application_insights" "vh-core-infra" {
  name     = var.resource_prefix
  location = "westeurope"
  # location            = data.azurerm_resource_group.vh-core-infra.location
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  application_type    = "web"
}

resource "azurerm_application_insights_web_test" "test" {
  for_each = var.apps

  name                    = "${each.key}-webtest"
  location                = azurerm_application_insights.vh-core-infra.location
  resource_group_name     = data.azurerm_resource_group.vh-core-infra.name
  application_insights_id = replace(azurerm_application_insights.vh-core-infra.id, "Microsoft.Insights", "microsoft.insights")
  kind                    = "ping"
  frequency               = 300
  timeout                 = 10
  enabled                 = true
  retry_enabled           = true
  geo_locations           = ["emea-ru-msa-edge", "emea-se-sto-edge"]

  configuration = <<XML
<WebTest Name="WebTest1" Id="ABD48585-0831-40CB-9069-682EA6BB3583" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="0" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
  <Items>
    <Request Method="GET" Guid="a5f10126-e4cd-570d-961c-cea43999a200" Version="1.1" Url="https://${each.value.public_fqdn}/HealthCheck/health" ThinkTime="0" Timeout="1T0" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML
}

resource "azurerm_log_analytics_workspace" "loganalytics" {
  name                = var.resource_prefix
  location            = azurerm_application_insights.vh-core-infra.location
  resource_group_name = data.azurerm_resource_group.vh-core-infra.name
  sku                 = "Free"
}

output "instrumentation_key" {
  value = azurerm_application_insights.vh-core-infra.instrumentation_key
}

output "la_workspace_id" {
  value = azurerm_log_analytics_workspace.loganalytics.workspace_id
}
