// ============================================
// メタデータ
// ============================================
metadata description = 'Azure Infrastructure as Code テンプレート - VM, Storage, Network, Bastion'
metadata author = 'Infrastructure Team'

// ============================================
// パラメータ
// ============================================

// 基本設定
@metadata({
  description: 'Azureリージョン (例: japaneast, eastus)'
})
param location string = resourceGroup().location

@minLength(3)
@maxLength(24)
@metadata({
  description: 'プロジェクト名 (リソース名の接頭辞)'
})
param projectName string = 'handson'

@minLength(3)
@maxLength(3)
@metadata({
  description: 'ユーザー番号 (3桁: 001-050)'
})
param userNumber string = '001'

@metadata({
  description: '環境名 (dev/prod など)'
})
param environment string = 'dev'

// VM設定
@metadata({
  description: '仮想マシン名'
})
param vmName string = 'vm-${userNumber}'

@metadata({
  description: '仮想マシンのサイズ (例: Standard_D2s_v3, Standard_D4s_v3)'
})
param vmSize string = 'Standard_D2s_v3'

@metadata({
  description: 'VM管理者ユーザー名'
})
param vmAdminUsername string = 'azureuser'

@metadata({
  description: 'VM管理者パスワード (8文字以上、大文字・小文字・数字・特殊文字を含む)'
})
@secure()
param vmAdminPassword string

@metadata({
  description: 'Windows OSバージョン'
})
param vmOsVersion string = '2025-datacenter-azure-edition'

// ストレージ設定
@minLength(3)
@maxLength(24)
@metadata({
  description: 'ストレージアカウント名'
})
param storageName string = 'sahandson${userNumber}'

@metadata({
  description: 'ストレージアカウントのSKU (Standard_RAGRS, Standard_GRS など)'
})
param storageSkuName string = 'Standard_RAGRS'

@metadata({
  description: 'ストレージの公開ネットワークアクセス (Disabled/Enabled)'
})
param storagePublicNetworkAccess string = 'Disabled'

@metadata({
  description: 'ネットワークルールのデフォルトアクション (Deny/Allow)'
})
param storageDefaultAction string = 'Deny'

// ネットワーク設定
@metadata({
  description: '仮想ネットワーク名'
})
param vnetName string = 'vnet-handson'

@metadata({
  description: '仮想ネットワークのアドレス空間 (CIDR表記)'
})
param vnetAddressSpace string = '10.0.0.0/16'

@metadata({
  description: 'VM サブネット名'
})
param vmSubnetName string = 'vm-subnet'

@metadata({
  description: 'VM サブネットのアドレス範囲 (CIDR表記)'
})
param vmSubnetAddressPrefix string = '10.0.1.0/24'

@metadata({
  description: 'Private Endpoint サブネット名'
})
param peSubnetName string = 'pe-subnet'

@metadata({
  description: 'Private Endpoint サブネットのアドレス範囲 (CIDR表記)'
})
param peSubnetAddressPrefix string = '10.0.2.0/24'

// Bastion設定
@metadata({
  description: 'Azure Bastion (Developer SKU) をデプロイするかどうか'
})
param enableBastion bool = true

@metadata({
  description: 'Azure Bastion のSKU (Developer/Standard)'
})
param bastionSkuName string = 'Developer'

@metadata({
  description: 'Azure Bastion のスケールユニット数'
})
param bastionScaleUnits int = 2

// タグ
@metadata({
  description: '環境タグ (dev/staging/prod など)'
})
param tagEnvironment string = environment

@metadata({
  description: 'プロジェクトタグ'
})
param tagProject string = projectName

@metadata({
  description: 'コストセンタータグ'
})
param tagCostCenter string = 'IT'

@metadata({
  description: 'リソース作成日時'
})
param createdDate string = utcNow('u')

// ============================================
// ローカル変数
// ============================================
var commonTags = {
  environment: tagEnvironment
  project: tagProject
  costCenter: tagCostCenter
  createdDate: createdDate
  managedBy: 'Bicep'
}

var resourceNaming = {
  vm: vmName
  nic: 'vm-${userNumber}-nic'
  nsgVm: '${vnetName}-vm-subnet-nsg-${location}'
  nsgPe: '${vnetName}-pe-subnet-nsg-${location}'
  nsgVmLegacy: 'vm-${userNumber}-nsg'
  vnet: vnetName
  pe: 'pe-handson-blob'
  peNic: 'pe-handson-blob-nic'
  bastion: '${vnetName}-bastion'
  privateDnsZone: 'privatelink.blob.core.windows.net'
}

