@description('Resource and host name for the Linux VM.')
param resourceName string

@description('Size of the virtual machine. Reference: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general')
@allowed([
  'Standard_A2'
  'Standard_A3'
  'Standard_B2s'
  'Standard_B2ms'
  'Standard_B4ms'
  'Standard_A2_v2'
  'Standard_A4_v2'
])
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Wether or not boot diagnostics must be enabled')
param bootDiagnostics bool

@description('Storage Account for boot diagnostics')
@maxLength(24)
param diagnosticsStorageAccountName string

@description('This parameter allows the user to select the Storage Acocunt Type for the OS Disks.')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param osStorageAccountType string = 'StandardSSD_LRS'

@description('Size of the OS disk')
@allowed([
  64
  128
  256
  512
  1024
])
param osDiskSizeGB int = 128

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended. The password must be at least 8 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param adminPasswordOrKey string

@description('Local admin username for Linux VM')
param adminUserName string

@description('Enable Azure AD Authentication to login to the virtual machine')
param aadLogin bool = true

@description('Allow remote access through an Azure Bastion Service')
param remoteAccessMode bool = true

@description('Confiugre Linux VM as Log Forwarder')
param enableCEF bool = true

@description('Name of the resourcegroup where the virtual network resides')
param virtualNetworkResourceGroup string

@description('Name of the virtual network')
param virtualNetworkName string

@description('Name of the subnet to join the virtual machine')
param subnetName string

@description('Name of the resourcegroup where the log analyics workspace resides')
param workspaceResoureGroup string

@description('Name of the Log Analytics workspace')
param workspaceName string

@description('The location of resources, such as templates and DSC modules, that the template depends on')
param _artifactsLocation string = 'https://raw.githubusercontent.com/SecureHats/Sentinel-playground/main/'

@description('Auto-generated token to access _artifactsLocation. Leave it blank unless you need to provide your own value.')
param _artifactsLocationSasToken string = ''

var workspace_id = reference(logAnalytics.id, '2015-11-01-preview').customerId
var workspace_key = listKeys(logAnalytics.id, '2015-11-01-preview').primarySharedKey
var setUpCEFScript = uri('${_artifactsLocation}/scripts/Sentinel/logforwarder.sh', '${_artifactsLocationSasToken}')
var aadLoginExtensionName = 'AADLoginForLinux'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUserName}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var azureBastionSubnet = [
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: '10.247.250.0/27'
      networkSecurityGroup: {
        id: nsg.id
      }
    }
  }
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: diagnosticsStorageAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource stglock 'Microsoft.Authorization/locks@2016-09-01' = {
  scope: storageAccount
  name: '${storageAccount.name}-lock'
  properties: {
    level: 'CanNotDelete'
    notes: 'resource should not be deleted manually'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroup)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
  scope: resourceGroup(virtualNetworkResourceGroup)
}

resource bastionNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = if (remoteAccessMode) {
  name: 'vnet-bastion'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.247.250.0/26'
      ]
    }
    subnets: azureBastionSubnet
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${resourceName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = if (remoteAccessMode) {
  name: 'nsg-bastion-host'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPsInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 110
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Outbound'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          priority: 110
          access: 'Allow'
          direction: 'Outbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2018-11-01' = if (remoteAccessMode) {
  name: 'pip-LinuxBastionHost'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource piplock 'Microsoft.Authorization/locks@2016-09-01' = {
  scope: pip
  name: '${pip.name}-lock'
  properties: {
    level: 'CanNotDelete'
    notes: 'resource should not be deleted manually'
  }
}

resource azureBastion 'Microsoft.Network/bastionHosts@2020-05-01' = if (remoteAccessMode) {
  name: 'LinuxBastionHost'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: '${bastionNetwork.id}/subnets/azureBastionSubnet'
          }
        }
      }
    ]
  }
}

resource azureBastionlock 'Microsoft.Authorization/locks@2016-09-01' = {
  scope: azureBastion
  name: '${azureBastion.name}-lock'
  properties: {
    level: 'CanNotDelete'
    notes: 'resource should not be deleted manually'
  }
}

resource bastionpeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = if (remoteAccessMode) {
  name: '${bastionNetwork.name}/bastion-link'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet.id
    }
  }
}


resource hostpeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = if (remoteAccessMode) {
  name: '${vnet.name}/bastion-link'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: bastionNetwork.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: resourceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '82gen2'
        version: 'latest'
      }
      osDisk: {
        name: '${resourceName}-osDisk'
        osType: 'Linux'
        diskSizeGB: osDiskSizeGB
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: osStorageAccountType

        }
      }
    }
    osProfile: {
      computerName: resourceName
      adminUsername: adminUserName
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    diagnosticsProfile: bootDiagnostics ? {
      bootDiagnostics: {
        enabled: bootDiagnostics
        storageUri: storageAccount.properties.primaryEndpoints.blob
      } 
    } : null
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource vmlock 'Microsoft.Authorization/locks@2016-09-01' = {
  scope: vm
  name: '${vm.name}-lock'
  properties: {
    level: 'CanNotDelete'
    notes: 'resource should not be deleted manually'
  }
}

resource aadExtensions 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = if (aadLogin) {
  name: '${vm.name}/${aadLoginExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory.LinuxSSH'
    type: aadLoginExtensionName
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}

resource cef 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = if (enableCEF){
  name: '${vm.name}/cef'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    protectedSettings: {
      commandToExecute: 'bash logforwarder.sh -w ${workspace_id} -k ${workspace_key}'
      fileUris: [
        setUpCEFScript
      ]
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' existing = {
  name: workspaceName
  scope: resourceGroup(workspaceResoureGroup)
}
