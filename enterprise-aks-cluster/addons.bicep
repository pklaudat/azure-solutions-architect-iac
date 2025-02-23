targetScope = 'resourceGroup'

param aksclustername string = 'pk8scluster'

param gitRepoUrl string = 'https://github.com/pklaudat/azure-bicep-core.git'

param gitBranch string = 'main'


resource cluster 'Microsoft.ContainerService/managedClusters@2024-09-02-preview' existing = {
  name: aksclustername
}

// flux will be used to maintain the infrastructure layer
resource enableNativeGitops 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  name: 'flux-system'
  scope: cluster
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
  }
}

// argo-cd provides application layer gitops
resource installArgoCd 'Microsoft.KubernetesConfiguration/fluxConfigurations@2024-04-01-preview' = {
  name: 'argo-cd'
  scope: cluster
  properties: {
    namespace: 'argo-cd'
    sourceKind: 'GitRepository'
    gitRepository: {
      url: gitRepoUrl
      repositoryRef: {
        branch: gitBranch
      }
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
    }
    kustomizations: {
      'argo-cd': {
        path: './enterprise-aks-cluster/addons/argo-cd'
        prune: true
        wait: true
        syncIntervalInSeconds: 600
      }
    }
  }
  dependsOn: [ enableNativeGitops ]
}


