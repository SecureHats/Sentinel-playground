// param location string = resourceGroup().location

// resource logs 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'logs'
//   location: location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${identityName.id}': {
//       }
//     }
//   }
//   properties: {
//     forceUpdateTag: guid
//     azPowerShellVersion: '5.4'
//     arguments: ' -WorkspaceName ${workspaceName} -CustomTableName ${customTableName} -repoUri ${CloudRepo}/tree/${Branch}/samples/ -DataProvidersarray \\"${union(dataProviders, enabledSolutions)}\\"'
//     primaryScriptUri: 'https://raw.githubusercontent.com/SecureHats/Sentinel-playground/${Branch}/PowerShell/Add-AzureMonitorData/Add-AzureMonitorData.ps1'
//     supportingScriptUris: []
//     timeout: 'PT30M'
//     cleanupPreference: 'Always'
//     retentionInterval: 'P1D'
//     containerSettings: {
//       containerGroupName: 'logscontainer'
//     }
//     unionProviders: union(dataProviders, enabledSolutions)
//   }
//   dependsOn: [
//     roleGuid_resource
//     sleep
//   ]
// }
