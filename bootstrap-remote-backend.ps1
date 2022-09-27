$env:location                 = 'usgovvirginia'
$env:tfbackend_rg_name        = 'tfstate'
$env:tfbackend_sa_name        = 'tfstate'
$env:tfbackend_container_name = 'tfstate'
$env:tf_sp_name               = 'az-tf-gh-sp'

Import-Module -Name Az.Accounts, Az.Resources, Az.Storage -Scope CurrentUser -Force

Write-Host 'Asserting Bootstrap Resources'
if (-Not (Get-AzADServicePrincipal -DisplayName))
{
    $sp = New-AzADServicePrincipal -DisplayName $env:tf_sp_name
}

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
