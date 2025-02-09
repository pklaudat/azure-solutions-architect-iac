using '../network-landing-zone/main.bicep'

param createBastionHost = true
param myIpAddress = ''
param projectName = 'learn'
param virtualNetworkAddress = ''
param virtualNetworkSubnets = [
  'AzureBastionSubnet'
  'AppGwSubnet'
  'HostSubnet'
  'OutboundSubnet'
  'K8sNodesSubnet'
  'DatabaseSubnet'
]
