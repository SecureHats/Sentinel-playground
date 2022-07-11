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
          name: 'Activity'
          type: 'string'
        }
        {
          name: 'AdditionalContext'
          type: 'string'
        }
        {
          name: 'ApplicationProtocol'
          type: 'string'
        }
        {
          name: 'CommunicationDirection'
          type: 'string'
        }
        {
          name: 'Computer'
          type: 'string'
        }
        {
          name: 'DestinationDnsDomain'
          type: 'string'
        }
        {
          name: 'DestinationHostName'
          type: 'string'
        }
        {
          name: 'DestinationIP'
          type: 'string'
        }
        {
          name: 'DestinationMACAddress'
          type: 'string'
        }
        {
          name: 'DestinationNTDomain'
          type: 'string'
        }
        {
          name: 'DestinationPort'
          type: 'int'
        }
        {
          name: 'DestinationProcessId'
          type: 'int'
        }
        {
          name: 'DestinationProcessName'
          type: 'string'
        }
        {
          name: 'DestinationServiceName'
          type: 'string'
        }
        {
          name: 'DestinationTranslatedAddress'
          type: 'string'
        }
        {
          name: 'DestinationTranslatedPort'
          type: 'int'
        }
        {
          name: 'DestinationUserID'
          type: 'string'
        }
        {
          name: 'DestinationUserName'
          type: 'string'
        }
        {
          name: 'DestinationUserPrivileges'
          type: 'string'
        }
        {
          name: 'DeviceAction'
          type: 'string'
        }
        {
          name: 'DeviceAddress'
          type: 'string'
        }
        {
          name: 'DeviceCustomDate1'
          type: 'string'
        }
        {
          name: 'DeviceCustomDate1Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomDate2'
          type: 'string'
        }
        {
          name: 'DeviceCustomDate2Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomFloatingPoint1'
          type: 'real'
        }
        {
          name: 'DeviceCustomFloatingPoint1Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomFloatingPoint2'
          type: 'real'
        }
        {
          name: 'DeviceCustomFloatingPoint2Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomFloatingPoint3'
          type: 'real'
        }
        {
          name: 'DeviceCustomFloatingPoint3Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomFloatingPoint4'
          type: 'real'
        }
        {
          name: 'DeviceCustomFloatingPoint4Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomIPv6Address1'
          type: 'string'
        }
        {
          name: 'DeviceCustomIPv6Address1Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomIPv6Address2'
          type: 'string'
        }
        {
          name: 'DeviceCustomIPv6Address2Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomIPv6Address3'
          type: 'string'
        }
        {
          name: 'DeviceCustomIPv6Address3Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomIPv6Address4'
          type: 'string'
        }
        {
          name: 'DeviceCustomIPv6Address4Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomNumber1'
          type: 'int'
        }
        {
          name: 'DeviceCustomNumber1Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomNumber2'
          type: 'int'
        }
        {
          name: 'DeviceCustomNumber2Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomNumber3'
          type: 'int'
        }
        {
          name: 'DeviceCustomNumber3Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomString1'
          type: 'string'
        }
        {
          name: 'DeviceCustomString1Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomString2'
          type: 'string'
        }
        {
          name: 'DeviceCustomString2Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomString3'
          type: 'string'
        }
        {
          name: 'DeviceCustomString3Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomString4'
          type: 'string'
        }
        {
          name: 'DeviceCustomString4Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomString5'
          type: 'string'
        }
        {
          name: 'DeviceCustomString5Label'
          type: 'string'
        }
        {
          name: 'DeviceCustomString6'
          type: 'string'
        }
        {
          name: 'DeviceCustomString6Label'
          type: 'string'
        }
        {
          name: 'DeviceDnsDomain'
          type: 'string'
        }
        {
          name: 'DeviceEventClassID'
          type: 'string'
        }
        {
          name: 'DeviceExternalID'
          type: 'string'
        }
        {
          name: 'DeviceFacility'
          type: 'string'
        }
        {
          name: 'DeviceInboundInterface'
          type: 'string'
        }
        {
          name: 'DeviceMacAddress'
          type: 'string'
        }
        {
          name: 'DeviceName'
          type: 'string'
        }
        {
          name: 'DeviceNtDomain'
          type: 'string'
        }
        {
          name: 'DeviceOutboundInterface'
          type: 'string'
        }
        {
          name: 'DevicePayloadId'
          type: 'string'
        }
        {
          name: 'DeviceProduct'
          type: 'string'
        }
        {
          name: 'DeviceTimeZone'
          type: 'string'
        }
        {
          name: 'DeviceTranslatedAddress'
          type: 'string'
        }
        {
          name: 'DeviceVendor'
          type: 'string'
        }
        {
          name: 'DeviceVersion'
          type: 'string'
        }
        {
          name: 'EndTime'
          type: 'datetime'
        }
        {
          name: 'EventCount'
          type: 'int'
        }
        {
          name: 'EventType'
          type: 'int'
        }
        {
          name: 'ExternalID'
          type: 'int'
        }
        {
          name: 'FileCreateTime'
          type: 'string'
        }
        {
          name: 'FileHash'
          type: 'string'
        }
        {
          name: 'FileID'
          type: 'string'
        }
        {
          name: 'FileModificationTime'
          type: 'string'
        }
        {
          name: 'FileName'
          type: 'string'
        }
        {
          name: 'FilePath'
          type: 'string'
        }
        {
          name: 'FilePermission'
          type: 'string'
        }
        {
          name: 'FileSize'
          type: 'int'
        }
        {
          name: 'FileType'
          type: 'string'
        }
        {
          name: 'FlexDate1'
          type: 'string'
        }
        {
          name: 'FlexDate1Label'
          type: 'string'
        }
        {
          name: 'FlexNumber1'
          type: 'int'
        }
        {
          name: 'FlexNumber1Label'
          type: 'string'
        }
        {
          name: 'FlexNumber2'
          type: 'int'
        }
        {
          name: 'FlexNumber2Label'
          type: 'string'
        }
        {
          name: 'FlexString1'
          type: 'string'
        }
        {
          name: 'FlexString1Label'
          type: 'string'
        }
        {
          name: 'FlexString2'
          type: 'string'
        }
        {
          name: 'FlexString2Label'
          type: 'string'
        }
        {
          name: 'IndicatorThreatType'
          type: 'string'
        }
        {
          name: 'LogSeverity'
          type: 'string'
        }
        {
          name: 'MaliciousIP'
          type: 'string'
        }
        {
          name: 'MaliciousIPCountry'
          type: 'string'
        }
        {
          name: 'MaliciousIPLatitude'
          type: 'real'
        }
        {
          name: 'MaliciousIPLongitude'
          type: 'real'
        }
        {
          name: 'Message'
          type: 'string'
        }
        {
          name: 'OldFileCreateTime'
          type: 'string'
        }
        {
          name: 'OldFileHash'
          type: 'string'
        }
        {
          name: 'OldFileID'
          type: 'string'
        }
        {
          name: 'OldFileModificationTime'
          type: 'string'
        }
        {
          name: 'OldFileName'
          type: 'string'
        }
        {
          name: 'OldFilePath'
          type: 'string'
        }
        {
          name: 'OldFilePermission'
          type: 'string'
        }
        {
          name: 'OldFileSize'
          type: 'int'
        }
        {
          name: 'OldFileType'
          type: 'string'
        }
        {
          name: 'OriginalLogSeverity'
          type: 'string'
        }
        {
          name: 'ProcessID'
          type: 'int'
        }
        {
          name: 'ProcessName'
          type: 'string'
        }
        {
          name: 'Protocol'
          type: 'string'
        }
        {
          name: 'ReceiptTime'
          type: 'string'
        }
        {
          name: 'ReceivedBytes'
          type: 'long'
        }
        {
          name: 'RemoteIP'
          type: 'string'
        }
        {
          name: 'RemotePort'
          type: 'string'
        }
        {
          name: 'RequestClientApplication'
          type: 'string'
        }
        {
          name: 'RequestContext'
          type: 'string'
        }
        {
          name: 'RequestCookies'
          type: 'string'
        }
        {
          name: 'RequestMethod'
          type: 'string'
        }
        {
          name: 'RequestURL'
          type: 'string'
        }
        {
          name: 'SentBytes'
          type: 'long'
        }
        {
          name: 'SimplifiedDeviceAction'
          type: 'string'
        }
        {
          name: 'SourceDnsDomain'
          type: 'string'
        }
        {
          name: 'SourceHostName'
          type: 'string'
        }
        {
          name: 'SourceIP'
          type: 'string'
        }
        {
          name: 'SourceMACAddress'
          type: 'string'
        }
        {
          name: 'SourceNTDomain'
          type: 'string'
        }
        {
          name: 'SourcePort'
          type: 'int'
        }
        {
          name: 'SourceProcessId'
          type: 'int'
        }
        {
          name: 'SourceProcessName'
          type: 'string'
        }
        {
          name: 'SourceServiceName'
          type: 'string'
        }
        {
          name: 'SourceSystem'
          type: 'string'
        }
        {
          name: 'SourceTranslatedAddress'
          type: 'string'
        }
        {
          name: 'SourceTranslatedPort'
          type: 'int'
        }
        {
          name: 'SourceUserID'
          type: 'string'
        }
        {
          name: 'SourceUserName'
          type: 'string'
        }
        {
          name: 'SourceUserPrivileges'
          type: 'string'
        }
        {
          name: 'StartTime'
          type: 'datetime'
        }
        {
          name: 'ThreatConfidence'
          type: 'string'
        }
        {
          name: 'ThreatDescription'
          type: 'string'
        }
        {
          name: 'ThreatSeverity'
          type: 'int'
        }
        {
          name: 'TimeGenerated'
          type: 'datetime'
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
