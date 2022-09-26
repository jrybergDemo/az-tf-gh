$env:location =                 'westus2'
$env:tfbackend_rg_name =        'D-WUS2-TFSTATE'
$env:tfbackend_sa_name =        'dwus2contosotfstate'
$env:tfbackend_container_name = 'd-wus2-contoso-tfstate'
$env:tf_client_obj_id =         '<SERVICE_PRINCIPAL_GUID>'

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

if (-Not (Get-AzRoleAssignment -ObjectId $env:tf_client_obj_id -RoleDefinitionName 'Reader and Data Access' -Scope $sa.Id  -ErrorAction 'SilentlyContinue'))
{
    az role assignment create --assignee-object-id $env:tf_client_obj_id --role 'Reader and Data Access' --scope $sa.Id
}