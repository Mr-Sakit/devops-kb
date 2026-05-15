variable "prefix" {
  description = "Name prefix for generated resources."
  type        = string
  default     = "__PREFIX__"
}

variable "environment" {
  description = "Environment name used in tags and resource names."
  type        = string
  default     = "dev"
}

variable "resource_group_name" {
  description = "Existing Azure resource group name."
  type        = string
  default     = "__PREFIX__-rg"
}

variable "vnet_name" {
  description = "Existing Azure virtual network name."
  type        = string
  default     = "__PREFIX__-vnet"
}

variable "admin_username" {
  description = "Admin username for Linux VM scale sets."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key used for VMSS instances."
  type        = string
}

variable "vm_size" {
  description = "Azure VM size for frontend and backend VM scale sets."
  type        = string
  default     = "__VM_SIZE__"
}

variable "image_publisher" {
  description = "Azure Marketplace image publisher."
  type        = string
  default     = "__IMAGE_PUBLISHER__"
}

variable "image_offer" {
  description = "Azure Marketplace image offer."
  type        = string
  default     = "__IMAGE_OFFER__"
}

variable "image_sku" {
  description = "Azure Marketplace image SKU."
  type        = string
  default     = "__IMAGE_SKU__"
}

variable "image_version" {
  description = "Azure Marketplace image version."
  type        = string
  default     = "latest"
}

variable "sql_admin_login" {
  description = "Azure SQL administrator username."
  type        = string
  default     = "sqladminuser"
}

variable "sql_admin_password" {
  description = "Azure SQL administrator password."
  type        = string
  sensitive   = true
}

variable "frontend_load_balancer_private_ip" {
  description = "Static private IP for the frontend internal load balancer."
  type        = string
  default     = "10.0.12.10"
}

variable "backend_load_balancer_private_ip" {
  description = "Static private IP for the backend internal load balancer."
  type        = string
  default     = "10.0.13.10"
}
