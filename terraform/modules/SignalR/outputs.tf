output "signalr_connection_str" {
  value = azurerm_signalr_service.vh.primary_connection_string
}
