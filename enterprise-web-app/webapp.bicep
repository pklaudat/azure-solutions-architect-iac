targetScope = 'resourceGroup'

var location = resourceGroup().location

param listOfAppNames array

@allowed(['linux', 'windows'])
param hostingPlanOs string = 'linux'

param hostingPlanTier string = 'Basic'

param hostingPlanTierCode string = 'B1'

param hostingPlanName string

param hostingPlanWorkerSize int = 0

param maxiumHostingPlanWorkerSize int = 1

param zoneRedundant bool = false

@allowed(['PYTHON|3.12', 'PYTHON|3.11', 'PYTHON|3.10'])
param fxVersion string = 'PYTHON|3.12'

param ingressSubnet string

param egressSubnet string

param virtualNetwork string

param virtualNetworkResourceGroup string


resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: hostingPlanName
  location: location
  kind: hostingPlanOs
  tags: loadJsonContent('../metadata.json')
  sku: {
    tier: hostingPlanTier
    name: hostingPlanTierCode
  }
  properties: {
    targetWorkerCount: hostingPlanWorkerSize
    reserved: hostingPlanOs == 'linux' ? true: false
    zoneRedundant: zoneRedundant
    targetWorkerSizeId: 0
    maximumElasticWorkerCount: maxiumHostingPlanWorkerSize
  }
}


resource app 'Microsoft.Web/sites@2024-04-01' = [for i in range(0, length(listOfAppNames)): {
  name: listOfAppNames[i]
  location: location
  tags: loadJsonContent('../metadata.json')
  properties: {
    siteConfig: {
      appSettings: [

      ]
      linuxFxVersion: fxVersion
      alwaysOn: false
      ftpsState: 'Disabled'
    }
    httpsOnly: true
    vnetRouteAllEnabled: true
    publicNetworkAccess: 'Disabled'
    clientAffinityEnabled: false
    virtualNetworkSubnetId: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork, egressSubnet)
    serverFarmId: plan.id
  }
}]


resource disableScm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = [for i in range(0, length(listOfAppNames)): {
  name: '${listOfAppNames[i]}/scm'
  properties: {
    allow: false
  }
  dependsOn: [app]
}]

resource disableFtp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = [for i in range(0, length(listOfAppNames)): {
  name: '${listOfAppNames[i]}/ftp'
  properties: {
    allow: false
  }
  dependsOn: [app]
}]


resource injectVnet 'Microsoft.Web/sites/networkConfig@2024-04-01' = [for i in range(0, length(listOfAppNames)):{
  name: 'virtualNetwork'
  parent: app[i]
  properties: {
    swiftSupported: false
    subnetResourceId: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork, egressSubnet)
  }
}]

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2024-05-01' = [for i in range(0, length(listOfAppNames)): {
  name: 'pe-${listOfAppNames[i]}'
  tags: loadJsonContent('../metadata.json')
  location: location
  properties: {
    
    subnet: {
      id: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork, ingressSubnet)
      properties: {
        privateEndpointNetworkPolicies: 'Enabled'
      }
    }
    customNetworkInterfaceName: 'nic-${listOfAppNames[i]}'
    privateLinkServiceConnections: [
      {
        name: 'privatelinkConnection'
        properties: {
          groupIds: ['sites']
          privateLinkServiceId: app[i].id
        }
      }
    ]
  }
}]
