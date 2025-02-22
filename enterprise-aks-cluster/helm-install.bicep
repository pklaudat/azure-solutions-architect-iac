param clusterName string

param clusterNamespace string

param packageName string

param helmRepositoryName string

param helmPackageName string

param helmRepositoryUrl string

param timeNow string = utcNow()

param values object

var scriptContent = 'az aks command invoke --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --command "helm repo add ${helmRepositoryName} ${helmRepositoryUrl} && helm repo update && helm install argo ${helmRepositoryName}/${helmPackageName} --namespace ${clusterNamespace} --create-namespace"'

var kubernetesServiceClusterRBACAdmin = 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
var kubernetesContributorRole = 'ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8'

resource helmInstallManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: 'identity-helm-install'
  location: resourceGroup().location
}

resource clusterAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in [kubernetesServiceClusterRBACAdmin, kubernetesContributorRole]: {
    name: guid(resourceGroup().name, clusterName, role, 'helm')
    properties: {
      principalId: helmInstallManagedIdentity.properties.principalId
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role)
      principalType: 'ServicePrincipal'
    }
  }
]

resource helmRelease 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'helm-install-${packageName}'
  location: resourceGroup().location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${helmInstallManagedIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.60.0'
    retentionInterval: 'P1D'
    forceUpdateTag: timeNow
    scriptContent: scriptContent
    cleanupPreference: 'Always'
    environmentVariables: [
      {
        name: 'RESOURCE_GROUP'
        value: resourceGroup().name
      }
      {
        name: 'CLUSTER_NAME'
        value: clusterName
      }
    ]
  }
  dependsOn: [clusterAccess]
}
