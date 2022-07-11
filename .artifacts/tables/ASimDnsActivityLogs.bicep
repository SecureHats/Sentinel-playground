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
        [
  {
    name: "TimeGenerated"
    type: "datetime"
  }
  {
    name: "EventCount"
    type: "int"
  }
  {
    name: "EventType"
    type: "string"
  }
  {
    name: "EventSubType"
    type: "string"
  }
  {
    name: "EventResult"
    type: "string"
  }
  {
    name: "EventResultDetails"
    type: "string"
  }
  {
    name: "EventOriginalType"
    type: "string"
  }
  {
    name: "EventProduct"
    type: "string"
  }
  {
    name: "EventVendor"
    type: "string"
  }
  {
    name: "DvcIpAddr"
    type: "string"
  }
  {
    name: "DvcHostname"
    type: "string"
  }
  {
    name: "DvcDomain"
    type: "string"
  }
  {
    name: "DvcDomainType"
    type: "string"
  }
  {
    name: "DvcOs"
    type: "string"
  }
  {
    name: "DvcOsVersion"
    type: "string"
  }
  {
    name: "AdditionalFields"
    type: "dynamic"
  }
  {
    name: "SrcIpAddr"
    type: "string"
  }
  {
    name: "SrcPortNumber"
    type: "int"
  }
  {
    name: "DstIpAddr"
    type: "string"
  }
  {
    name: "DnsQuery"
    type: "string"
  }
  {
    name: "DnsQueryType"
    type: "int"
  }
  {
    name: "DnsQueryTypeName"
    type: "string"
  }
  {
    name: "DnsResponseCode"
    type: "int"
  }
  {
    name: "TransactionIdHex"
    type: "string"
  }
  {
    name: "NetworkProtocol"
    type: "string"
  }
  {
    name: "DnsQueryClass"
    type: "int"
  }
  {
    name: "DnsQueryClassName"
    type: "string"
  }
  {
    name: "DnsNetworkDuration"
    type: "int"
  }
  {
    name: "DnsFlagsAuthenticated"
    type: "bool"
  }
  {
    name: "DnsFlagsAuthoritative"
    type: "bool"
  }
  {
    name: "DnsFlagsRecursionDesired"
    type: "bool"
  }
  {
    name: "DnsSessionId"
    type: "string"
  }
  {
    name: "EventMessage"
    type: "string"
  }
  {
    name: "EventOriginalUid"
    type: "string"
  }
  {
    name: "EventReportUrl"
    type: "string"
  }
  {
    name: "DvcFQDN"
    type: "string"
  }
  {
    name: "DvcId"
    type: "string"
  }
  {
    name: "DvcIdType"
    type: "string"
  }
  {
    name: "SrcHostname"
    type: "string"
  }
  {
    name: "SrcDomain"
    type: "string"
  }
  {
    name: "SrcDomainType"
    type: "string"
  }
  {
    name: "SrcFQDN"
    type: "string"
  }
  {
    name: "SrcDvcId"
    type: "string"
  }
  {
    name: "SrcDvcIdType"
    type: "string"
  }
  {
    name: "SrcDeviceType"
    type: "string"
  }
  {
    name: "SrcUserId"
    type: "string"
  }
  {
    name: "SrcUserIdType"
    type: "string"
  }
  {
    name: "SrcUsername"
    type: "string"
  }
  {
    name: "SrcUsernameType"
    type: "string"
  }
  {
    name: "SrcUserType"
    type: "string"
  }
  {
    name: "SrcOriginalUserType"
    type: "string"
  }
  {
    name: "SrcProcessName"
    type: "string"
  }
  {
    name: "SrcProcessId"
    type: "string"
  }
  {
    name: "SrcProcessGuid"
    type: "string"
  }
  {
    name: "DstPortNumber"
    type: "int"
  }
  {
    name: "DstHostname"
    type: "string"
  }
  {
    name: "DstDomain"
    type: "string"
  }
  {
    name: "DstDomainType"
    type: "string"
  }
  {
    name: "DstFQDN"
    type: "string"
  }
  {
    name: "DstDvcId"
    type: "string"
  }
  {
    name: "DstDvcIdType"
    type: "string"
  }
  {
    name: "DstDeviceType"
    type: "string"
  }
  {
    name: "UrlCategory"
    type: "string"
  }
  {
    name: "ThreatCategory"
    type: "string"
  }
  {
    name: "DvcAction"
    type: "string"
  }
  {
    name: "DnsFlagsCheckingDisabled"
    type: "bool"
  }
  {
    name: "DnsFlagsRecursionAvailable"
    type: "bool"
  }
  {
    name: "DnsFlagsTruncates"
    type: "bool"
  }
  {
    name: "DnsFlagsZ"
    type: "bool"
  }
  {
    name: "SourceSystem"
    type: "string"
  }
  {
    name: "_ResourceId"
    type: "string"
  }
]
    }
  }
}

// Outputs
output dataCollectionEndpoint string = dce.properties.logsIngestion.endpoint
output immutableId string = dce.properties.immutableId
output endpointUri string = '${dce.properties.logsIngestion.endpoint}/dataCollectionRules/${dcr.properties.immutableId}/streams/${customTable}?api-version=2021-11-01-preview'
