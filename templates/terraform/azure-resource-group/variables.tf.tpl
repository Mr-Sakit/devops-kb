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
