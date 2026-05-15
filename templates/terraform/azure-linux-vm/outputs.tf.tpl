output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.rg.name
}

output "vm_name" {
  description = "Name of the created Linux VM."
  value       = azurerm_linux_virtual_machine.vm.name
}

output "public_ip_address" {
  description = "Public IP address of the Linux VM."
  value       = azurerm_public_ip.public_ip.ip_address
}

output "ssh_command" {
  description = "SSH command for the Linux VM."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.public_ip.ip_address}"
}
