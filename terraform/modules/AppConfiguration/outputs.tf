output "appconfig_connection_str" {
  value = azurerm_app_configuration.vh.primary_read_key.connection_string
}

output "appconfig_connection_str_write" {
  value = azurerm_app_configuration.vh.primary_write_key.connection_string
}
