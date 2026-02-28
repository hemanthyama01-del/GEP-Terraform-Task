terraform {
  backend "azurerm" {
    resource_group_name  = "kloudsavvy-commonRG"
    storage_account_name = "kloudsavvyinfraterraform"
    container_name       = "hemanth-task-terraform"
    key                  = "prod/terraform.tfstate"
  }
}
