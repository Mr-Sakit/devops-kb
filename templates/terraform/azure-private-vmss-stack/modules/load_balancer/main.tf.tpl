resource "azurerm_lb" "frontend" {
  name                = "ilb-${var.name_prefix}-frontend"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                          = "frontend-private"
    subnet_id                     = var.web_subnet_id
    private_ip_address            = var.frontend_private_ip
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "frontend" {
  name            = "frontend-vmss-pool"
  loadbalancer_id = azurerm_lb.frontend.id
}

resource "azurerm_lb_probe" "frontend" {
  name            = "frontend-health"
  loadbalancer_id = azurerm_lb.frontend.id
  protocol        = "Http"
  port            = 80
  request_path    = "/health"
}

resource "azurerm_lb_rule" "frontend" {
  name                           = "frontend-http"
  loadbalancer_id                = azurerm_lb.frontend.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-private"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.frontend.id]
  probe_id                       = azurerm_lb_probe.frontend.id
}

resource "azurerm_lb" "backend" {
  name                = "ilb-${var.name_prefix}-backend"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                          = "backend-private"
    subnet_id                     = var.api_subnet_id
    private_ip_address            = var.backend_private_ip
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "backend" {
  name            = "backend-vmss-pool"
  loadbalancer_id = azurerm_lb.backend.id
}

resource "azurerm_lb_probe" "backend" {
  name            = "backend-health"
  loadbalancer_id = azurerm_lb.backend.id
  protocol        = "Http"
  port            = 8080
  request_path    = "/api/health"
}

resource "azurerm_lb_rule" "backend" {
  name                           = "backend-http"
  loadbalancer_id                = azurerm_lb.backend.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "backend-private"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend.id]
  probe_id                       = azurerm_lb_probe.backend.id
}
