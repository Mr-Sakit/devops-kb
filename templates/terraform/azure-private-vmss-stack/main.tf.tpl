locals {
  name_prefix = "${var.prefix}-${var.environment}"
  tags = {
    project     = var.prefix
    environment = var.environment
    managed_by  = "terraform"
  }
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.main.name
}

module "network" {
  source              = "./modules/network"
  name_prefix         = local.name_prefix
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  vnet_name           = data.azurerm_virtual_network.main.name
  tags                = local.tags
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  name_prefix         = local.name_prefix
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  web_subnet_id       = module.network.web_subnet_id
  api_subnet_id       = module.network.api_subnet_id
  frontend_private_ip = var.frontend_load_balancer_private_ip
  backend_private_ip  = var.backend_load_balancer_private_ip
  tags                = local.tags
}

module "compute" {
  source                      = "./modules/compute"
  name_prefix                 = local.name_prefix
  location                    = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  frontend_subnet_id          = module.network.web_subnet_id
  backend_subnet_id           = module.network.api_subnet_id
  frontend_lb_backend_pool_id = module.load_balancer.frontend_backend_pool_id
  backend_lb_backend_pool_id  = module.load_balancer.backend_backend_pool_id
  admin_username              = var.admin_username
  ssh_public_key              = var.ssh_public_key
  vm_size                     = var.vm_size
  image_publisher             = var.image_publisher
  image_offer                 = var.image_offer
  image_sku                   = var.image_sku
  image_version               = var.image_version
  tags                        = local.tags
}

module "database" {
  source              = "./modules/database"
  name_prefix         = local.name_prefix
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = module.network.data_subnet_id
  sql_admin_login     = var.sql_admin_login
  sql_admin_password  = var.sql_admin_password
  tags                = local.tags
}
