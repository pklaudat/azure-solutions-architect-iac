using '../enterprise-web-app/main.bicep'

param project = 'enterp'
param webApps = [
  'app-${project}'
]
param webAppResourceGroup = 'RG_WEBAPP-CENTRALUS'
param virtualNetworkResourceGroup = 'RG_NETWORK-CENTRALUS'
param virtualNetwork = 'learn-vnet'
param ingressSubnet = 'HostSubnet'
param egressSubnet = 'OutboundSubnet'

