targetScope = 'resourceGroup'

@description('Kubernetes cluster name.')
param kubernetesClusterName string

@description('Kubernetes cluster version.')
@allowed(['1.30.0'])
param kubernetesClusterVersion string

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(50)
param agentCount int = 2

@description('The size of the Virtual Machine.')
param agentVMSize string = 'standard_D2s_v3'

param virtualNetworkResourceGroup string

param virtualNetwork string

param subnet string

param managedResourceGroup string


@allowed(['standard'])
param kubeApiLoadBalancerSku string = 'standard'

@allowed(['overlay'])
param networkPluginMode string = 'overlay'

param kubernetesServiceCidr string

param kubernetesDnsServiceIp string



var location = resourceGroup().location

resource clusterPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.${location}.azmk8s.io'
  location: 'Global'
  properties: {}
}

resource ingressPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: '${replace(kubernetesClusterName, '_', '-')}.${location}.learn.io'
  location: 'Global'
  properties: {}
}

resource networkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for zone in [clusterPrivateDnsZone.name, ingressPrivateDnsZone.name]: {
    name: '${zone}/link-${virtualNetwork}'
    location: 'Global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', virtualNetwork)
      }
    }
  }
]

module encryptionLayer 'encryption.bicep' = {
  name: '${kubernetesClusterName}-encryption-layer'
  params: {
    kubernetesClusterName: kubernetesClusterName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    virtualNetwork: virtualNetwork
    subnet: subnet
  }
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: 'user_identity-vault-access'
  location: location
}

var cryptoUserRoleId = 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
var privateDnsZoneContributorRoleId = 'b12aa53e-6015-4669-85d0-8515ebb3ae7f'

resource vaultIamAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in [cryptoUserRoleId, privateDnsZoneContributorRoleId]: {
    name: guid(subscription().id, resourceGroup().name, identity.name, role)
    properties: {
      principalId: identity.properties.principalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role)
    }
    dependsOn: [encryptionLayer]
  }
]

resource diskEncryption 'Microsoft.Compute/diskEncryptionSets@2024-03-02' = {
  name: '${kubernetesClusterName}-node-encryption'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    encryptionType: 'EncryptionAtRestWithCustomerKey'
    activeKey: {
      keyUrl: encryptionLayer.outputs.keyUrlWithVersion
    }
    rotationToLatestKeyVersionEnabled: true
  }
  dependsOn: [vaultIamAccess]
}

resource cluster 'Microsoft.ContainerService/managedClusters@2024-09-02-preview' = {
  name: kubernetesClusterName
  location: location
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    kubernetesVersion: kubernetesClusterVersion
    aadProfile: {
      managed: true
      adminGroupObjectIDs: []
      enableAzureRBAC: true
    }
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'NodeImage'
    }
    ingressProfile: {
      webAppRouting: {
        enabled: true
        nginx: {
          defaultIngressControllerType: 'Internal'
        }
        dnsZoneResourceIds: [ingressPrivateDnsZone.id]
      }
    }
    nodeResourceGroup: managedResourceGroup
    // nodeResourceGroupProfile: {
    //   restrictionLevel: 'ReadOnly' desired feature (still preview)
    // }
    dnsPrefix: replace(kubernetesClusterName, '_', '-')
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        osSKU: 'Ubuntu'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
        availabilityZones: ['1']
        enableNodePublicIP: false
        maxPods: 110
        vnetSubnetID: resourceId(
          virtualNetworkResourceGroup,
          'Microsoft.Network/virtualNetworks/subnets',
          virtualNetwork,
          subnet
        )
      }
    ]
    networkProfile: {
      loadBalancerSku: kubeApiLoadBalancerSku
      networkPlugin: 'azure'
      networkPluginMode: networkPluginMode
      networkDataplane: 'azure'
      networkPolicy: 'none'
      serviceCidr: kubernetesServiceCidr
      dnsServiceIP: kubernetesDnsServiceIp
      outboundType: 'userDefinedRouting'
      loadBalancerProfile: {
        outboundIPPrefixes: {
          publicIPPrefixes: []
        }
        outboundIPs: {
          publicIPs: []
        }
      }
    
    }
    securityProfile: {
      imageCleaner: {
        enabled: true
        intervalHours: 168
      }
      workloadIdentity: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    enableRBAC: true
    publicNetworkAccess: 'Disabled'
    disableLocalAccounts: true
    diskEncryptionSetID: diskEncryption.id
    apiServerAccessProfile: {
      enablePrivateCluster: true
      disableRunCommand: true
      enablePrivateClusterPublicFQDN: false
      // enableVnetIntegration: true
      privateDNSZone: clusterPrivateDnsZone.id
      // subnetId: resourceId( => vnet integration in the api server is a preview feature
      //   virtualNetworkResourceGroup,
      //   'Microsoft.Network/virtualNetworks/subnets',
      //   virtualNetwork,
      //   subnet
      // )
    }
  }
}


// resource extension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {}


// resource config 'Microsoft.KubernetesConfiguration/fluxConfigurations@2024-04-01-preview'
