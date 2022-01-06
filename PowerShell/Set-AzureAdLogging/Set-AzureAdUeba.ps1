[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Anomalies', 'EntityAnalytics', 'Ueba')]
    [string]$Endpoint,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('AuditLogs', 'AzureActivity', 'SigninLogs')]
    [array]$LogTypes
)

$apiVersion = '2021-09-01-preview'
$workspace = Get-AzResource `
    -Name "$WorkspaceName" `
    -ResourceType 'Microsoft.OperationalInsights/workspaces' 
 
$uri = '{0}/providers/Microsoft.SecurityInsights/settings/{1}?api-version={2}' -f $workspace.ResourceId, $Endpoint, $apiVersion    

$payload = @{
    name       = "$Endpoint"
    type       = "Microsoft.SecurityInsights/settings"
    kind       = "$Endpoint"

    properties = if ($LogTypes -and ($Endpoint -eq 'Ueba')) {    
        @{
            datasources = @(
                $LogTypes
            )
        }
    }
}

# Validate if any settings are already configured.
$validate = (Invoke-AzRestMethod -Path $uri -Method GET).Content | ConvertFrom-Json
if ($validate.etag) {
    $payload.etag = $validate.etag
}

$response = (Invoke-AzRestMethod -Path $uri -Payload ($payload | ConvertTo-Json -Depth 10) -Method PUT)
if ($response.StatusCode -eq 200) {
    Write-Output "Configuration completed"
}
else {
    ($response.Content | ConvertFrom-Json).error
}