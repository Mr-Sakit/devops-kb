output "frontend_vmss_name" {
  value = module.compute.frontend_vmss_name
}

output "backend_vmss_name" {
  value = module.compute.backend_vmss_name
}

output "frontend_internal_load_balancer_private_ip" {
  value = module.load_balancer.frontend_lb_private_ip
}

output "backend_internal_load_balancer_private_ip" {
  value = module.load_balancer.backend_lb_private_ip
}

output "sql_server_name" {
  value = module.database.sql_server_name
}

output "sql_database_name" {
  value = module.database.sql_database_name
}
