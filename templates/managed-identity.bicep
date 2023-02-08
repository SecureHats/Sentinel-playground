@description('Name of the managed identity')
param managedIdentityName string

@description('Either create new or use existing user-assigned managed identity')
param newManagedIdentity bool = false

@description('Location of the resource group')
param location string = resourceGroup().location

@allowed([
  'Owner'
  'Contributor'
  'Reader'
])

@description('Built-in role to assign')
param builtInRoleType string = 'Contributor'

var roleDefinitionId = {
  Owner: {
    id: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  }
  Contributor: {
    id: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  }
  Reader: {
    id: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  }
}
var identityName = (newManagedIdentity ? '${managedIdentityName}-${location}' : managedIdentityName)

resource managedidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource resourceRole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (newManagedIdentity ? bool('true') : bool('false')) {
  name: guid(resourceGroup().id, identityName, roleDefinitionId[builtInRoleType].id)
  properties: {
    roleDefinitionId: roleDefinitionId[builtInRoleType].id
    principalId: reference(managedidentity.id, '2018-11-30', 'Full').properties.principalId
  }
}
