# ---------------------------------------------------------------------------
# Global
# ---------------------------------------------------------------------------
variable "environment" {
  description = "Deployment environment identifier (dev, staging, prod)."
  type        = string
}

variable "project" {
  description = "Project / workload name."
  type        = string
}

variable "owner" {
  description = "Team or individual responsible for this deployment."
  type        = string
}

variable "cost_center" {
  description = "Cost center code used for billing allocation."
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources into."
  type        = string
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
variable "vnet_address_space" {
  description = "CIDR block(s) for the Virtual Network."
  type        = list(string)
}

# ---------------------------------------------------------------------------
# Virtual Machine
# ---------------------------------------------------------------------------
variable "vm_size" {
  description = "Azure VM SKU (e.g. Standard_B2s)."
  type        = string
}

variable "admin_username" {
  description = "Local administrator username for the Linux VM."
  type        = string
}

variable "admin_ssh_public_key" {
  description = "SSH public key (contents) for the Linux VM admin user."
  type        = string
  sensitive   = true
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB."
  type        = number
  default     = 30

  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 1024
    error_message = "OS disk size must be between 30 and 1024 GB."
  }
}

# ---------------------------------------------------------------------------
# Storage Account
# ---------------------------------------------------------------------------
variable "storage_account_tier" {
  description = "Performance tier for the Storage Account (Standard or Premium)."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier must be Standard or Premium."
  }
}

variable "storage_replication_type" {
  description = "Replication type for the Storage Account (LRS, GRS, ZRS, RAGRS)."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "ZRS", "RAGRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Invalid replication type."
  }
}
