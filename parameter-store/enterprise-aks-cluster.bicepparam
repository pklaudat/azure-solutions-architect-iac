using '../enterprise-aks-cluster/main.bicep'

param kubernetesClusterName = 'aks-dev'
param kubernetesClusterVersion = '1.29.9'
param virtualNetworkResourceGroup = 'RG_NETWORK-CENTRALUS'
param virtualNetwork = ''
param nodesSubnet = 'K8sNodesSubnet'
param managedResourceGroup = ''
