output "resource_group_name" {
  description = "Name of the deployed resource group."
  value       = module.vnet.resource_group_name
}

output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = module.vnet.vnet_id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = module.vnet.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet name → resource ID."
  value       = module.vnet.subnet_ids
}

output "vm_ids" {
  description = "List of Virtual Machine resource IDs."
  value       = azurerm_linux_virtual_machine.vm[*].id
}

output "vm_private_ips" {
  description = "List of private IP addresses for the VMs."
  value       = azurerm_network_interface.vm[*].private_ip_address
}

output "storage_account_name" {
  description = "Name of the deployed Storage Account."
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "Resource ID of the Storage Account."
  value       = azurerm_storage_account.main.id
}
