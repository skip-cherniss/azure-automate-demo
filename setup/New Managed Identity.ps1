# Author: Skip M. Cherniss

# If you haven't already installed this
#Install-Module -Name Az -AllowClobber -Scope CurrentUser

if (Get-Module -ListAvailable -Name Az.*) {
    Write-Host "Az Module already installed"
}
else {
    Write-Host "Installing Az Module"
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}


### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  CONNECT TO AZURE
### ///////////////////////////////////////////////////////////////////////////////////////////////

$tenantId = ''
$subscriptionId = ''
Connect-AzAccount -Tenant $tenantId -Subscription $subscriptionId

<#

https://www.powershellgallery.com/packages/Az.ManagedServiceIdentity/0.7.2
# make sure to run as administrator
Install-Module -Name Az.ManagedServiceIdentity -RequiredVersion 0.7.2

Az.ManagedServiceIdentity
https://docs.microsoft.com/en-us/powershell/module/az.managedserviceidentity/new-azuserassignedidentity?view=azps-6.3.0

#>


### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  CREATE MANAGED IDENTITY
### ///////////////////////////////////////////////////////////////////////////////////////////////


$idname = "id-vstudio-powershell-demo"
$resourceGroupName = 'rg-vstudio-powershell-demo' 
$location = 'centralus' 

New-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $idname -Location $location


# https://docs.microsoft.com/en-us/azure/automation/add-user-assigned-identity
# add id to azure automation
$id = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $idname

# Assign this managed identity to your azure automation and add a clientId variable with the clientId value from this
Write-Host $id.ClientId

### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  GRANT MANAGED IDENTITY CONTRIBUTOR TO RESOURCE GROUP
### ///////////////////////////////////////////////////////////////////////////////////////////////

$rg = get-azresourcegroup -Name $resourceGroupName

New-AzRoleAssignment -ObjectId $id.PrincipalId -RoleDefinitionName "Contributor" -Scope $rg.ResourceId


