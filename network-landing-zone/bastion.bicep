param bastionInstanceName string

param disableCopyPaste bool = false

@allowed(['Developer', 'Basic','Standard', 'Premium'])
param tier string = 'Basic'

@allowed( [['1'], ['2'], ['3'], ['1','2'], ['2', '3'], ['1', '2', '3'], []] )
param availabilityZones array = []

param privateOnly bool = false

param virtualNetwork string

param virtualNetworkResourceGroup string

param instanceCount int = 2


var location = resourceGroup().location

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-${bastionInstanceName}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: bastionInstanceName
    }
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2024-01-01' = {
  name: bastionInstanceName
  sku: {
    name: tier
  }
  zones: availabilityZones == [] ? null: availabilityZones
  location: location
  properties: {
    scaleUnits: instanceCount
    disableCopyPaste: disableCopyPaste
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: privateOnly ? {} : { id: publicIp.id }
          subnet: {
            id: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork, 'AzureBastionSubnet')
          }
        }
      }
    ]
    
  }
}
