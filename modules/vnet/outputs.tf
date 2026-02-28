output "resource_group_name" {
  description = "Name of the resource group that contains the VNET."
  value       = local.resource_group_name
}

output "resource_group_id" {
  description = "Resource ID of the resource group."
  value       = var.create_resource_group ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.existing[0].id
}

output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "Address space assigned to the Virtual Network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet logical name → subnet resource ID."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet logical name → list of address prefixes."
  value       = { for k, v in azurerm_subnet.this : k => v.address_prefixes }
}

output "nsg_ids" {
  description = "Map of NSG logical name → NSG resource ID."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "location" {
  description = "Azure region where the VNET was deployed."
  value       = local.location
}
