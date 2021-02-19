param location string {
  default: resourceGroup().location
}

param logAnalyticsWorkspaceName string = 'la-${uniqueString(resourceGroup().id)}'

var SecurityInsights = {
  name: 'SecurityInsights(${logAnalyticsWorkspaceName})'
}

var environmentName = 'Development'
var costCenterName = 'IT'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: {
    Environment: environmentName
    CostCenter: costCenterName
  }
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
      immediatePurgeDataOn30Days: true
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource Sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: SecurityInsights.name
  location: location
  dependsOn: [
    logAnalyticsWorkspace
  ]
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: SecurityInsights.name
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
}
