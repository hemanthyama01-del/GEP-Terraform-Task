# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.existing[0].name
  location            = var.create_resource_group ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.existing[0].location
}

# ---------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = local.resource_group_name
  location            = local.location
  address_space       = var.vnet_address_space
  dns_servers         = length(var.dns_servers) > 0 ? var.dns_servers : null
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = length(each.value.service_endpoints) > 0 ? each.value.service_endpoints : null

  private_endpoint_network_policies             = each.value.private_endpoint_enabled ? "Enabled" : "Disabled"
  private_link_service_network_policies_enabled = each.value.private_link_enabled

  dynamic "delegation" {
    for_each = each.value.delegation_name != null ? [1] : []
    content {
      name = each.value.delegation_name
      service_delegation {
        name    = each.value.delegation_service
        actions = each.value.delegation_actions
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Network Security Groups
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  for_each = var.network_security_groups

  name                = each.key
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = var.tags

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# ---------------------------------------------------------------------------
# NSG <-> Subnet Associations
# ---------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = var.nsg_subnet_associations

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value].id
}
