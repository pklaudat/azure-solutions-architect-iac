targetScope = 'resourceGroup'

param myIpAddress string = ''

@description('The virtual network name.')
param virtualNetworkName string

@description('The virtual network address range.')
param virtualNetworkAddress string

@description('List of subnets under the desired virtual network.')
param virtualNetworkSubnets array = [
  'AzureBastionSubnet'
  'AppGwSubnet'
  'HostSubnet'
  'OutboundSubnet'
  'K8sNodesSubnet'
  'DatabaseSubnet'
]

@description('List of subnet sizes for the virtual network.')
param virtualNetworkSubnetSizes array

@description('Setup custom DHCP servers - Remove Azure DNS.')
param customDNS array = []

var location = resourceGroup().location

@description('Considered range is continuous - all subnets under the same address space.')
var ipRanges = [
  for i in range(0, length(virtualNetworkSubnetSizes)): cidrSubnet(
    virtualNetworkAddress,
    virtualNetworkSubnetSizes[i],
    i
  )
]

var bastionSecurityRules = [
  {
    name: 'AllowHttpsInbound'
    properties: {
      direction: 'Inbound'
      access: 'Allow'
      priority: 120
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      sourcePortRanges: []
      sourceAddressPrefixes: [ myIpAddress ]
      destinationAddressPrefixes: []
      sourceApplicationSecurityGroups: []
      destinationApplicationSecurityGroups: []
    }
  }
  {
    name: 'AllowGatewayManagerInbound'
    properties: {
      direction: 'Inbound'
      access: 'Allow'
      priority: 130
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'GatewayManager'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
  {
    name: 'AllowzureLoadBalancerInbound'
    properties: {
      direction: 'Inbound'
      access: 'Allow'
      priority: 140
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'AzureLoadBalancer'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
  {
    name: 'AllowBastionHostCommunicationInbound'
    properties: {
      direction: 'Inbound'
      access: 'Allow'
      priority: 150
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
    }
  }
  {
    name: 'DenyAllInbound'
    properties: {
      direction: 'Inbound'
      access: 'Deny'
      priority: 4000
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
  // Outbound rules
  {
    name: 'AllowSshRdpOutbound'
    properties: {
      direction: 'Outbound'
      access: 'Allow'
      priority: 100
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '22'
        '3389'
      ]
    }
  }
  {
    name: 'AllowAzureCloudOutbound'
    properties: {
      direction: 'Outbound'
      access: 'Allow'
      priority: 110
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'AzureCloud'
      destinationPortRange: '443'
    }
  }
  {
    name: 'AllowBastionCommunicationOutbound'
    properties: {
      direction: 'Outbound'
      access: 'Allow'
      priority: 120
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
    }
  }
  {
    name: 'AllowHttpOutbound'
    properties: {
      direction: 'Outbound'
      access: 'Allow'
      priority: 130
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '80'
    }
  }
  {
    name: 'DenyAllOutbound'
    properties: {
      direction: 'Outbound'
      access: 'Deny'
      priority: 4000
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
]

resource subnetNetworkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2024-01-01' = [
  for subnet in virtualNetworkSubnets: {
    name: 'nsg-${subnet}'
    location: location
    properties: {
      securityRules: contains('AzureBastionSubnet', subnet) ? bastionSecurityRules : []
    }
  }
]

resource networkWatcher 'Microsoft.Network/networkWatchers@2024-05-01' = {
  name: 'watch-${virtualNetworkName}'
  location: location
  properties: {}
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: virtualNetworkName
  location: location
  @batchSize(1)
  resource subnets 'subnets@2024-05-01' = [
    for i in range(0, length(virtualNetworkSubnets)): {
      name: virtualNetworkSubnets[i]
      properties: {
        addressPrefix: ipRanges[i]
        defaultOutboundAccess: true
        privateEndpointNetworkPolicies: 'Enabled'
        networkSecurityGroup: {
          id: subnetNetworkSecurityGroups[i].id
        }
      }
    }
  ]
  properties: {
    addressSpace: {
      addressPrefixes: [virtualNetworkAddress]
    }
    dhcpOptions: { dnsServers: customDNS }
  }
}

output subnetIds array = [for i in range(0, length(virtualNetworkSubnets)): virtualNetwork.properties.subnets[i].id]

output subnetNames array = [for i in range(0, length(virtualNetworkSubnets)): virtualNetwork.properties.subnets[i].name]

output virtualNetworkName string = virtualNetwork.name
