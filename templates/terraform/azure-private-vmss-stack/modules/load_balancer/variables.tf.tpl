variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "web_subnet_id" { type = string }
variable "api_subnet_id" { type = string }
variable "frontend_private_ip" { type = string }
variable "backend_private_ip" { type = string }
variable "tags" { type = map(string) }
