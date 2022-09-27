terraform {
  required_providers {
    azurerm = "~> 3"
  }

  backend "azurerm" {
    key                  = "dev-azure-kubernetes-service.tfstate"
    environment          = "public"
    client_id            = "f1b82532-da8e-47ee-b652-b477517d9534"
    subscription_id      = "65213276-e312-4beb-9ee5-aa0b5196e748"
    tenant_id            = "72f988bf-86f1-41af-91ab-2d7cd011db47"
    resource_group_name  = "tfstate"
    storage_account_name = "jryberg"
    container_name       = "tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}