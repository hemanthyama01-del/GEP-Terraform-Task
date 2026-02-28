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

variable "enable_ddos_protection" {
  description = "Enable Azure DDoS Network Protection plan."
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "Resource ID of an existing DDoS protection plan."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Virtual Machine
# ---------------------------------------------------------------------------
variable "vm_size" {
  description = "Azure VM SKU."
  type        = string
}

variable "admin_username" {
  description = "Local administrator username for the Linux VM."
  type        = string
}

variable "admin_ssh_public_key" {
  description = "SSH public key for the Linux VM admin user."
  type        = string
  sensitive   = true
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB."
  type        = number
  default     = 64

  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 1024
    error_message = "OS disk size must be between 30 and 1024 GB."
  }
}

variable "vm_count" {
  description = "Number of Linux VMs to deploy."
  type        = number
  default     = 1

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 10
    error_message = "vm_count must be between 1 and 10."
  }
}

# ---------------------------------------------------------------------------
# Storage Account
# ---------------------------------------------------------------------------
variable "storage_account_tier" {
  description = "Performance tier for the Storage Account."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier must be Standard or Premium."
  }
}

variable "storage_replication_type" {
  description = "Replication type for the Storage Account."
  type        = string
  default     = "GRS"

  validation {
    condition     = contains(["LRS", "GRS", "ZRS", "RAGRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Invalid replication type."
  }
}
