metadata description = 'Azure Infrastructure as Code テンプレート - VM, Storage, Network, Bastion'
metadata author = 'Infrastructure Team'

@description('Azureリージョン (例: japaneast, eastus)')
param location string = resourceGroup().location

@description('ユーザー番号 (3桁: 001-050)')
@allowed([
  '001'
  '002'
  '003'
  '004'
  '005'
  '006'
  '007'
  '008'
  '009'
  '010'
  '011'
  '012'
  '013'
  '014'
  '015'
  '016'
  '017'
  '018'
  '019'
  '020'
  '021'
  '022'
  '023'
  '024'
  '025'
  '026'
  '027'
  '028'
  '029'
  '030'
  '031'
  '032'
  '033'
  '034'
  '035'
  '036'
  '037'
  '038'
  '039'
  '040'
  '041'
  '042'
  '043'
  '044'
  '045'
  '046'
  '047'
  '048'
  '049'
  '050'
])
param userNumber string = '001'

@description('仮想マシンのサイズ (例: Standard_D2s_v3, Standard_D4s_v3)')
param vmSize string = 'Standard_D2s_v3'

@description('VM管理者ユーザー名')
param vmAdminUsername string = 'azureuser'

@description('VM管理者パスワード (8文字以上、大文字・小文字・数字・特殊文字を含む)')
@secure()
param vmAdminPassword string

// 固定値（ポータルに表示しない）
var vmName = 'vm-${userNumber}'
var vmOsVersion = '2025-datacenter-azure-edition'
var storageName = 'sahandson${userNumber}'
var storageSkuName = 'Standard_RAGRS'
var storagePublicNetworkAccess = 'Disabled'
var storageDefaultAction = 'Deny'
var vnetName = 'vnet-handson'
var vnetAddressSpace = '10.0.0.0/16'
var vmSubnetName = 'vm-subnet'
var vmSubnetAddressPrefix = '10.0.1.0/24'
var peSubnetName = 'pe-subnet'
var peSubnetAddressPrefix = '10.0.2.0/24'
var bastionSkuName = 'Developer'
var bastionScaleUnits = 2
var enableBastion = false

var resourceNaming = {
  vm: vmName
  nic: 'vm-${userNumber}-nic'
  nsgVm: 'vm-subnet-nsg'
  nsgPe: 'pe-subnet-nsg'
  vnet: vnetName
  pe: 'pe-handson-blob'
  peNic: 'pe-handson-blob-nic'
  bastion: '${vnetName}-bastion'
  privateDnsZone: 'privatelink.blob.core.windows.net'
}


resource resourceNaming_nsgVm 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: resourceNaming.nsgVm
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyInternet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80,443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 100
          direction: 'Outbound'
          description: 'ブラウザでのインターネット閲覧を拒否 (HTTP/HTTPS)'
        }
      }
    ]
  }
}

resource resourceNaming_nsgPe 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: resourceNaming.nsgPe
  location: location
  properties: {
    securityRules: []
  }
}

resource resourceNaming_privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: resourceNaming.privateDnsZone
  location: 'global'
  properties: {}
}

resource storage 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageName
  location: location
  sku: {
    name: storageSkuName
    tier: split(storageSkuName, '_')[0]
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: storagePublicNetworkAccess
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    largeFileSharesState: 'Enabled'
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: storageDefaultAction
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource resourceNaming_vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: resourceNaming.vm
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: vmOsVersion
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${resourceNaming.vm}_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: resourceNaming.vm
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
          assessmentMode: 'ImageDefault'
          enableHotpatching: true
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceNaming_nic.id
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource resourceNaming_bastion 'Microsoft.Network/bastionHosts@2024-07-01' = if (enableBastion) {
  name: resourceNaming.bastion
  location: location
  sku: {
    name: bastionSkuName
  }
  properties: {
    scaleUnits: bastionScaleUnits
    virtualNetwork: {
      id: resourceNaming_vnet.id
    }
    ipConfigurations: []
  }
}

resource resourceNaming_privateDnsZone_storage 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  name: '${resourceNaming.privateDnsZone}/${storageName}'
  properties: {
    metadata: {
      creator: 'created by private endpoint ${resourceNaming.pe} with resource guid ${resourceNaming_pe.id}'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.3.4'
      }
    ]
  }
  dependsOn: [
    resourceNaming_privateDnsZone
  ]
}

