$env:location                 = 'usgovvirginia'
$env:tfbackend_rg_name        = 'tfstate'
$env:tfbackend_sa_name        = 'tfstate'
$env:tfbackend_container_name = 'tfstate'
$env:tf_client_app_id         = '<SERVICE_PRINCIPAL_GUID>'

Install-Module -Name Az.Accounts, Az.Resources, Az.Storage -Scope CurrentUser -Force

Write-Host 'Asserting Bootstrap Resources'

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

if (-Not (Get-AzRoleAssignment -ServicePrincipalName $env:tf_client_app_id -Scope $sa.Id -RoleDefinitionName 'Storage Blob Data Contributor'))
{
    New-AzRoleAssignment -ApplicationId $env:tf_client_app_id -Scope $sa.Id -RoleDefinitionName 'Storage Blob Data Contributor'
}
