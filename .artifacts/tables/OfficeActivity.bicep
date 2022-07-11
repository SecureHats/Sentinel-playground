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
          name: 'Application'
          type: 'string'
        }
        {
          name: 'UserDomain'
          type: 'string'
        }
        {
          name: 'UserAgent'
          type: 'string'
        }
        {
          name: 'RecordType'
          type: 'string'
        }
        {
          name: 'TimeGenerated'
          type: 'datetime'
        }
        {
          name: 'Operation'
          type: 'string'
        }
        {
          name: 'OrganizationId'
          type: 'string'
        }
        {
          name: 'OrganizationId_'
          type: 'string'
        }
        {
          name: 'UserType'
          type: 'string'
        }
        {
          name: 'UserKey'
          type: 'string'
        }
        {
          name: 'OfficeWorkload'
          type: 'string'
        }
        {
          name: 'ResultStatus'
          type: 'string'
        }
        {
          name: 'ResultReasonType'
          type: 'string'
        }
        {
          name: 'OfficeObjectId'
          type: 'string'
        }
        {
          name: 'UserId'
          type: 'string'
        }
        {
          name: 'UserId_'
          type: 'string'
        }
        {
          name: 'ClientIP'
          type: 'string'
        }
        {
          name: 'ClientIP_'
          type: 'string'
        }
        {
          name: 'Scope'
          type: 'string'
        }
        {
          name: 'Site_'
          type: 'string'
        }
        {
          name: 'ItemType'
          type: 'string'
        }
        {
          name: 'EventSource'
          type: 'string'
        }
        {
          name: 'Source_Name'
          type: 'string'
        }
        {
          name: 'MachineDomainInfo'
          type: 'string'
        }
        {
          name: 'MachineId'
          type: 'string'
        }
        {
          name: 'Site_Url'
          type: 'string'
        }
        {
          name: 'Site_Url_'
          type: 'string'
        }
        {
          name: 'SourceRelativeUrl'
          type: 'string'
        }
        {
          name: 'SourceRelativeUrl_'
          type: 'string'
        }
        {
          name: 'SourceFileName'
          type: 'string'
        }
        {
          name: 'SourceFileName_'
          type: 'string'
        }
        {
          name: 'SourceFileExtension'
          type: 'string'
        }
        {
          name: 'DestinationRelativeUrl'
          type: 'string'
        }
        {
          name: 'DestinationFileName'
          type: 'string'
        }
        {
          name: 'DestinationFileExtension'
          type: 'string'
        }
        {
          name: 'UserSharedWith'
          type: 'string'
        }
        {
          name: 'SharingType'
          type: 'string'
        }
        {
          name: 'CustomEvent'
          type: 'string'
        }
        {
          name: 'Event_Data'
          type: 'string'
        }
        {
          name: 'ModifiedObjectResolvedName'
          type: 'string'
        }
        {
          name: 'Parameters'
          type: 'string'
        }
        {
          name: 'ExternalAccess'
          type: 'string'
        }
        {
          name: 'OriginatingServer'
          type: 'string'
        }
        {
          name: 'OrganizationName'
          type: 'string'
        }
        {
          name: 'Logon_Type'
          type: 'string'
        }
        {
          name: 'InternalLogonType'
          type: 'int'
        }
        {
          name: 'MailboxGuid'
          type: 'string'
        }
        {
          name: 'MailboxOwnerUPN'
          type: 'string'
        }
        {
          name: 'MailboxOwnerSid'
          type: 'string'
        }
        {
          name: 'MailboxOwnerMasterAccountSid'
          type: 'string'
        }
        {
          name: 'LogonUserSid'
          type: 'string'
        }
        {
          name: 'LogonUserDisplayName'
          type: 'string'
        }
        {
          name: 'ClientInfoString'
          type: 'string'
        }
        {
          name: 'Client_IPAddress'
          type: 'string'
        }
        {
          name: 'ClientMachineName'
          type: 'string'
        }
        {
          name: 'ClientProcessName'
          type: 'string'
        }
        {
          name: 'ClientVersion'
          type: 'string'
        }
        {
          name: 'Folder'
          type: 'string'
        }
        {
          name: 'CrossMailboxOperations'
          type: 'bool'
        }
        {
          name: 'DestMailboxId'
          type: 'string'
        }
        {
          name: 'DestMailboxOwnerUPN'
          type: 'string'
        }
        {
          name: 'DestMailboxOwnerSid'
          type: 'string'
        }
        {
          name: 'DestMailboxOwnerMasterAccountSid'
          type: 'string'
        }
        {
          name: 'DestFolder'
          type: 'string'
        }
        {
          name: 'Folders'
          type: 'string'
        }
        {
          name: 'AffectedItems'
          type: 'string'
        }
        {
          name: 'Item'
          type: 'string'
        }
        {
          name: 'ModifiedProperties'
          type: 'string'
        }
        {
          name: 'SendAsUserSmtp'
          type: 'string'
        }
        {
          name: 'SendAsUserMailboxGuid'
          type: 'string'
        }
        {
          name: 'SendOnBehalfOfUserSmtp'
          type: 'string'
        }
        {
          name: 'SendonBehalfOfUserMailboxGuid'
          type: 'string'
        }
        {
          name: 'ExtendedProperties'
          type: 'string'
        }
        {
          name: 'Client'
          type: 'string'
        }
        {
          name: 'LoginStatus'
          type: 'int'
        }
        {
          name: 'Actor'
          type: 'string'
        }
        {
          name: 'ActorContextId'
          type: 'string'
        }
        {
          name: 'ActorIpAddress'
          type: 'string'
        }
        {
          name: 'InterSystemsId'
          type: 'string'
        }
        {
          name: 'IntraSystemId'
          type: 'string'
        }
        {
          name: 'SupportTicketId'
          type: 'string'
        }
        {
          name: 'TargetContextId'
          type: 'string'
        }
        {
          name: 'DataCenterSecurityEventType'
          type: 'int'
        }
        {
          name: 'EffectiveOrganization'
          type: 'string'
        }
        {
          name: 'ElevationTime'
          type: 'datetime'
        }
        {
          name: 'ElevationApprover'
          type: 'string'
        }
        {
          name: 'ElevationApprovedTime'
          type: 'datetime'
        }
        {
          name: 'ElevationRequestId'
          type: 'string'
        }
        {
          name: 'ElevationRole'
          type: 'string'
        }
        {
          name: 'ElevationDuration'
          type: 'int'
        }
        {
          name: 'GenericInfo'
          type: 'string'
        }
        {
          name: 'SourceSystem'
          type: 'string'
        }
        {
          name: 'OfficeId'
          type: 'string'
        }
        {
          name: 'SourceRecordId'
          type: 'string'
        }
        {
          name: 'AzureActiveDirectory_EventType'
          type: 'string'
        }
        {
          name: 'AADTarget'
          type: 'string'
        }
        {
          name: 'Start_Time'
          type: 'datetime'
        }
        {
          name: 'OfficeTenantId'
          type: 'string'
        }
        {
          name: 'OfficeTenantId_'
          type: 'string'
        }
        {
          name: 'TargetUserOrGroupName'
          type: 'string'
        }
        {
          name: 'TargetUserOrGroupType'
          type: 'string'
        }
        {
          name: 'MessageId'
          type: 'string'
        }
        {
          name: 'Members'
          type: 'dynamic'
        }
        {
          name: 'TeamName'
          type: 'string'
        }
        {
          name: 'TeamGuid'
          type: 'string'
        }
        {
          name: 'ChannelType'
          type: 'string'
        }
        {
          name: 'ChannelName'
          type: 'string'
        }
        {
          name: 'ChannelGuid'
          type: 'string'
        }
        {
          name: 'ExtraProperties'
          type: 'dynamic'
        }
        {
          name: 'AddOnType'
          type: 'string'
        }
        {
          name: 'AddonName'
          type: 'string'
        }
        {
          name: 'TabType'
          type: 'string'
        }
        {
          name: 'Name'
          type: 'string'
        }
        {
          name: 'OldValue'
          type: 'string'
        }
        {
          name: 'NewValue'
          type: 'string'
        }
        {
          name: 'ItemName'
          type: 'string'
        }
        {
          name: 'ChatThreadId'
          type: 'string'
        }
        {
          name: 'ChatName'
          type: 'string'
        }
        {
          name: 'CommunicationType'
          type: 'string'
        }
        {
          name: 'AADGroupId'
          type: 'string'
        }
        {
          name: 'AddOnGuid'
          type: 'string'
        }
        {
          name: 'AppDistributionMode'
          type: 'string'
        }
        {
          name: 'TargetUserId'
          type: 'string'
        }
        {
          name: 'OperationScope'
          type: 'string'
        }
        {
          name: 'AzureADAppId'
          type: 'string'
        }
        {
          name: 'OperationProperties'
          type: 'dynamic'
        }
        {
          name: 'AppId'
          type: 'string'
        }
        {
          name: 'ClientAppId'
          type: 'string'
        }
        {
          name: 'ApplicationId'
          type: 'string'
        }
        {
          name: 'SRPolicyId'
          type: 'string'
        }
        {
          name: 'SRPolicyName'
          type: 'string'
        }
        {
          name: 'SRRuleMatchDetails'
          type: 'dynamic'
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
