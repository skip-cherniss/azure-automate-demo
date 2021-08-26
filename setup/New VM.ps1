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

$resourceGroupName = 'rg-vstudio-powershell-demo' 
$location = 'centralus' 


### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  CREATE RESOURCE GROUP
### ///////////////////////////////////////////////////////////////////////////////////////////////

New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create variables to store the storage account name and the storage account SKU information
$StorageAccountName = "stvmpowershelldemo"
$SkuName = "Standard_LRS"


### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  CREATE STORAGE ACCOUNT
### ///////////////////////////////////////////////////////////////////////////////////////////////

# Create a new storage account
$StorageAccount = New-AzStorageAccount `
  -Location $location `
  -ResourceGroupName $ResourceGroupName `
  -Type $SkuName `
  -Name $StorageAccountName

Set-AzCurrentStorageAccount `
  -StorageAccountName $storageAccountName `
  -ResourceGroupName $resourceGroupName

### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  INITIALIZE NETWORK
### ///////////////////////////////////////////////////////////////////////////////////////////////


# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name snet-demo `
  -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -Name vnet-demo `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -AllocationMethod Static `
  -IdleTimeoutInMinutes 4 `
  -Name "pip-vstudio-powershell-demo01-$(Get-Random)"
  
### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  NSG
### ///////////////////////////////////////////////////////////////////////////////////////////////

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig `
  -Name myNetworkSecurityGroupRuleRDP `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 3389 `
  -Access Allow

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
  -Name myNetworkSecurityGroupRuleWWW `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -Name nsg-vstudio-powershell-demo `
  -SecurityRules $nsgRuleRDP,$nsgRuleWeb


### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  NIC
### ///////////////////////////////////////////////////////////////////////////////////////////////


# Create a virtual network card and associate it with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name nic-vstudio-powershell-demo01 `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id



### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  CREDENTIALS
### ///////////////////////////////////////////////////////////////////////////////////////////////

# Define a credential object to store the username and password for the VM
$UserName='demouser'
$Password='Password@123'| ConvertTo-SecureString -Force -AsPlainText
$Credential=New-Object PSCredential($UserName,$Password)



### ///////////////////////////////////////////////////////////////////////////////////////////////
### *******  VM CREATION
### ///////////////////////////////////////////////////////////////////////////////////////////////
# Create the VM configuration object

$VmName = "vm-vstudio-powershell-demo01"
$VmSize = "Standard_A1_v2"
$VirtualMachine = New-AzVMConfig `
  -VMName $VmName `
  -VMSize $VmSize

$VirtualMachine = Set-AzVMOperatingSystem `
  -VM $VirtualMachine `
  -Windows `
  -ComputerName "powershelldemo" `
  -Credential $Credential -ProvisionVMAgent

$VirtualMachine = Set-AzVMSourceImage `
  -VM $VirtualMachine `
  -PublisherName "MicrosoftWindowsServer" `
  -Offer "WindowsServer" `
  -Skus "2019-Datacenter" `
  -Version "latest"

# Sets the operating system disk properties on a VM.
$VirtualMachine = Set-AzVMOSDisk `
  -VM $VirtualMachine `
  -CreateOption FromImage | `
  Set-AzVMBootDiagnostic -ResourceGroupName $ResourceGroupName `
  -StorageAccountName $StorageAccountName -Enable |`
  Add-AzVMNetworkInterface -Id $nic.Id


# Create the VM.
New-AzVM `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -VM $VirtualMachine


Stop-AzVM -ResourceGroupName $resourceGroupName -Name $VmName
