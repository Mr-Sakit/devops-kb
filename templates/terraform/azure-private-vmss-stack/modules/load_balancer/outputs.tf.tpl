output "frontend_lb_name" { value = azurerm_lb.frontend.name }
output "backend_lb_name" { value = azurerm_lb.backend.name }
output "frontend_lb_private_ip" { value = var.frontend_private_ip }
output "backend_lb_private_ip" { value = var.backend_private_ip }
output "frontend_backend_pool_id" { value = azurerm_lb_backend_address_pool.frontend.id }
output "backend_backend_pool_id" { value = azurerm_lb_backend_address_pool.backend.id }
