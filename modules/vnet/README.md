# terraform-azure-vnet

A reusable, production-ready Terraform module that provisions a **secure Azure Virtual Network** together with optional subnets, NSGs, and DDoS protection.

---

<!-- BEGIN_TF_DOCS -->
<!-- terraform-docs output is injected here automatically by pre-commit -->
<!-- END_TF_DOCS -->

## Usage

```hcl
module "vnet" {
  source = "../../modules/vnet"

  create_resource_group = true
  resource_group_name   = "myapp-dev-eus-rg"
  location              = "eastus"

  vnet_name          = "myapp-dev-eus-vnet"
  vnet_address_space = ["10.10.0.0/16"]

  subnets = {
    "myapp-dev-eus-snet-app" = {
      address_prefixes  = ["10.10.0.0/20"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
  }

  network_security_groups = {
    "myapp-dev-eus-nsg-app" = {
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
        }
      ]
    }
  }

  nsg_subnet_associations = {
    "myapp-dev-eus-snet-app" = "myapp-dev-eus-nsg-app"
  }

  tags = {
    environment = "dev"
    project     = "myapp"
    owner       = "platform-team"
    cost_center = "CC-1001"
    managed_by  = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `create_resource_group` | Create resource group if true, else look up existing | `bool` | `true` | no |
| `resource_group_name` | Resource group name | `string` | n/a | yes |
| `location` | Azure region | `string` | n/a | yes |
| `vnet_name` | Virtual Network name | `string` | n/a | yes |
| `vnet_address_space` | CIDR block list for the VNET | `list(string)` | n/a | yes |
| `dns_servers` | Custom DNS server IPs | `list(string)` | `[]` | no |
| `enable_ddos_protection` | Enable DDoS protection plan | `bool` | `false` | no |
| `ddos_protection_plan_id` | Existing DDoS plan resource ID | `string` | `null` | no |
| `subnets` | Map of subnet definitions | `map(object)` | `{}` | no |
| `network_security_groups` | Map of NSG definitions | `map(object)` | `{}` | no |
| `nsg_subnet_associations` | Subnet → NSG association map | `map(string)` | `{}` | no |
| `tags` | Common tag map | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Name of the resource group |
| `resource_group_id` | Resource ID of the resource group |
| `vnet_id` | Resource ID of the VNET |
| `vnet_name` | Name of the VNET |
| `vnet_address_space` | Address space of the VNET |
| `subnet_ids` | Map of subnet name → resource ID |
| `subnet_address_prefixes` | Map of subnet name → prefixes |
| `nsg_ids` | Map of NSG name → resource ID |
| `location` | Deployed region |
