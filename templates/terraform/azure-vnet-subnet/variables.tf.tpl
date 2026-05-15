variable "prefix" {
  description = "Name prefix for Azure resources."
  type        = string
  default     = "__PREFIX__"
}

variable "location" {
  description = "Azure region where resources will be created."
  type        = string
  default     = "__LOCATION__"
}

variable "vnet_address_space" {
  description = "CIDR block for the virtual network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "CIDR block for the subnet."
  type        = string
  default     = "10.0.1.0/24"
}
