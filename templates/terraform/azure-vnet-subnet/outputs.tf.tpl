output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.rg.name
}

output "vnet_name" {
  description = "Name of the created virtual network."
  value       = azurerm_virtual_network.vnet.name
}

output "subnet_name" {
  description = "Name of the created subnet."
  value       = azurerm_subnet.subnet.name
}
