
@description('name of the Log Analytics workspace')
param workspaceName string

@description('deployment location for the resource')
param location string = resourceGroup().location

@description('Log Analytics workspace')
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
name: workspaceName
}

var resourceId = '/subscriptions/${subscription().subscriptionId}/providers/microsoft.insights/eventtypes/management'

resource SecurityInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspaceName})'
  location: location
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: workspace.id
  }
}

resource workspaceName_subscriptionId 'Microsoft.OperationalInsights/workspaces/dataSources@2020-03-01-preview' = {
  parent: workspace
  name: replace(subscription().subscriptionId, '-', '')
  kind: 'AzureActivityLog'
  properties: {
    linkedResourceId: resourceId
  }
}

resource workspaceName_SecurityInsightsSecurityEventCollectionConfiguration 'Microsoft.OperationalInsights/workspaces/dataSources@2020-03-01-preview' = {
  parent: workspace
  name: 'SecurityInsightsSecurityEventCollectionConfiguration'
  kind: 'SecurityInsightsSecurityEventCollectionConfiguration'
  properties: {
    tier: 'All'
    tierSetMethod: 'Custom'
  }
}
