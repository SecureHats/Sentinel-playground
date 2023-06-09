// Parameters
@description('Specifies the name of the Data Collection Rule to create.')
param dataCollectionRuleName string = 'SecurityAlert'

@description('Name of the Log Analytics workspace.')
param workspaceName string

@description('Location of the Log Analytics workspace')
param location string = resourceGroup().location

@description('Specifies the name of the Data Collection Endpoint to create')
param dataCollectionEndpointName string = 'SecurityAlert'

@description('Specifies the name of the Custom Log Table for data ingestion')
param customLogTable string = 'SecurityAlert'

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
            name: 'AlertLink'
            type: 'string'
          }	
          {
            name: 'AlertName' 
            type: 'string'
          }
          {
            name: 'AlertSeverity' 
            type: 'string'
          }
          {
            name: 'AlertType' 
            type: 'string'
          }
          {
            name: 'BilledSize'
            type: 'real'
          }
          {
            name: 'CompromisedEntity' 
            type: 'string'
          }	
          {
            name: 'ConfidenceLevel' 
            type: 'string'
          }
          
          {
            name: 'ConfidenceScore'
            type: 'real'
          }	
          {
            name: 'Description' 
            type: 'string'
          }
          
          {
            name: 'DisplayName' 
            type: 'string'
          }	
          {
            name: 'EndTime'
            type:	'datetime'
          }	
          {
            name: 'Entities' 
            type: 'string'
          }	
          {
            name: 'ExtendedLinks' 
            type: 'string'
          }	
          {
            name: 'ExtendedProperties' 
            type: 'string'
          }
          {
            name: '_IsBillable' 
            type: 'string'
          }
          {
            name: 'IsIncident'
            type:	'boolean'
          }	
          {
            name: 'ProcessingEndTime'
            type: 'datetime'
          }	
          {
            name: 'ProductComponentName' 
            type: 'string'
          }	
          {
            name: 'ProductName' 
            type: 'string'
          }	
          {
            name: 'ProviderName' 
            type: 'string'
          }
          {
            name: 'RemediationSteps' 
            type: 'string'
          }
          {
            name: 'ResourceId' 
            type: 'string'
          }
          {
            name: 'SourceComputerId' 
            type: 'string'
          }
          {
            name: 'StartTime'
            type:	'datetime'
          }	
          {
            name: 'Status'
            type: 'string'
          }
          {
            name: 'SystemAlertId' 
            type: 'string'
          }
          {
            name: 'Tactics' 
            type: 'string'
          }	
          {
            name: 'Techniques' 
            type: 'string'
          }
          {
            name: 'TimeGenerated'
            type: 'datetime'
          }	
          {
            name: 'Type' 
            type: 'string'
          }
          {
            name: 'VendorName' 
            type: 'string'
          }
          {
            name: 'VendorOriginalId' 
            type: 'string'
          }	
          {
            name: 'WorkspaceResourceGroup' 
            type: 'string'
          }	
          {
            name: 'WorkspaceSubscriptionId' 
            type: 'string'
          }
          {
            name: 'SourceSystem'
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
        outputStream: 'Microsoft-SecurityAlert'
        transformKql: 'source | extend TimeGenerated = now()'
      }
    ]
  }
}

output dataCollectionEndpoint string = dce.properties.logsIngestion.endpoint
output immutableId string = dce.properties.immutableId
output endpointUri string = '${dce.properties.logsIngestion.endpoint}/dataCollectionRules/${dcr.properties.immutableId}/streams/${customTable}?api-version=2021-11-01-preview'
