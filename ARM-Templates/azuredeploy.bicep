@description('Name for the Log Analytics workspace')
param workspaceName string

@description('array of supported data providers')
param dataProviders array = []

@description('array of supported data providers')
param dataConnectors array = []

@description('Araay of supported solutions')
param enabledSolutions array = []

@description('Array of supported solutions')
param solutionConnectors array = []
param CloudRepo string = 'https://github.com/SecureHats/Sentinel-playground'
param Branch string = 'main'
param roleGuid string = newGuid()
param customTableName string = 'SecureHats'
param newManagedIdentity bool = false
param managedIdentityName string = workspaceName
param guid string = newGuid()

var Contributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
var identityName_var = (newManagedIdentity ? '${managedIdentityName}-${resourceGroup().location}' : managedIdentityName)

resource identityName 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName_var
  location: resourceGroup().location
}

resource roleGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (newManagedIdentity ? bool('true') : bool('false')) {
  name: roleGuid
  properties: {
    roleDefinitionId: Contributor
    principalId: reference(identityName.id, '2018-11-30', 'Full').properties.principalId
  }
  dependsOn: [
    sleep
  ]
}

resource logs 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'logs'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityName.id}': {
      }
    }
  }
  properties: {
    forceUpdateTag: guid
    azPowerShellVersion: '5.4'
    arguments: ' -WorkspaceName ${workspaceName} -CustomTableName ${customTableName} -repoUri ${CloudRepo}/tree/${Branch}/samples/ -DataProvidersarray \\"${union(dataProviders, enabledSolutions)}\\"'
    primaryScriptUri: 'https://raw.githubusercontent.com/SecureHats/Sentinel-playground/${Branch}/PowerShell/Add-AzureMonitorData/Add-AzureMonitorData.ps1'
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
    containerSettings: {
      containerGroupName: 'logscontainer'
    }
    unionProviders: union(dataProviders, enabledSolutions)
  }
  dependsOn: [
    roleGuid_resource
    sleep
  ]
}

resource functions 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'functions'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityName.id}': {
      }
    }
  }
  properties: {
    forceUpdateTag: guid
    azPowerShellVersion: '5.4'
    arguments: ' -WorkspaceName ${workspaceName} -CustomTableName ${customTableName} -repoUri ${CloudRepo}/tree/${Branch}/parsers/ -DataProvidersarray \\"${union(dataProviders, enabledSolutions)}\\"'
    primaryScriptUri: 'https://raw.githubusercontent.com/SecureHats/Sentinel-playground/${Branch}/PowerShell/Add-AzureMonitorData/Add-AzureMonitorData.ps1'
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
    containerSettings: {
      containerGroupName: 'functionscontainer'
    }
  }
  dependsOn: [
    roleGuid_resource
    solutions
  ]
}

resource sleep 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (newManagedIdentity ? bool('true') : bool('false')) {
  name: 'sleep'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    forceUpdateTag: '1'
    azPowerShellVersion: '3.0'
    arguments: ''
    scriptContent: 'Start-Sleep -Seconds 90'
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    identityName
  ]
}

module solutions '?' /*TODO: replace with correct path to https://raw.githubusercontent.com/SecureHats/Sentinel-playground/main/ARM-Templates/LinkedTemplates/solutions.json*/ = if (!empty(enabledSolutions)) {
  name: 'solutions'
  params: {
    workspaceName: workspaceName
    enabledSolutions: enabledSolutions
  }
  dependsOn: [
    workspaceName_resource
    sleep
  ]
}

resource waiting_for_customdata 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'waiting-for-customdata'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    forceUpdateTag: '1'
    azPowerShellVersion: '3.0'
    arguments: ''
    scriptContent: 'Start-Sleep -Seconds 900'
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    identityName
    solutions
  ]
}

resource AlertRules 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'AlertRules'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityName.id}': {
      }
    }
  }
  properties: {
    forceUpdateTag: guid
    azPowerShellVersion: '5.4'
    arguments: ' -Workspace ${workspaceName} -ResourceGroup ${resourceGroup().name} -SetDefaults'
    primaryScriptUri: 'https://raw.githubusercontent.com/SecureHats/Sentinel-playground/${Branch}/PowerShell/Update-DetectionRules/Update-DetectionRules.ps1'
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
    containerSettings: {
      containerGroupName: 'alertscontainer'
    }
  }
  dependsOn: [
    waiting_for_customdata
  ]
}

resource functions 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'functions'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityName.id}': {
      }
    }
  }
  properties: {
    forceUpdateTag: guid
    azPowerShellVersion: '5.4'
    arguments: ' -WorkspaceName ${workspaceName} -CustomTableName ${customTableName} -repoUri ${CloudRepo}/tree/${Branch}/parsers/ -DataProvidersarray \\"${union(dataProviders, enabledSolutions)}\\"'
    primaryScriptUri: 'https://raw.githubusercontent.com/SecureHats/Sentinel-playground/${Branch}/PowerShell/Add-AzureMonitorData/Add-AzureMonitorData.ps1'
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
    containerSettings: {
      containerGroupName: 'functionscontainer'
    }
  }
  dependsOn: [
    roleGuid_resource
    solutions
  ]
}
