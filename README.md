# Azure, Terraform, and GitHub
This repository contains a template exemplifying how to use Terraform to deploy Azure resources from GitHub Actions, authenticating with a Service Principal using [OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect) (federated credentials).

NOTE: This template is using Azure US Government cloud as its target environment. To point to a different cloud environment, simply update the `ARM_ENVIRONMENT` environment variable value in the GitHub workflow file to [any valid value](https://www.terraform.io/language/settings/backends/azurerm#configuration-variables). Since the default is set to 'public', you can also simply remove the `ARM_ENVIRONMENT` environment variable if deploying to Azure public cloud. Also ensure any regions are also updated (e.g. in the bootstrap script).

## Prerequisites
- Azure Subscription
- Azure Service Principal
  - Create a new Service Principal or use an existing one and [add federated credentials](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#create-an-azure-active-directory-application-and-service-principal) using the 'Environment' Entity type. This environment name will be setup in GitHub below
- Azure resources required to support remote backend
  - Use this [bootstrap script](bootstrap-remote-backend.ps1) to deploy the following resources:
    - Service Principal
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
  - OIDC support was added in version `3.7.0`, so that is the minimum required
  - The Terraform configuration used in this example will connect to the [remote backend using OIDC & AAD RBAC](https://www.terraform.io/language/settings/backends/azurerm)
  - The Terraform configuration used in this example will connect to Azure [using OIDC for the AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)

## Required Modifications
- The [bootstrap script](bootstrap-remote-backend.ps1) will only need to be run once & can be run using any authenticated account
  - Requires the Service Principal display name to create the Service Principal and assign the correct RBAC role on the storage account
  - Can also modify the following values:
     - Resource Group name
     - Storage Account name
     - Location (Azure Region)
     - Container name
- [Terraform backend configuration](.tfbackend/dev-azure-kubernetes) needs to be updated with values that match the bootstrap script if any resource names were changed:
  - Name of the backend file ('key')
  - Resource Group name
  - Storage Account name
  - Container name

## Environments Overview
There are two environments defined in this template: DEV and TEST. The DEV environment is meant to represent the initial 'development' environment that developers/engineers can use to build out new configurations or test out any desired change in code/configuration. The expectations for the DEV environment are that supporting infrastructure (Identity, Networking/Routing, etc) might or might not be up and running, so integration tests are not required. The more formal TEST environment is expected to have supporting infrastructure or services available in order to fully test any changes using functional or integration test suites. The PROD environment is assumed and changes there would be released by a designated team using a formal release process.

## Workflow Overview
The workflow file ['dev-azure-kubernetes.yml'](.github/workflows/dev-azure-kubernetes.yml) is the mechanism that deploys the Azure resources to the DEV environment using the terraform configuration. Its trigger is set to `workflow_dispatch` (manual) and also any `pull_request` on the main (trunk) branch. The workflow filename & defined name are the same value and must match the filename of the [Terraform partial backend configuration](.tfbackend/dev-azure-kubernetes) and [TFVars filename](terraform/data/dev-azure-kubernetes.tfvars). This is because the workflow name, which is defined in the workflow's `name` attribute (on line 1), is stored as an environment variable ('github.workflow') in the [GitHub context](https://docs.github.com/en/actions/learn-github-actions/contexts#github-context). That value is referenced to pull in the backend configuration for the `terraform init` execution and TFVars for the `terraform plan`. This allows us to maintain the same Terraform configuration assets and GitHub workflow structure across deployment environments, with dynamic values to be passed in based on target environment.

The DEV workflow is set to trigger on `pull_request` to the main (trunk) branch of the repository. The TEST workflow will trigger on the pull request being merged (pushed) to the main branch.

## Data Structures
A central tenant to good development is good data structure. In order to reduce maintenance, confusion, and to keep IaC code simple, the data for the configuration is stored in a single location, within a data directory inside the terraform directory. Another approach is to move all the required variables to the GitHub workflow file as environment variables starting with `TF_VAR_` and ending with the actual variable name. The values will be passed into all defined GitHub Actions steps and pulled in by Terraform during execution. The upside to this approach is that literally all required data for the execution of the workflow will be in one place: the workflow file. The downside to this approach is when attempting to run Terraform locally, the variable values will need to be populated in the console as environment variables, which can get messy. Additionally - when running Terraform locally - if any variable values are generated during workflow execution, they will need to be manually generated and passed in.

NOTE: It is NEVER a good idea to create separate Terraform configurations based on environment. This eliminates the confidence that your configurations are being deployed identically to each environment. Separate configurations increase code management, decrease confidence in resource deployment parity, and will only lead to frustration. The approach given in this template is meant to provide a scalable solution to deploying across multiple environments with the same configuration with only the variable values and/or counts changing.