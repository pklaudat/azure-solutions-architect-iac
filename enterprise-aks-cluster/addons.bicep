targetScope = 'resourceGroup'

param aksclustername string = 'pk8scluster'

module installArgoCd 'helm-install.bicep' = {
  name: 'install-argocd'
  params: {
    helmRepositoryUrl: 'https://argoproj.github.io/argo-helm'
    helmRepositoryName: 'argo'
    helmPackageName: 'argo-cd'
    clusterName: aksclustername
    clusterNamespace: 'argo-cd'
    packageName: 'argo-cd'
    values: {
      server: {
        ingress: {
          enabled: true
          ingressClassName: 'webapprouting.kubernetes.azure.com'
        }
      }
    }
  }
}


