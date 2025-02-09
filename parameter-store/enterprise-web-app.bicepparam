using '../enterprise-web-app/main.bicep'

param project = 'enterp'
param webApps = [
  'app-${project}'
]
param webAppResourceGroup = ''
param virtualNetworkResourceGroup = ''
param virtualNetwork = ''
param ingressSubnet = 'HostSubnet'
param egressSubnet = 'OutboundSubnet'