// ============================================
// ネットワークセキュリティグループ
// ============================================
resource networkSecurityGroups_vm_050_nsg_name_resource 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: resourceNaming.nsgVmLegacy
  location: location
  tags: commonTags
  properties: {
    securityRules: [
      {
        name: 'DenyInternet'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 100
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource networkSecurityGroups_vnet_handson_pe_subnet_nsg_japaneast_name_resource 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: resourceNaming.nsgPe
  location: location
  tags: commonTags
  properties: {
    securityRules: []
  }
}

resource networkSecurityGroups_vnet_handson_vm_subnet_nsg_japaneast_name_resource 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: resourceNaming.nsgVm
  location: location
  tags: commonTags
  properties: {
    securityRules: []
  }
}

// ============================================
// プライベート DNS ゾーン
// ============================================
resource privateDnsZones_privatelink_blob_core_windows_net_name_resource 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: resourceNaming.privateDnsZone
  location: 'global'
  tags: commonTags
  properties: {}
}

// ============================================
// ストレージアカウント
// ============================================
resource storageAccounts_sahandson001_name_resource 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageName
  location: location
  tags: commonTags
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

// ============================================
// 仮想マシン
// ============================================
resource virtualMachines_vm_050_name_resource 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: resourceNaming.vm
  location: location
  tags: commonTags
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
      requireGuestProvisionSignal: true
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
          id: networkInterfaces_vm_050170_name_resource.id
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

// ============================================
// Bastion ホスト
// ============================================
resource bastionHosts_vnet_handson_bastion_name_resource 'Microsoft.Network/bastionHosts@2024-07-01' = if (enableBastion) {
  name: resourceNaming.bastion
  location: location
  tags: commonTags
  sku: {
    name: bastionSkuName
  }
  properties: {
    scaleUnits: bastionScaleUnits
    virtualNetwork: {
      id: virtualNetworks_vnet_handson_name_resource.id
    }
    ipConfigurations: []
  }
}

// ============================================
// セキュリティルール
// ============================================
resource networkSecurityGroups_vm_050_nsg_name_DenyInternet 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: '${resourceNaming.nsgVmLegacy}/DenyInternet'
  properties: {
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'Internet'
    access: 'Deny'
    priority: 100
    direction: 'Outbound'
  }
  dependsOn: [
    networkSecurityGroups_vm_050_nsg_name_resource
  ]
}

// ============================================
// Private DNS Zone レコード
// ============================================
resource privateDnsZones_privatelink_blob_core_windows_net_name_sahandson001 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: privateDnsZones_privatelink_blob_core_windows_net_name_resource
  name: storageName
  properties: {
    metadata: {
      creator: 'created by private endpoint ${resourceNaming.pe} with resource guid ${privateEndpoints_pe_handson_blob_name_resource.id}'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.3.4'
      }
    ]
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_blob_core_windows_net_name 'Microsoft.Network/privateDnsZones/SOA@2024-06-01' = {
  parent: privateDnsZones_privatelink_blob_core_windows_net_name_resource
  name: '@'
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
}

// ============================================
// ストレージサービス設定
// ============================================
resource storageAccounts_sahandson001_name_default 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storageAccounts_sahandson001_name_resource
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

