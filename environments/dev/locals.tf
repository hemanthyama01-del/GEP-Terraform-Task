locals {
  # Short region abbreviation used in naming
  region_short = {
    "eastus"        = "eus"
    "eastus2"       = "eus2"
    "westus"        = "wus"
    "westus2"       = "wus2"
    "westus3"       = "wus3"
    "centralus"     = "cus"
    "westeurope"    = "weu"
    "northeurope"   = "neu"
    "uksouth"       = "uks"
    "ukwest"        = "ukw"
    "eastasia"      = "ea"
    "southeastasia" = "sea"
    "australiaeast" = "aue"
  }

  region_code = lookup(local.region_short, var.location, replace(var.location, " ", ""))

  # Naming convention: project-env-region-resource
  name_prefix = "${var.project}-${var.environment}-${local.region_code}"

  # Consistent tags applied to every resource
  common_tags = {
    environment  = var.environment
    project      = var.project
    owner        = var.owner
    cost_center  = var.cost_center
    managed_by   = "terraform"
    last_updated = formatdate("YYYY-MM-DD", timestamp())
  }

  # Resource names
  resource_group_name  = "${local.name_prefix}-rg"
  vnet_name            = "${local.name_prefix}-vnet"
  vm_name              = "${local.name_prefix}-vm"
  nic_name             = "${local.name_prefix}-nic"
  pip_name             = "${local.name_prefix}-pip"
  os_disk_name         = "${local.name_prefix}-osdisk"
  storage_account_name = lower(replace("st${var.project}${var.environment}${local.region_code}001", "-", ""))
}
