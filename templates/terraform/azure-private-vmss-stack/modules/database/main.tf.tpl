resource "azurerm_mssql_server" "main" {
  name                          = "sql-${var.name_prefix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"
  tags                          = var.tags
}

resource "azurerm_mssql_database" "main" {
  name           = "sqldb-${var.name_prefix}"
  server_id      = azurerm_mssql_server.main.id
  sku_name       = "S0"
  max_size_gb    = 10
  zone_redundant = false
  tags           = var.tags

  short_term_retention_policy {
    retention_days           = 14
    backup_interval_in_hours = 12
  }
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-${var.name_prefix}-sql"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name_prefix}-sql"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}
