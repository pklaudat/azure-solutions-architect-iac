targetScope = 'subscription'

@minLength(2)
@maxLength(12)
param project string = 'enterp'

param webApps array = ['app-${project}']

param webAppResourceGroup string

param virtualNetworkResourceGroup string

param virtualNetwork string

param ingressSubnet string = 'HostSubnet'

param egressSubnet string = 'OutboundSubnet'

var location = deployment().location

var tags = loadJsonContent('../metadata.json')


resource appResourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: webAppResourceGroup
  tags: tags
  location: location
  properties: {}
}


module enterpriseApp 'webapp.bicep' = {
  name: 'enterpriseapps-${project}'
  scope: appResourceGroup
  params: {
    listOfAppNames: webApps
    virtualNetwork: virtualNetwork
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    egressSubnet: egressSubnet
    ingressSubnet: ingressSubnet
    hostingPlanName: 'asp-${appResourceGroup.name}'
    hostingPlanOs: 'linux'
    hostingPlanTier: 'Basic'
    hostingPlanTierCode: 'B1'
    hostingPlanWorkerSize: 1
    maxiumHostingPlanWorkerSize: 1
  }
}
