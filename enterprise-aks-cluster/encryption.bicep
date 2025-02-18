
@description('Kubernetes cluster name.')
param kubernetesClusterName string

param virtualNetworkResourceGroup string

param virtualNetwork string

param subnet string

var location = resourceGroup().location


resource vaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'Global'
  properties: {}
}

resource networkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for zone in [vaultPrivateDnsZone.name]: {
  name: '${zone}/link-${virtualNetwork}'
  location: 'Global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id:  resourceId(
        virtualNetworkResourceGroup,
        'Microsoft.Network/virtualNetworks',
        virtualNetwork
      )
    }
  }
}]

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: '${replace(kubernetesClusterName, '_', '-' )}-kvault'
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enabledForDiskEncryption: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
    }
  }
}

resource encryptionKey 'Microsoft.KeyVault/vaults/keys@2024-04-01-preview' = {
  name: 'key'
  parent: keyVault
  properties: {
    keySize: 2048
    kty: 'RSA'
  }
}

resource vaultEndpointDnsIntegration 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: 'default'
  parent: vaultEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: vaultPrivateDnsZone.id
        }
      }
    ]
  }
}

resource vaultEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${keyVault.name}-endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId(
        virtualNetworkResourceGroup,
        'Microsoft.Network/virtualNetworks/subnets',
        virtualNetwork,
        subnet
      )
      properties: {
        privateEndpointNetworkPolicies: 'Enabled'
      }
    }
    customNetworkInterfaceName: 'nic-${keyVault.name}'
    privateLinkServiceConnections: [
      {
        name: 'privatelinkConnection'
        properties: {
          groupIds: ['vault']
          privateLinkServiceId:keyVault.id
        }
      }
    ]
  }
}









output keyVault string = keyVault.name
output keyVaultId string = keyVault.id
output keyUrl string = encryptionKey.properties.keyUri
output keyUrlWithVersion string = encryptionKey.properties.keyUriWithVersion
