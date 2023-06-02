@description('Specifies the name of the Data Collection Rule to create.')
param dataCollectionRuleName string = 'AuditLogs'

@description('Name of the Log Analytics workspace.')
param workspaceName string

@description('Location of the Log Analytics workspace')
param location string = resourceGroup().location

@description('Specifies the name of the Data Collection Endpoint to create')
param dataCollectionEndpointName string = 'AuditLogs'

@description('Specifies the name of the Custom Log Table for data ingestion')
param customLogTable string = 'LogCollection'

var customTable = 'Custom-${customLogTable}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: workspaceName
}

resource dce 'Microsoft.Insights/dataCollectionEndpoints@2021-04-01' = {
  name: dataCollectionEndpointName
  location: location
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource dcr 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  name: dataCollectionRuleName
  location: location
  properties: {
    dataCollectionEndpointId: dce.id
    streamDeclarations: {
      '${customTable}': {
        columns: [
          {
            name: 'TenantId'
            type: 'string'
        }
        {
            name: 'SourceSystem'
            type: 'string'
        }
        {
            name: 'TimeGenerated'
            type: 'datetime'
        }
        {
            name: 'ResourceId'
            type: 'string'
        }
        {
            name: 'OperationName'
            type: 'string'
        }
        {
            name: 'OperationVersion'
            type: 'string'
        }
        {
            name: 'Category'
            type: 'string'
        }
        {
            name: 'ResultType'
            type: 'string'
        }
        {
            name: 'ResultSignature'
            type: 'string'
        }
        {
            name: 'ResultDescription'
            type: 'string'
        }
        {
            name: 'DurationMs'
            type: 'long'
        }
        {
            name: 'CorrelationId'
            type: 'string'
        }
        {
            name: 'Resource'
            type: 'string'
        }
        {
            name: 'ResourceGroup'
            type: 'string'
        }
        {
            name: 'ResourceProvider'
            type: 'string'
        }
        {
            name: 'Identity'
            type: 'string'
        }
        {
            name: 'Level'
            type: 'string'
        }
        {
            name: 'Location'
            type: 'string'
        }
        {
            name: 'AdditionalDetails'
            type: 'dynamic'
        }
        {
            name: 'Id'
            type: 'string'
        }
        {
            name: 'InitiatedBy'
            type: 'dynamic'
        }
        {
            name: 'LoggedByService'
            type: 'string'
        }
        {
            name: 'Result'
            type: 'string'
        }
        {
            name: 'ResultReason'
            type: 'string'
        }
        {
            name: 'TargetResources'
            type: 'dynamic'
        }
        {
            name: 'AADTenantId'
            type: 'string'
        }
        {
            name: 'ActivityDisplayName'
            type: 'string'
        }
        {
            name: 'Activitydatetime'
            type: 'datetime'
        }
        {
            name: 'AADOperationType'
            type: 'string'
        }
        {
            name: 'Type'
            type: 'string'
        }
        ]
      }
    }
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
        outputStream: 'Microsoft-AuditLogs'
        transformKql: 'source | extend TimeGenerated = now()'
      }
    ]
  }
}

output dataCollectionEndpoint string = dce.properties.logsIngestion.endpoint
output immutableId string = dce.properties.immutableId
output endpointUri string = '${dce.properties.logsIngestion.endpoint}/dataCollectionRules/${dcr.properties.immutableId}/streams/${customTable}?api-version=2021-11-01-preview'
