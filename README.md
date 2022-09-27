# Azure, Terraform, and GitHub
This repository contains a template exemplifying how to use Terraform to deploy Azure resources from GitHub, authenticating with a Service Principal using OIDC (federated credentials).

NOTE: This template is using Azure US Government cloud as its target environment. To point to public cloud environment, either simply remove the environment attributes from the providers.tf file (which default to public) or update the value to 'public'. Also ensure any regions are also updated (e.g. in the bootstrap script).

## Prerequisites
- Azure Subscription
- Azure Service Principal
  - Create a new Service Principal or use an existing one and [add federated credentials](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#create-an-azure-active-directory-application-and-service-principal) using the 'Environment' Entity type. This environment name will be setup in GitHub below
- Azure resources required to support remote backend
  - Use this [bootstrap script](bootstrap-remote-backend.ps1) to deploy the following resources
    - Resource Group
    - Storage Account
    - Container
    - RBAC Role 'Storage Blob Data Conributor' assigned to the Service Principal on the Storage Account
- GitHub
  - Setup a GitHub 'Environment' in your repository that matches the name used in the federated credential created above
    - Add Environment secrets for:
      - Client/Application ID
      - Subscription ID
      - Tenant ID
- Terraform
  - The Terraform configuration used in this example will connect to the [remote backend using OIDC & AAD RBAC](https://www.terraform.io/language/settings/backends/azurerm)
  - The Terraform configuration used in this example will connect to Azure [using OIDC for the AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)

## Required Modifications
- The [bootstrap script](bootstrap-remote-backend.ps1)
  - Requires the Service Principal Application ID to assign the correct RBAC role on the storage account
  - Can also modify the following values:
     - Resource Group name
     - Storage Account name
     - Location (Azure Region)
     - Container name
- [Terraform backend configuration](.tfbackend/dev-azure-kubernetes) needs to be populated with values that match the bootstrap script
  - Name of the backend file ('key')
  - Resource Group name
  - Storage Account name
  - Container name