resource Microsoft_Network_privateDnsZones_SOA_resourceNaming_privateDnsZone 'Microsoft.Network/privateDnsZones/SOA@2024-06-01' = {
  name: '${resourceNaming.privateDnsZone}/@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
  dependsOn: [
    resourceNaming_privateDnsZone
  ]
}

resource storageName_default 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storage
  name: 'default'
  sku: {
    name: storageSkuName
    tier: split(storageSkuName, '_')[0]
  }
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_storageName_default 'Microsoft.Storage/storageAccounts/fileServices@2025-01-01' = {
  parent: storage
  name: 'default'
  sku: {
    name: storageSkuName
    tier: split(storageSkuName, '_')[0]
  }
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource Microsoft_Storage_storageAccounts_queueServices_storageName_default 'Microsoft.Storage/storageAccounts/queueServices@2025-01-01' = {
  parent: storage
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_storageName_default 'Microsoft.Storage/storageAccounts/tableServices@2025-01-01' = {
  parent: storage
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource resourceNaming_nic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: resourceNaming.nic
  location: location
  kind: 'Regular'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.2.4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceNaming_vnet_vmSubnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
  dependsOn: [
    resourceNaming_vnet_vmSubnet
  ]
}

resource resourceNaming_privateDnsZone_id 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: '${resourceNaming.privateDnsZone}/${uniqueString(resourceGroup().id)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    resolutionPolicy: 'Default'
    virtualNetwork: {
      id: resourceNaming_vnet.id
    }
  }
  dependsOn: [
    resourceNaming_privateDnsZone
  ]
}

resource resourceNaming_pe 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: resourceNaming.pe
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: resourceNaming.pe
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'blob'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: resourceNaming.peNic
    subnet: {
      id: resourceNaming_vnet_peSubnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
  dependsOn: [
    resourceNaming_vnet_peSubnet
  ]
}

resource resourceNaming_pe_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = {
  name: '${resourceNaming.pe}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: resourceNaming_privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    resourceNaming_pe
  ]
}

resource resourceNaming_vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: resourceNaming.vnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    privateEndpointVNetPolicies: 'Disabled'
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: vmSubnetName
        properties: {
          addressPrefix: vmSubnetAddressPrefix
          networkSecurityGroup: {
            id: resourceNaming_nsgVm.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
      {
        name: peSubnetName
        properties: {
          addressPrefix: peSubnetAddressPrefix
          networkSecurityGroup: {
            id: resourceNaming_nsgPe.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource resourceNaming_vnet_peSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: '${resourceNaming.vnet}/${peSubnetName}'
  properties: {
    addressPrefix: peSubnetAddressPrefix
    networkSecurityGroup: {
      id: resourceNaming_nsgPe.id
    }
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
  dependsOn: [
    resourceNaming_vnet
  ]
}

resource resourceNaming_vnet_vmSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: '${resourceNaming.vnet}/${vmSubnetName}'
  properties: {
    addressPrefix: vmSubnetAddressPrefix
    networkSecurityGroup: {
      id: resourceNaming_nsgVm.id
    }
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
  dependsOn: [
    resourceNaming_vnet
  ]
}

resource storageName_default_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  parent: storageName_default
  name: 'container'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
  dependsOn: [
    storage
  ]
}

output vnetId string = resourceNaming_vnet.id
output vnetName string = resourceNaming.vnet
output vmId string = resourceNaming_vm.id
output vmName string = resourceNaming.vm
output storageAccountId string = storage.id
output storageAccountName string = storageName
output storageAccountPrimaryBlobEndpoint string = storage.properties.primaryEndpoints.blob
output nicId string = resourceNaming_nic.id
output privateEndpointId string = resourceNaming_pe.id
output bastionId string = (enableBastion ? resourceNaming_bastion.id : 'Bastion not enabled')
output resourceGroup string = resourceGroup().name
output location string = location
