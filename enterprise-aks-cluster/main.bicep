targetScope = 'subscription'

@description('Kubernetes cluster name.')
param kubernetesClusterName string


@description('Kubernetes cluster version.')
@allowed(['1.29.9'])
param kubernetesClusterVersion string


param virtualNetworkResourceGroup string
param virtualNetwork string
param nodesSubnet string

param managedResourceGroup string = 'RG_ENTERPRISE_AKS_MANAGED'


var location = deployment().location



resource customerManagedRG 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'RG_ENTERPRISE_AKS'
  location: location
  tags: loadJsonContent('../metadata.json')
  properties: {}
}

// resource msftManagedRG 'Microsoft.Resources/resourceGroups@2024-11-01' = {
//   name: 'RG_ENTERPRISE_AKS_MANAGED'
//   location: location
//   tags: loadJsonContent('../metadata.json')
//   properties: {}
// }

// 10.0.0.0/16
// 10.0.0.10
// 100.0.0.0/16

module aks 'cluster.bicep' = {
  name: 'enterprise-aks-cluster'
  scope: customerManagedRG
  params: {
    managedResourceGroup: managedResourceGroup
    kubernetesClusterName: kubernetesClusterName
    kubernetesClusterVersion: kubernetesClusterVersion
    virtualNetwork: virtualNetwork
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    subnet: nodesSubnet
  }
}








