@description('Specifies the name of the Data Collection Rule to create.')
param dataCollectionRuleName string = 'SigninLogs'

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
            name: 'AlternateSignInName'
            type: 'string'
          }
          {
            name: 'AppDisplayName'
            type: 'int'
          }
          {
            name: 'AppId'
            type: 'string'
          }
          {
            name: 'AuthenticationContextClassReferences'
            type: 'string'
          }
          {
            name: 'AuthenticationDetails'
            type: 'string'
          }
          {
            name: 'AuthenticationMethodsUsed'
            type: 'string'
          }
          {
            name: 'AuthenticationProcessingDetails'
            type: 'string'
          }
          {
            name: 'AuthenticationRequirement'
            type: 'string'
          }
          {
            name: 'AuthenticationRequirementPolicies'
            type: 'string'
          }
          {
            name: 'ClientAppUsed'
            type: 'string'
          }
          {
            name: 'ConditionalAccessPolicies'
            type: 'dynamic'
          }
          {
            name: 'ConditionalAccessStatus'
            type: 'string'
          }
          {
            name: 'CreatedDateTime'
            type: 'datetime'
          }
          {
            name: 'DeviceDetail'
            type: 'dynamic'
          }
          {
            name: 'IsInteractive'
            type: 'boolean'
          }
          {
            name: 'IPAddress'
            type: 'string'
          }
          {
            name: 'IsRisky'
            type: 'boolean'
          }
          {
            name: 'LocationDetails'
            type: 'dynamic'
          }
          {
            name: 'MfaDetail'
            type: 'dynamic'
          }
          {
            name: 'NetworkLocationDetails'
            type: 'string'
          }
          {
            name: 'OriginalRequestId'
            type: 'string'
          }
          {
            name: 'ProcessingTimeInMilliseconds'
            type: 'string'
          }
          {
            name: 'RiskDetail'
            type: 'string'
          }
          {
            name: 'RiskEventTypes'
            type: 'string'
          }
          {
            name: 'RiskEventTypes_V2'
            type: 'string'
          }
          {
            name: 'RiskLevelAggregated'
            type: 'string'
          }
          {
            name: 'RiskLevelDuringSignIn'
            type: 'int'
          }
          {
            name: 'RiskState'
            type: 'string'
          }
          {
            name: 'ResourceIdentity'
            type: 'int'
          }
          {
            name: 'ResourceDisplayName'
            type: 'string'
          }
          {
            name: 'ResourceServicePrincipalId'
            type: 'int'
          }
          {
            name: 'ServicePrincipalId'
            type: 'string'
          }
          {
            name: 'ServicePrincipalName'
            type: 'string'
          }
          {
            name: 'Status'
            type: 'dynamic'
          }
          {
            name: 'TokenIssuerName'
            type: 'string'
          }
          {
            name: 'TokenIssuerType'
            type: 'string'
          }
          {
            name: 'UserAgent'
            type: 'string'
          }
          {
            name: 'UserDisplayName'
            type: 'string'
          }
          {
            name: 'UserId'
            type: 'string'
          }
          {
            name: 'UserPrincipalName'
            type: 'string'
          }
          {
            name: 'AADTenantId'
            type: 'string'
          }
          {
            name: 'UserType'
            type: 'string'
          }
          {
            name: 'FlaggedForReview'
            type: 'boolean'
          }
          {
            name: 'IPAddressFromResourceProvider'
            type: 'string'
          }
          {
            name: 'SignInIdentifier'
            type: 'string'
          }
          {
            name: 'SignInIdentifierType'
            type: 'string'
          }
          {
            name: 'ResourceTenantId'
            type: 'string'
          }
          {
            name: 'HomeTenantId'
            type: 'string'
          }
          {
            name: 'UniqueTokenIdentifier'
            type: 'string'
          }
          {
            name: 'SessionLifetimePolicies'
            type: 'string'
          }
          {
            name: 'AutonomousSystemNumber'
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
          'Microsoft-SecurityAlert'
        ]
        destinations: [
          workspace.name
        ]
        outputStream: 'Microsoft-SecurityAlert'
        transformKql: 'source'
      }
    ]
  }
}

output dataCollectionEndpoint string = dce.properties.logsIngestion.endpoint
output immutableId string = dce.properties.immutableId
output endpointUri string = '${dce.properties.logsIngestion.endpoint}/dataCollectionRules/${dcr.properties.immutableId}/streams/${customTable}?api-version=2021-11-01-preview'
