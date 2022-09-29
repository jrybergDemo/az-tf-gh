# Authenticate to Azure Subscription
# Connect-AzAccount -Environment AzureCloud -Subscription $subId

$env:location                 = 'westus2'
$env:tfbackend_rg_name        = 'tfstate'
$env:tfbackend_sa_name        = 'jrybergdemo'
$env:tfbackend_container_name = 'tfstate'
$env:tf_sp_name               = 'dev-az-tf-gh-sp'
$env:ghOrgName                = 'jrybergDemo'
$env:ghRepoName               = 'az-tf-gh'
$env:ghRepoEnvironmentName    = 'Azure-Public-Dev'

Import-Module -Name Az.Accounts, Az.Resources, Az.Storage -Scope 'Local' -Force

####################### CREATE SERVICE PRINCIPAL AND FEDERATED CREDENTIAL #######################
if (-Not ($sp = Get-AzADServicePrincipal -DisplayName $env:tf_sp_name))
{
    $sp = New-AzADServicePrincipal -DisplayName $env:tf_sp_name
}

$app = Get-AzADApplication -ApplicationId $sp.AppId
Write-Host "IMPORTANT: Save this Application ID as a secret in the GitHub environment: $($app.AppId)" -ForegroundColor Green

if (-Not (Get-AzADAppFederatedCredential -ApplicationObjectId $app.Id))
{
    $params = @{
        ApplicationObjectId = $app.Id
        Audience            = 'api://AzureADTokenExchange'
        Issuer              = 'https://token.actions.githubusercontent.com'
        Name                = $env:tf_sp_name
        Subject             = "repo:$($env:ghOrgName)/$($env:ghRepoName):environment:$($env:ghRepoEnvironmentName)"
    }
    $cred = New-AzADAppFederatedCredential @params
}

####################### CREATE BACKEND RESOURCES #######################
if (-Not (Get-AzResourceGroup -Name $env:tfbackend_rg_name -Location $env:location -ErrorAction 'SilentlyContinue'))
{
    New-AzResourceGroup -Name $env:tfbackend_rg_name -Location $env:location -ErrorAction 'Stop'
}

if (-Not ($sa = Get-AzStorageAccount -ResourceGroupName $env:tfbackend_rg_name -Name $env:tfbackend_sa_name -ErrorAction 'SilentlyContinue'))
{
    $sa = New-AzStorageAccount -ResourceGroupName $env:tfbackend_rg_name -Name $env:tfbackend_sa_name -Location $env:location -SkuName 'Standard_GRS' -AllowBlobPublicAccess $false -ErrorAction 'Stop'
}

if (-Not (Get-AzStorageContainer -Name $env:tfbackend_container_name -Context $sa.Context -ErrorAction 'SilentlyContinue'))
{
    $container = New-AzStorageContainer -Name $env:tfbackend_container_name -Context $sa.Context -ErrorAction 'Stop'
}

if (-Not (Get-AzRoleAssignment -ServicePrincipalName $sp.AppId -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)" -RoleDefinitionName 'Contributor' -ErrorAction 'SilentlyContinue'))
{
    $subContributorRA = New-AzRoleAssignment -ApplicationId $sp.AppId -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)" -RoleDefinitionName 'Contributor' -ErrorAction 'Stop'
}

if (-Not (Get-AzRoleAssignment -ServicePrincipalName $sp.AppId -Scope $sa.Id -RoleDefinitionName 'Storage Blob Data Contributor' -ErrorAction 'SilentlyContinue'))
{
    $saBlobContributorRA = New-AzRoleAssignment -ApplicationId $sp.AppId -Scope $sa.Id -RoleDefinitionName 'Storage Blob Data Contributor' -ErrorAction 'Stop'
}
