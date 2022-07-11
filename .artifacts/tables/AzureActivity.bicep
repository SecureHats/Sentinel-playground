// Parameters
@description('Specifies the name of the Data Collection Rule to create.')
param dataCollectionRuleName string

@description('Name of the Log Analytics workspace.')
param workspaceName string

@description('Location of the Log Analytics workspace')
param location string = resourceGroup().location

@description('Specifies the name of the Data Collection Endpoint to create')
param dataCollectionEndpointName string

@description('Specifies the name of the Custom Log Table for data ingestion')
param customLogTable string

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: workspaceName
}

//  Variables
var customTable = 'Custom-${customLogTable}'

// Resources
resource dce 'Microsoft.Insights/dataCollectionEndpoints@2021-04-01' = {
  name: dataCollectionEndpointName
  location: location
  properties:{
    networkAcls:{
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource dcr 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  name: dataCollectionRuleName
  location: location
  properties: {
    dataCollectionEndpointId: dce.id
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspace.id
          name: workspace.name
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          customTable
        ]
        destinations: [
          workspace.name
        ]
      outputStream: customTable
      transformKql: 'source | extend TimeGenerated = now()'
      }
    ]
  }
}

resource table 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  name: '${workspaceName}/${customLogTable}'
  properties: {
    schema: {
      name: customLogTable
      columns: [
        {
          name: 'SourceSystem'
          type: 'string'
        }
        {
          name: 'CallerIpAddress'
          type: 'string'
        }
        {
          name: 'CategoryValue'
          type: 'string'
        }
        {
          name: 'CorrelationId'
          type: 'string'
        }
        {
          name: 'Authorization'
          type: 'string'
        }
        {
          name: 'Authorization_d'
          type: 'dynamic'
        }
        {
          name: 'Claims'
          type: 'string'
        }
        {
          name: 'Claims_d'
          type: 'dynamic'
        }
        {
          name: 'Level'
          type: 'string'
        }
        {
          name: 'OperationNameValue'
          type: 'string'
        }
        {
          name: 'Properties'
          type: 'string'
        }
        {
          name: 'Properties_d'
          type: 'dynamic'
        }
        {
          name: 'Caller'
          type: 'string'
        }
        {
          name: 'EventDataId'
          type: 'string'
        }
        {
          name: 'EventSubmissionTimestamp'
          type: 'datetime'
        }
        {
          name: 'HTTPRequest'
          type: 'string'
        }
        {
          name: 'OperationId'
          type: 'string'
        }
        {
          name: 'ResourceGroup'
          type: 'string'
        }
        {
          name: 'ResourceProviderValue'
          type: 'string'
        }
        {
          name: 'ActivityStatusValue'
          type: 'string'
        }
        {
          name: 'ActivitySubstatusValue'
          type: 'string'
        }
        {
          name: 'Hierarchy'
          type: 'string'
        }
        {
          name: 'TimeGenerated'
          type: 'datetime'
        }
        {
          name: 'SubscriptionId'
          type: 'string'
        }
        {
          name: 'OperationName'
          type: 'string'
        }
        {
          name: 'ActivityStatus'
          type: 'string'
        }
        {
          name: 'ActivitySubstatus'
          type: 'string'
        }
        {
          name: 'Category'
          type: 'string'
        }
        {
          name: 'ResourceId'
          type: 'string'
        }
        {
          name: 'ResourceProvider'
          type: 'string'
        }
        {
          name: 'Resource'
          type: 'string'
        }
        {
          name: '_ResourceId'
          type: 'string'
        }
      ]
    }
  }
}

// Outputs
output dataCollectionEndpoint string = dce.properties.logsIngestion.endpoint
output immutableId string = dce.properties.immutableId
output endpointUri string = '${dce.properties.logsIngestion.endpoint}/dataCollectionRules/${dcr.properties.immutableId}/streams/${customTable}?api-version=2021-11-01-preview'
