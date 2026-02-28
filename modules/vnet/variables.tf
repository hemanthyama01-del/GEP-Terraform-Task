# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
variable "create_resource_group" {
  description = "Whether to create the resource group. Set to false to reference an existing one."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group. Used for creation or data-lookup depending on create_resource_group."
  type        = string

  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Azure region to deploy resources into (e.g. eastus, westeurope)."
  type        = string

  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "westus3",
      "centralus", "northcentralus", "southcentralus",
      "westeurope", "northeurope", "uksouth", "ukwest",
      "eastasia", "southeastasia", "australiaeast",
    ], var.location)
    error_message = "Location must be a valid Azure region short-name."
  }
}

# ---------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------
variable "vnet_name" {
  description = "Name of the Azure Virtual Network."
  type        = string
}

variable "vnet_address_space" {
  description = "List of CIDR blocks assigned to the VNET (e.g. [\"10.0.0.0/16\"])."
  type        = list(string)

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "At least one address space CIDR block is required."
  }
}

variable "dns_servers" {
  description = "Optional list of custom DNS server IP addresses. Leave empty to use Azure-provided DNS."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# DDoS Protection
# ---------------------------------------------------------------------------
variable "enable_ddos_protection" {
  description = "Enable Azure DDoS Network Protection plan on this VNET."
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "Resource ID of an existing DDoS protection plan. Required when enable_ddos_protection = true."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------
variable "subnets" {
  description = <<-EOT
    Map of subnet definitions. Key is the subnet logical name.
    Each object supports:
      - address_prefixes      : (required) List of CIDR blocks.
      - service_endpoints     : (optional) List of Azure service endpoint identifiers.
      - delegation_name       : (optional) Delegation name (used when delegating to a service).
      - delegation_service    : (optional) Service name for the delegation (e.g. "Microsoft.Web/serverFarms").
      - delegation_actions    : (optional) List of actions allowed by the delegated service.
      - private_endpoint_enabled : (optional) Disable private endpoint network policies. Default true.
      - private_link_enabled  : (optional) Disable private link service network policies. Default true.
  EOT
  type = map(object({
    address_prefixes         = list(string)
    service_endpoints        = optional(list(string), [])
    delegation_name          = optional(string, null)
    delegation_service       = optional(string, null)
    delegation_actions       = optional(list(string), [])
    private_endpoint_enabled = optional(bool, true)
    private_link_enabled     = optional(bool, true)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Network Security Groups
# ---------------------------------------------------------------------------
variable "network_security_groups" {
  description = <<-EOT
    Map of NSG definitions. Key is the NSG logical name.
    Each object supports:
      - security_rules: list of rule objects (name, priority, direction, access,
        protocol, source_port_range, destination_port_range,
        source_address_prefix, destination_address_prefix).
  EOT
  type = map(object({
    security_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# NSG <-> Subnet associations
# ---------------------------------------------------------------------------
variable "nsg_subnet_associations" {
  description = <<-EOT
    Map linking subnet logical names to NSG logical names.
    Example: { "web" = "web-nsg", "app" = "app-nsg" }
  EOT
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Tagging
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
