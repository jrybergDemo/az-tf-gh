terraform {
  required_providers {
    azurerm = "~> 3"
  }

  backend "azurerm" {
    environment = "public"
    use_oidc    = true
  }
}

provider "azurerm" {
  use_oidc                   = true
  skip_provider_registration = true
  features { }
}