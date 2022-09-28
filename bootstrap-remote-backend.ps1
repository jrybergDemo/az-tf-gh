$env:location                 = 'usgovvirginia'
$env:tfbackend_rg_name        = 'tfstate'
$env:tfbackend_sa_name        = 'tfstate'
$env:tfbackend_container_name = 'tfstate'
$env:tf_sp_name               = 'dev-az-tf-gh-sp'
$env:ghOrgName                = 'jrybergDemo'
$env:ghRepoName               = 'az-tf-gh'
$env:ghRepoEnvironmentName    = 'Azure-Gov-Dev'

Import-Module -Name Az.Accounts, Az.Resources, Az.Storage -Scope CurrentUser -Force

####################### CREATE SERVICE PRINCIPAL AND FEDERATED CREDENTIAL #######################
if (-Not ($sp = Get-AzADServicePrincipal -DisplayName $env:tf_sp_name))
{
    $sp = New-AzADServicePrincipal -DisplayName $env:tf_sp_name
}

$app = Get-AzADApplication -ApplicationId $sp.AppId
Write-Host "IMPORTANT: Save this Application ID as a secret in the GitHub environment: $($app.AppId)"

if (-Not (Get-AzADAppFederatedCredential -ApplicationObjectId $app.Id))
{
    $params = @{
        ApplicationObjectId = $app.Id
        Audience            = 'api://AzureADTokenExchange'
        Issuer              = 'https://token.actions.githubusercontent.com'
        Name                = $env:tf_sp_name
        Subject             = "repo:$($env:ghOrgName)/$($env:ghRepoName):environment:$($env:ghRepoEnvironmentName)"
    }
    New-AzADAppFederatedCredential @params
}

####################### CREATE BACKEND RESOURCES #######################
if (-Not (Get-AzResourceGroup -Name $env:tfbackend_rg_name -Location $env:location -ErrorAction 'SilentlyContinue'))
{
    New-AzResourceGroup -Name $env:tfbackend_rg_name -Location $env:location
}

if (-Not ($sa = Get-AzStorageAccount -ResourceGroupName $env:tfbackend_rg_name -Name $env:tfbackend_sa_name -ErrorAction 'SilentlyContinue'))
{
    $sa = New-AzStorageAccount -ResourceGroupName $env:tfbackend_rg_name -Name $env:tfbackend_sa_name -Location $env:location -SkuName 'Standard_GRS' -AllowBlobPublicAccess $false
}

if (-Not (Get-AzStorageContainer -Name $env:tfbackend_container_name -Context $sa.Context -ErrorAction 'SilentlyContinue'))
{
    New-AzStorageContainer -Name $env:tfbackend_container_name -Context $sa.Context
}

if (-Not (Get-AzRoleAssignment -ServicePrincipalName $sp.AppId -Scope $sa.Id -RoleDefinitionName 'Storage Blob Data Contributor'))
{
    New-AzRoleAssignment -ApplicationId $sp.AppId -Scope $sa.Id -RoleDefinitionName 'Storage Blob Data Contributor'
}