resource Microsoft_Storage_storageAccounts_fileServices_storageAccounts_sahandson001_name_default 'Microsoft.Storage/storageAccounts/fileServices@2025-01-01' = {
  parent: storageAccounts_sahandson001_name_resource
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

resource storageAccounts_sahandson001_name_storageAccounts_sahandson001_name_e9af9228_99fe_4a66_aa9e_7b7e0657bd72 'Microsoft.Storage/storageAccounts/privateEndpointConnections@2025-01-01' = {
  parent: storageAccounts_sahandson001_name_resource
  name: '${storageName}.e9af9228-99fe-4a66-aa9e-7b7e0657bd72'
  properties: {
    privateEndpoint: {}
    privateLinkServiceConnectionState: {
      status: 'Approved'
      description: 'Auto-Approved'
      actionRequired: 'None'
    }
  }
}

resource Microsoft_Storage_storageAccounts_queueServices_storageAccounts_sahandson001_name_default 'Microsoft.Storage/storageAccounts/queueServices@2025-01-01' = {
  parent: storageAccounts_sahandson001_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_storageAccounts_sahandson001_name_default 'Microsoft.Storage/storageAccounts/tableServices@2025-01-01' = {
  parent: storageAccounts_sahandson001_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

// ============================================
// ネットワークインターフェース
// ============================================
resource networkInterfaces_vm_050170_name_resource 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: resourceNaming.nic
  location: location
  tags: commonTags
  kind: 'Regular'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.2.4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetworks_vnet_handson_name_vm_subnet.id
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
    networkSecurityGroup: {
      id: networkSecurityGroups_vm_050_nsg_name_resource.id
    }
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}

// ============================================
// Private DNS Zone リンク
// ============================================
resource privateDnsZones_privatelink_blob_core_windows_net_name_63bhe7lgb2yni 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZones_privatelink_blob_core_windows_net_name_resource
  name: uniqueString(resourceGroup().id)
  location: 'global'
  properties: {
    registrationEnabled: false
    resolutionPolicy: 'Default'
    virtualNetwork: {
      id: virtualNetworks_vnet_handson_name_resource.id
    }
  }
}

// ============================================
// プライベートエンドポイント
// ============================================
resource privateEndpoints_pe_handson_blob_name_resource 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: resourceNaming.pe
  location: location
  tags: commonTags
  properties: {
    privateLinkServiceConnections: [
      {
        name: resourceNaming.pe
        properties: {
          privateLinkServiceId: storageAccounts_sahandson001_name_resource.id
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
      id: virtualNetworks_vnet_handson_name_pe_subnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource privateEndpoints_pe_handson_blob_name_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = {
  name: '${resourceNaming.pe}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZones_privatelink_blob_core_windows_net_name_resource.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoints_pe_handson_blob_name_resource
  ]
}

// ============================================
// 仮想ネットワーク
// ============================================
resource virtualNetworks_vnet_handson_name_resource 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: resourceNaming.vnet
  location: location
  tags: commonTags
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
            id: networkSecurityGroups_vnet_handson_vm_subnet_nsg_japaneast_name_resource.id
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
            id: networkSecurityGroups_vnet_handson_pe_subnet_nsg_japaneast_name_resource.id
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

// ============================================
// サブネット
// ============================================
resource virtualNetworks_vnet_handson_name_pe_subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: '${resourceNaming.vnet}/${peSubnetName}'
  properties: {
    addressPrefix: peSubnetAddressPrefix
    networkSecurityGroup: {
      id: networkSecurityGroups_vnet_handson_pe_subnet_nsg_japaneast_name_resource.id
    }
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
  dependsOn: [
    virtualNetworks_vnet_handson_name_resource
  ]
}

resource virtualNetworks_vnet_handson_name_vm_subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: '${resourceNaming.vnet}/${vmSubnetName}'
  properties: {
    addressPrefix: vmSubnetAddressPrefix
    networkSecurityGroup: {
      id: networkSecurityGroups_vnet_handson_vm_subnet_nsg_japaneast_name_resource.id
    }
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
  dependsOn: [
    virtualNetworks_vnet_handson_name_resource
  ]
}

// ============================================
// ストレージコンテナー
// ============================================
resource storageAccounts_sahandson001_name_default_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  parent: storageAccounts_sahandson001_name_default
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
    storageAccounts_sahandson001_name_resource
  ]
}

// ============================================
// 出力値
// ============================================
output vnetId string = virtualNetworks_vnet_handson_name_resource.id
output vnetName string = virtualNetworks_vnet_handson_name_resource.name
output vmId string = virtualMachines_vm_050_name_resource.id
output vmName string = virtualMachines_vm_050_name_resource.name
output storageAccountId string = storageAccounts_sahandson001_name_resource.id
output storageAccountName string = storageAccounts_sahandson001_name_resource.name
output storageAccountPrimaryBlobEndpoint string = storageAccounts_sahandson001_name_resource.properties.primaryBlobEndpoint
output nicId string = networkInterfaces_vm_050170_name_resource.id
output privateEndpointId string = privateEndpoints_pe_handson_blob_name_resource.id
output bastionId string = enableBastion ? bastionHosts_vnet_handson_bastion_name_resource.id : 'Bastion not enabled'
output resourceGroup string = resourceGroup().name
output location string = location
