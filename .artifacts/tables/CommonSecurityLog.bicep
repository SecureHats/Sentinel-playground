@description('Specifies the name of the Data Collection Rule to create.')
param dataCollectionRuleName string = 'CommonSecurityLog'

@description('Name of the Log Analytics workspace.')
param workspaceName string

@description('Location of the Log Analytics workspace')
param location string = resourceGroup().location

@description('Specifies the name of the Data Collection Endpoint to create')
param dataCollectionEndpointName string = 'CommonSecurityLog'

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
            type: 'datetime'
            name: 'TimeGenerated'
          }
          {
            type: 'string'
            name: 'DeviceVendor'
          }
          {
            type: 'string'
            name: 'DeviceProduct'
          }
          {
            type: 'string'
            name: 'DeviceVersion'
          }
          {
            type: 'string'
            name: 'DeviceEventClassID'
          }
          {
            type: 'string'
            name: 'Activity'
          }
          {
            type: 'string'
            name: 'LogSeverity'
          }
          {
            type: 'string'
            name: 'OriginalLogSeverity'
          }
          {
            type: 'string'
            name: 'AdditionalExtensions'
          }
          {
            type: 'string'
            name: 'DeviceAction'
          }
          {
            type: 'string'
            name: 'ApplicationProtocol'
          }
          {
            type: 'int'
            name: 'EventCount'
          }
          {
            type: 'string'
            name: 'DestinationDnsDomain'
          }
          {
            type: 'string'
            name: 'DestinationServiceName'
          }
          {
            type: 'string'
            name: 'DestinationTranslatedAddress'
          }
          {
            type: 'int'
            name: 'DestinationTranslatedPort'
          }
          {
            type: 'string'
            name: 'CommunicationDirection'
          }
          {
            type: 'string'
            name: 'DeviceDnsDomain'
          }
          {
            type: 'string'
            name: 'DeviceExternalID'
          }
          {
            type: 'string'
            name: 'DeviceFacility'
          }
          {
            type: 'string'
            name: 'DeviceInboundInterface'
          }
          {
            type: 'string'
            name: 'DeviceNtDomain'
          }
          {
            type: 'string'
            name: 'DeviceOutboundInterface'
          }
          {
            type: 'string'
            name: 'DevicePayloadId'
          }
          {
            type: 'string'
            name: 'ProcessName'
          }
          {
            type: 'string'
            name: 'DeviceTranslatedAddress'
          }
          {
            type: 'string'
            name: 'DestinationHostName'
          }
          {
            type: 'string'
            name: 'DestinationMACAddress'
          }
          {
            type: 'string'
            name: 'DestinationNTDomain'
          }
          {
            type: 'int'
            name: 'DestinationProcessId'
          }
          {
            type: 'string'
            name: 'DestinationUserPrivileges'
          }
          {
            type: 'string'
            name: 'DestinationProcessName'
          }
          {
            type: 'int'
            name: 'DestinationPort'
          }
          {
            type: 'string'
            name: 'DestinationIP'
          }
          {
            type: 'string'
            name: 'DeviceTimeZone'
          }
          {
            type: 'string'
            name: 'DestinationUserID'
          }
          {
            type: 'string'
            name: 'DestinationUserName'
          }
          {
            type: 'string'
            name: 'DeviceAddress'
          }
          {
            type: 'string'
            name: 'DeviceName'
          }
          {
            type: 'string'
            name: 'DeviceMacAddress'
          }
          {
            type: 'int'
            name: 'ProcessID'
          }
          {
            type: 'datetime'
            name: 'EndTime'
          }
          {
            type: 'int'
            name: 'ExternalID'
          }
          {
            type: 'string'
            name: 'FileCreateTime'
          }
          {
            type: 'string'
            name: 'FileHash'
          }
          {
            type: 'string'
            name: 'FileID'
          }
          {
            type: 'string'
            name: 'FileModificationTime'
          }
          {
            type: 'string'
            name: 'FilePath'
          }
          {
            type: 'string'
            name: 'FilePermission'
          }
          {
            type: 'string'
            name: 'FileType'
          }
          {
            type: 'string'
            name: 'FileName'
          }
          {
            type: 'int'
            name: 'FileSize'
          }
          {
            type: 'long'
            name: 'ReceivedBytes'
          }
          {
            type: 'string'
            name: 'Message'
          }
          {
            type: 'string'
            name: 'OldFileCreateTime'
          }
          {
            type: 'string'
            name: 'OldFileHash'
          }
          {
            type: 'string'
            name: 'OldFileID'
          }
          {
            type: 'string'
            name: 'OldFileModificationTime'
          }
          {
            type: 'string'
            name: 'OldFileName'
          }
          {
            type: 'string'
            name: 'OldFilePath'
          }
          {
            type: 'string'
            name: 'OldFilePermission'
          }
          {
            type: 'int'
            name: 'OldFileSize'
          }
          {
            type: 'string'
            name: 'OldFileType'
          }
          {
            type: 'long'
            name: 'SentBytes'
          }
          {
            type: 'string'
            name: 'Protocol'
          }
          {
            type: 'string'
            name: 'RequestURL'
          }
          {
            type: 'string'
            name: 'RequestClientApplication'
          }
          {
            type: 'string'
            name: 'RequestContext'
          }
          {
            type: 'string'
            name: 'RequestCookies'
          }
          {
            type: 'string'
            name: 'RequestMethod'
          }
          {
            type: 'string'
            name: 'ReceiptTime'
          }
          {
            type: 'string'
            name: 'SourceHostName'
          }
          {
            type: 'string'
            name: 'SourceMACAddress'
          }
          {
            type: 'string'
            name: 'SourceNTDomain'
          }
          {
            type: 'string'
            name: 'SourceDnsDomain'
          }
          {
            type: 'string'
            name: 'SourceServiceName'
          }
          {
            type: 'string'
            name: 'SourceTranslatedAddress'
          }
          {
            type: 'int'
            name: 'SourceTranslatedPort'
          }
          {
            type: 'int'
            name: 'SourceProcessId'
          }
          {
            type: 'string'
            name: 'SourceUserPrivileges'
          }
          {
            type: 'string'
            name: 'SourceProcessName'
          }
          {
            type: 'int'
            name: 'SourcePort'
          }
          {
            type: 'string'
            name: 'SourceIP'
          }
          {
            type: 'datetime'
            name: 'StartTime'
          }
          {
            type: 'string'
            name: 'SourceUserID'
          }
          {
            type: 'string'
            name: 'SourceUserName'
          }
          {
            type: 'int'
            name: 'EventType'
          }
          {
            type: 'string'
            name: 'DeviceCustomIPv6Address1'
          }
          {
            type: 'string'
            name: 'DeviceCustomIPv6Address1Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomIPv6Address2'
          }
          {
            type: 'string'
            name: 'DeviceCustomIPv6Address2Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomIPv6Address3'
          }
          {
            type: 'string'
            name: 'DeviceCustomIPv6Address3Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomIPv6Address4'
          }
          {
            type: 'string'
            name: 'DeviceCustomIPv6Address4Label'
          }
          {
            type: 'real'
            name: 'DeviceCustomFloatingPoint1'
          }
          {
            type: 'string'
            name: 'DeviceCustomFloatingPoint1Label'
          }
          {
            type: 'real'
            name: 'DeviceCustomFloatingPoint2'
          }
          {
            type: 'string'
            name: 'DeviceCustomFloatingPoint2Label'
          }
          {
            type: 'real'
            name: 'DeviceCustomFloatingPoint3'
          }
          {
            type: 'string'
            name: 'DeviceCustomFloatingPoint3Label'
          }
          {
            type: 'real'
            name: 'DeviceCustomFloatingPoint4'
          }
          {
            type: 'string'
            name: 'DeviceCustomFloatingPoint4Label'
          }
          {
            type: 'int'
            name: 'DeviceCustomNumber1'
          }
          {
            type: 'string'
            name: 'DeviceCustomNumber1Label'
          }
          {
            type: 'int'
            name: 'DeviceCustomNumber2'
          }
          {
            type: 'string'
            name: 'DeviceCustomNumber2Label'
          }
          {
            type: 'int'
            name: 'DeviceCustomNumber3'
          }
          {
            type: 'string'
            name: 'DeviceCustomNumber3Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomString1'
          }
          {
            type: 'string'
            name: 'DeviceCustomString1Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomString2'
          }
          {
            type: 'string'
            name: 'DeviceCustomString2Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomString3'
          }
          {
            type: 'string'
            name: 'DeviceCustomString3Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomString4'
          }
          {
            type: 'string'
            name: 'DeviceCustomString4Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomString5'
          }
          {
            type: 'string'
            name: 'DeviceCustomString5Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomString6'
          }
          {
            type: 'string'
            name: 'DeviceCustomString6Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomDate1'
          }
          {
            type: 'string'
            name: 'DeviceCustomDate1Label'
          }
          {
            type: 'string'
            name: 'DeviceCustomDate2'
          }
          {
            type: 'string'
            name: 'DeviceCustomDate2Label'
          }
          {
            type: 'string'
            name: 'FlexDate1'
          }
          {
            type: 'string'
            name: 'FlexDate1Label'
          }
          {
            type: 'int'
            name: 'FlexNumber1'
          }
          {
            type: 'string'
            name: 'FlexNumber1Label'
          }
          {
            type: 'int'
            name: 'FlexNumber2'
          }
          {
            type: 'string'
            name: 'FlexNumber2Label'
          }
          {
            type: 'string'
            name: 'FlexString1'
          }
          {
            type: 'string'
            name: 'FlexString1Label'
          }
          {
            type: 'string'
            name: 'FlexString2'
          }
          {
            type: 'string'
            name: 'FlexString2Label'
          }
          {
            type: 'string'
            name: 'RemoteIP'
          }
          {
            type: 'string'
            name: 'RemotePort'
          }
          {
            type: 'string'
            name: 'MaliciousIP'
          }
          {
            type: 'int'
            name: 'ThreatSeverity'
          }
          {
            type: 'string'
            name: 'IndicatorThreatType'
          }
          {
            type: 'string'
            name: 'ThreatDescription'
          }
          {
            type: 'string'
            name: 'ThreatConfidence'
          }
          {
            type: 'string'
            name: 'ReportReferenceLink'
          }
          {
            type: 'real'
            name: 'MaliciousIPLongitude'
          }
          {
            type: 'real'
            name: 'MaliciousIPLatitude'
          }
          {
            type: 'string'
            name: 'MaliciousIPCountry'
          }
          {
            type: 'string'
            name: 'Computer'
          }
          {
            type: 'string'
            name: 'SourceSystem'
          }
          {
            type: 'string'
            name: 'SimplifiedDeviceAction'
          }
          {
            type: 'string'
            name: 'Type'
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
        outputStream: 'Microsoft-CommonSecurityLog'
        transformKql: 'source | extend TimeGenerated = now()'
      }
    ]
  }
}

output dataCollectionEndpoint string = dce.properties.logsIngestion.endpoint
output immutableId string = dce.properties.immutableId
output endpointUri string = '${dce.properties.logsIngestion.endpoint}/dataCollectionRules/${dcr.properties.immutableId}/streams/${customTable}?api-version=2021-11-01-preview'
