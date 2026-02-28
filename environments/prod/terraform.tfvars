# ============================================================
# Prod environment — terraform.tfvars
# Sensitive values (admin_ssh_public_key) must be supplied
# via TF_VAR_admin_ssh_public_key or a secrets manager.
# Never commit sensitive values to source control.
# ============================================================

# Global
environment = "prod"
project     = "myapp"
owner       = "platform-team"
cost_center = "CC-2001"
location    = "eastus2"

# Networking
vnet_address_space     = ["10.20.0.0/16"]
enable_ddos_protection = false
# ddos_protection_plan_id = "/subscriptions/<sub_id>/resourceGroups/.../providers/Microsoft.Network/ddosProtectionPlans/..."

# Virtual Machine
vm_size        = "Standard_D4s_v5"
vm_count       = 2
admin_username = "azureuser"
# admin_ssh_public_key  = "ssh-rsa AAAA..."   # supply via env var TF_VAR_admin_ssh_public_key
os_disk_size_gb = 64

# Storage Account
storage_account_tier     = "Standard"
storage_replication_type = "GRS"
