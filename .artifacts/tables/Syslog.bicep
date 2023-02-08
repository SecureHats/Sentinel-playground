@description('Specifies the name of the Data Collection Rule to create.')
param dataCollectionRuleName string = 'Syslog'

@description('Name of the Log Analytics workspace.')
param workspaceName string

@description('Location of the Log Analytics workspace')
param location string = resourceGroup().location

@description('Specifies the name of the Data Collection Endpoint to create')
param dataCollectionEndpointName string = 'Syslog'

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
            name: 'SourceSystem' 
            type: 'string'
        }
        {
            name: 'TimeGenerated' 
            type: 'datetime'
        }
        {
            name: 'Computer' 
            type: 'string'
        }
        {
            name: 'EventTime' 
            type: 'datetime'
        }
        {
            name: 'Facility' 
            type: 'string'
        }
        {
            name: 'HostName' 
            type: 'string'
        }
        {
            name: 'SeverityLevel' 
            type: 'string'
        }
        {
            name: 'SyslogMessage' 
            type: 'string'
        }
        {
            name: 'ProcessID' 
            type: 'int'
        }
        {
            name: 'HostIP' 
            type: 'string'
        }
        {
            name: 'ProcessName' 
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
        outputStream: 'Microsoft-Syslog'
        transformKql: 'source | extend TimeGenerated = now()'
      }
    ]
  }
}

output dataCollectionEndpoint string = dce.properties.logsIngestion.endpoint
output immutableId string = dce.properties.immutableId
output endpointUri string = '${dce.properties.logsIngestion.endpoint}/dataCollectionRules/${dcr.properties.immutableId}/streams/${customTable}?api-version=2021-11-01-preview'
