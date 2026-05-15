output "app_gateway_subnet_id" { value = azurerm_subnet.app_gateway.id }
output "web_subnet_id" { value = azurerm_subnet.web.id }
output "api_subnet_id" { value = azurerm_subnet.api.id }
output "data_subnet_id" { value = azurerm_subnet.data.id }
