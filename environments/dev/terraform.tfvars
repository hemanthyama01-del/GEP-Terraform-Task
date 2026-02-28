# ============================================================
# Dev environment — terraform.tfvars
# Sensitive values (admin_ssh_public_key) should be supplied
# via TF_VAR_admin_ssh_public_key environment variable or
# a secrets manager, never committed to source control.
# ============================================================

# Global
environment = "dev"
project     = "myapp"
owner       = "platform-team"
cost_center = "CC-1001"
location    = "eastus"

# Networking
vnet_address_space = ["10.10.0.0/16"]

# Virtual Machine
vm_size        = "Standard_B2s"
admin_username = "azureuser"
# admin_ssh_public_key  = "ssh-rsa AAAA..."   # supply via env var TF_VAR_admin_ssh_public_key
os_disk_size_gb = 30

# Storage Account
storage_account_tier     = "Standard"
storage_replication_type = "LRS"
