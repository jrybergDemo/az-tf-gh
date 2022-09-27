terraform {
  required_providers {
    azurerm = "~> 3"
  }

  backend "azurerm" {
    environment = "usgovernment"
    use_oidc    = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  environment                = "usgovernment"
  use_oidc                   = true
  skip_provider_registration = true
  features { }
}