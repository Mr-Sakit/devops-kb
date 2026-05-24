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

variable "admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key used to access the Linux VM."
  type        = string
  default     = "__SSH_PUBLIC_KEY__"

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)[[:space:]]+[^[:space:]]+", var.ssh_public_key))
    error_message = "ssh_public_key must be a complete SSH public key, for example: ssh-ed25519 AAAA... user@host. Do not enter a password or a short word."
  }
}

variable "ssh_source_address_prefix" {
  description = "Source IP/CIDR allowed to SSH into the VM."
  type        = string
  default     = "*"
}

variable "ssh_private_key_path" {
  description = "Local private key path used only to print a convenient SSH command."
  type        = string
  default     = "__SSH_PRIVATE_KEY_PATH__"
}

variable "vm_size" {
  description = "Azure VM size."
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
