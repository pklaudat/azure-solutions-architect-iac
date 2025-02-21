targetScope = 'subscription'

@description('Kubernetes cluster name.')
param kubernetesClusterName string


@description('Kubernetes cluster version.')
@allowed(['1.30.0'])
param kubernetesClusterVersion string

@allowed(['standard'])
@description('SKU for the load balancer provisioned to support the k8s control plane entrypoint.')
param kubeApiLoadBalancerSku string = 'standard'

@allowed(['overlay'])
@description('Network Plugin being used to the Container networking interface.')
param networkPluginMode string = 'overlay'

@description('Kubernetes Service CIDR.')
param kubernetesServiceCidr string

@description('DNS Server IP address for k8s service.')
param kubernetesDnsServiceIp string

@description('Resource group where the virtual network is deployed.')
param virtualNetworkResourceGroup string

@description('Virtual network name that the AKS service will consume to host the nodes.')
param virtualNetwork string

@description('Subnet name being used to deploy the AKS nodes.')
param nodesSubnet string

@description('Managed resource group to deploy the AKS managed resources, such as load balancer, public ip, private dns zones etc.')
param managedResourceGroup string = 'RG_ENTERPRISE_AKS_MANAGED'


var location = deployment().location



resource customerManagedRG 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'RG_ENTERPRISE_AKS-${location}'
  location: location
  tags: loadJsonContent('../metadata.json')
  properties: {}
}

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
    kubeApiLoadBalancerSku: kubeApiLoadBalancerSku
    kubernetesDnsServiceIp: kubernetesDnsServiceIp
    kubernetesServiceCidr: kubernetesServiceCidr
    networkPluginMode: networkPluginMode
  }
}








