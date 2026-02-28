locals {
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

  name_prefix = "${var.project}-${var.environment}-${local.region_code}"

  common_tags = {
    environment  = var.environment
    project      = var.project
    owner        = var.owner
    cost_center  = var.cost_center
    managed_by   = "terraform"
    last_updated = formatdate("YYYY-MM-DD", timestamp())
  }

  resource_group_name  = "${local.name_prefix}-rg"
  vnet_name            = "${local.name_prefix}-vnet"
  storage_account_name = lower(replace("st${var.project}${var.environment}${local.region_code}001", "-", ""))
}
