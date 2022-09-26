# Azure, Terraform, and GitHub
How to use Terraform to deploy Azure resources from GitHub.

## Prerequisites
- Azure Subscription
- Azure Service Principal
  - [Using OIDC](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)
- [Remote Backend Setup](bootstrap-remote-backend.ps1)
   - Resource Group
   - Storage Account
   - Container
   - RBAC Role 'Reader and Data Access' assigned to the Service Principal on the Storage Account
   - [Terraform backend configuration](dev-azure-kubernetes-service) populated with the appropriate values