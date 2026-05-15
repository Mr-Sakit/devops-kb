resource "azurerm_subnet" "app_gateway" {
  name                 = "snet-${var.name_prefix}-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.0.11.0/24"]
}

resource "azurerm_subnet" "web" {
  name                 = "snet-${var.name_prefix}-web"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.0.12.0/24"]
}

resource "azurerm_subnet" "api" {
  name                 = "snet-${var.name_prefix}-api"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.0.13.0/24"]
}

resource "azurerm_subnet" "data" {
  name                              = "snet-${var.name_prefix}-data"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = var.vnet_name
  address_prefixes                  = ["10.0.14.0/24"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_nat_gateway" "compute" {
  name                    = "nat-${var.name_prefix}-compute"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_public_ip" "nat" {
  name                = "pip-${var.name_prefix}-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "compute" {
  nat_gateway_id       = azurerm_nat_gateway.compute.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg-${var.name_prefix}-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP-From-AppGateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.11.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-Ops"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.5.0/24"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "api" {
  name                = "nsg-${var.name_prefix}-api"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-API-From-Web"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.0.12.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-Ops"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.5.0/24"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_nat_gateway_association" "web" {
  subnet_id      = azurerm_subnet.web.id
  nat_gateway_id = azurerm_nat_gateway.compute.id
}

resource "azurerm_subnet_nat_gateway_association" "api" {
  subnet_id      = azurerm_subnet.api.id
  nat_gateway_id = azurerm_nat_gateway.compute.id
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "api" {
  subnet_id                 = azurerm_subnet.api.id
  network_security_group_id = azurerm_network_security_group.api.id
}
