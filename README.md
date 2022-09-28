# Azure, Terraform, and GitHub
This repository contains a template exemplifying how to use Terraform to deploy Azure resources from GitHub Actions, authenticating with a Service Principal using [OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect) (federated credentials), and remotely storing the state using an Azure Storage Account as the backend.

NOTE: This template is using Azure US Government cloud as its target environment. To point to a different cloud environment, simply update the `ARM_ENVIRONMENT` environment variable value in the GitHub workflow file to [any valid value](https://www.terraform.io/language/settings/backends/azurerm#configuration-variables). Since the default is set to 'public', you can also simply remove the `ARM_ENVIRONMENT` environment variable if deploying to Azure public cloud. Also ensure any regions are updated in the code (e.g. in the bootstrap script & TFVars files).

___
&nbsp;

# Prerequisites
## Azure
- Azure Active Directory Tenant
- Active Subscription
- Service Principal with federated credential
  - Use the [bootstrap script](bootstrap-remote-backend.ps1) to create the Service Principal and [federated credential](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#create-an-azure-active-directory-application-and-service-principal)
  - **IMPORTANT**: Make sure to copy down the Service Principal's Application ID from the output to save as a GitHub secret
- Resources to support Terraform remote backend
  - Use the [bootstrap script](bootstrap-remote-backend.ps1) to deploy the following resources:
    - Resource Group
    - Storage Account
    - Container
    - RBAC Role 'Storage Blob Data Contributor' assigned to the Service Principal on the Storage Account

## GitHub
- A [GitHub Organization](https://docs.github.com/en/get-started/learning-about-github/githubs-products#github-free-for-organizations) is required to use Azure federated credentials with GitHub Actions
- A GitHub Repository
- A GitHub Organizational Secret for the Tenant ID named 'AZURE_TENANT_ID'
- A GitHub 'Environment' in the target repository that matches the name used in the federated credential created above
- The following secrets created in the Environment:
    | Secret Name               | Value                            |
    | ------------------------- | -----------                      |
    | AZURE_CLIENT_ID           | Service Principal Application ID | 
    | AZURE_SUBSCRIPTION_ID     | Target Azure Subscription ID     |


## Terraform
- OIDC support was added in version `3.7.0`, so that is the minimum version required
- The Terraform configuration used in this example will connect to the [remote backend using OIDC & AAD RBAC](https://www.terraform.io/language/settings/backends/azurerm)
- The Terraform configuration used in this example will connect to Azure [using OIDC for the AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)

___
&nbsp;

# Bootstrap Azure Requirements
- The [bootstrap script](bootstrap-remote-backend.ps1) will only need to be run once & can be run using any authenticated account
  - Uses PowerShell to create the Azure Service Principal and Resource prerequisites using the following environment variables:

    | Variable Name             | Description |
    | ------------------------- | ----------- |
    | location                  | The target Azure region to deploy into |
    | tfbackend_rg_name         | The name for the Resource Group containing the Storage Account for the Terraform remote backend |
    | tfbackend_sa_name         | The name for the Storage Account containing the Terraform remote backend |
    | tfbackend_container_name  | The name for the Storage Account Container |
    | tf_sp_name                | The name for the Service Principal |
    | ghOrgName                 | The name for the GitHub Organization |
    | ghRepoName                | The name for the GitHub Repository |
    | ghRepoEnvironmentName     | The name for the GitHub Repository Environment |

- If any variable values from the bootstrap script are changed, the [Terraform backend configuration file](.tfbackend/dev-azure-kubernetes) needs to be updated with those changed values for the following resources:
  - Resource Group name
  - Storage Account name
  - Container name

___
&nbsp;

# Environments Overview
To follow DevOps best practices in maintaining seperate deployment boundaries, two environments are referenced in this template: DEV and TEST. In a real-world scenario, different Subscriptions with accompanying Service Principals would be assigned to each environment to keep the environments separate. To save on costs and complexity, this template actually uses the same subsciption and Service Principal deploying to separate Resource Groups representing each environment. To reproduce a real-world scenario with separate boundaries, the bootstrap script would need to be run against the different subscriptions, with the resulting Service Principal Application ID and Subscription ID values added to each appropriate GitHub Environment Secrets.

The DEV environment is meant to represent the initial 'development' environment that developers/engineers can use to build out new configurations or prove out any desired change in code/configuration. The expectations for the DEV environment are that supporting infrastructure (Identity, Networking/Routing, etc) might or might not be up and running, so integration tests are not required.

The more formal TEST environment is expected to have supporting infrastructure or services available in order to fully test any changes using functional or integration test suites. The PROD environment is not covered in this template (but might be added in a later commit 🤷). Changes to PROD would be deployed through a formal release process, currently outside the scope of this template.

___
&nbsp;

# Workflow Overview
The workflow file ['dev-azure-kubernetes.yml'](.github/workflows/dev-azure-kubernetes.yml) is the mechanism that deploys the Azure resources to the DEV environment using the terraform configuration. Its trigger is set to `workflow_dispatch` (manual) and also any `pull_request` on the main (trunk) branch. The workflow filename & defined name are the same value and must match the filename of the [Terraform partial backend configuration](.tfbackend/dev-azure-kubernetes) and [TFVars filename](terraform/data/dev-azure-kubernetes.tfvars). This is because the workflow name, which is defined in the workflow's `name` attribute (on line 1), is stored as an environment variable ('github.workflow') in the [GitHub context](https://docs.github.com/en/actions/learn-github-actions/contexts#github-context). That value is referenced to pull in the backend configuration for the `terraform init` execution and TFVars for the `terraform plan`. This allows us to maintain the same Terraform configuration assets and GitHub workflow structure across deployment environments, with dynamic values to be passed in based on target environment.

The DEV workflow is set to trigger on `pull_request` to the main (trunk) branch of the repository. The TEST workflow will trigger on the pull request being merged (pushed) to the main branch.

___
&nbsp;

# Data Structures
A central tenant to good development is good data structure. In order to reduce maintenance, confusion, and to keep IaC code simple, the data for the configuration is stored in a single location, within a data directory inside the terraform directory. Another approach is to move all the required variables to the GitHub workflow file as environment variables starting with `TF_VAR_` and ending with the actual variable name. The values will be passed into all defined GitHub Actions steps and pulled in by Terraform during execution. The upside to this approach is that literally all required data for the execution of the workflow will be in one place: the workflow file. The downside to this approach is when attempting to run Terraform locally, the variable values will need to be populated in the console as environment variables, which can get messy. Additionally - when running Terraform locally - if any variable values are generated during workflow execution, they will need to be manually generated and passed in.

NOTE: It is NEVER a good idea to create separate Terraform configurations based on environment. This eliminates the confidence that your configurations are being deployed identically to each environment. Separate configurations increase code management, decrease confidence in resource deployment parity, and will only lead to frustration. The approach given in this template is meant to provide a scalable solution to deploying across multiple environments with the same configuration with only the variable values and/or counts changing.