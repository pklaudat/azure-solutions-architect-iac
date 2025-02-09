targetScope = 'subscription'

@description('Project name.')
param projectName string

@description('Create an Azure Bastion service to easily access the kubernetes node pools.')
param createBastionHost bool

@description('Address space for the virtual network.')
param virtualNetworkAddress string

@description('Subnet list to be created in the virtual network.')
param virtualNetworkSubnets array = [
  'AzureBastionSubnet'
  'AppGwSubnet'
  'HostSubnet'
  'OutboundSubnet'
  'K8sNodesSubnet'
  'DatabaseSubnet'
]

param myIpAddress string


resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: 'RG_NETWORK-${toUpper(deployment().location)}'
  location: deployment().location
  tags: loadJsonContent('../metadata.json')
}

module bastion '../network-landing-zone/bastion.bicep' = if (createBastionHost) {
  name: 'bastion-host'
  scope: networkResourceGroup
  params: {
    bastionInstanceName: 'k8s-bastion'
    privateOnly: false
    disableCopyPaste: false
    virtualNetwork: network.outputs.virtualNetworkName
    virtualNetworkResourceGroup: networkResourceGroup.name
  }
}

module network '../network-landing-zone/network.bicep' = {
  name: 'kubernetes-network'
  scope: networkResourceGroup
  params: {
    virtualNetworkAddress: virtualNetworkAddress
    virtualNetworkName: '${projectName}-vnet'
    virtualNetworkSubnetSizes: [25, 25, 25, 25, 25, 25]
    myIpAddress: myIpAddress
    virtualNetworkSubnets: virtualNetworkSubnets
  }
}
