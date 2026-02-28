# ---------------------------------------------------------------------------
# VNET Module
# ---------------------------------------------------------------------------
module "vnet" {
  source = "../../modules/vnet"

  create_resource_group   = true
  resource_group_name     = local.resource_group_name
  location                = var.location
  vnet_name               = local.vnet_name
  vnet_address_space      = var.vnet_address_space
  enable_ddos_protection  = var.enable_ddos_protection
  ddos_protection_plan_id = var.ddos_protection_plan_id

  subnets = {
    "${local.name_prefix}-snet-app" = {
      address_prefixes  = [cidrsubnet(var.vnet_address_space[0], 4, 0)]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "${local.name_prefix}-snet-data" = {
      address_prefixes  = [cidrsubnet(var.vnet_address_space[0], 4, 1)]
      service_endpoints = ["Microsoft.Storage"]
    }
    "${local.name_prefix}-snet-mgmt" = {
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 4, 2)]
    }
  }

  network_security_groups = {
    "${local.name_prefix}-nsg-app" = {
      security_rules = [
        {
          name                       = "allow-https-inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-http-redirect-inbound"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        },
        {
          name                       = "deny-all-inbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
      ]
    }
    "${local.name_prefix}-nsg-mgmt" = {
      security_rules = [
        {
          name                       = "allow-ssh-bastion-inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        },
        {
          name                       = "deny-all-inbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
      ]
    }
  }

  nsg_subnet_associations = {
    "${local.name_prefix}-snet-app"  = "${local.name_prefix}-nsg-app"
    "${local.name_prefix}-snet-mgmt" = "${local.name_prefix}-nsg-mgmt"
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Network Interfaces + Linux VMs  (count-based for scalability)
# ---------------------------------------------------------------------------
resource "azurerm_network_interface" "vm" {
  count               = var.vm_count
  name                = "${local.name_prefix}-nic-${format("%02d", count.index + 1)}"
  resource_group_name = module.vnet.resource_group_name
  location            = var.location
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnet_ids["${local.name_prefix}-snet-app"]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                           = var.vm_count
  name                            = "${local.name_prefix}-vm-${format("%02d", count.index + 1)}"
  resource_group_name             = module.vnet.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  tags                            = local.common_tags

  network_interface_ids = [azurerm_network_interface.vm[count.index].id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    name                 = "${local.name_prefix}-osdisk-${format("%02d", count.index + 1)}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

# ---------------------------------------------------------------------------
# Storage Account  (Blob enabled, production-hardened)
# ---------------------------------------------------------------------------
resource "random_string" "storage_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_storage_account" "main" {
  name                      = substr("${local.storage_account_name}${random_string.storage_suffix.result}", 0, 24)
  resource_group_name       = module.vnet.resource_group_name
  location                  = var.location
  account_tier              = var.storage_account_tier
  account_replication_type  = var.storage_replication_type
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true
  tags                      = local.common_tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [module.vnet.subnet_ids["${local.name_prefix}-snet-app"]]
  }
}

resource "azurerm_storage_container" "main" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
