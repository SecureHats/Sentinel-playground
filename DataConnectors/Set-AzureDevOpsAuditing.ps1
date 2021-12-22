[CmdletBinding()]
param (
    [Parameter(Mandatory = $true,
        Position = 0)]
    [string]$WorkspaceId,

    [Parameter(Mandatory = $true,
        Position = 1)]
    [string]$WorkspaceKey,

    [Parameter(Mandatory = $true,
        Position = 2)]
    [string]$Organization,

    [Parameter(Mandatory = $true,
        Position = 3)]
    [string]$PersonalAccessToken

)

$uri = 'https://auditservice.dev.azure.com/{0}/_apis/audit/streams?daysToBackfill=0&api-version=6.0-preview.1' -f $organization

$headers = @{
    "Authorization" = "Basic $([System.Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(":$PersonalAccessToken")))"
    "Content-Type"  = "application/json"
}

$payload = @{
    consumerType   = 'AzureMonitorLogs'
    consumerInputs = @{
        WorkspaceId = $WorkspaceId
        SharedKey   = $WorkspaceKey
    }
} | ConvertTo-Json -Depth 10

$defaultHttpSettings = @{
    useBasicParsing = $true
    contentType     = "application/json"
    Uri             = $uri
    headers         = $headers
    Method          = "POST"
}

Invoke-RestMethod @defaultHttpSettings -Body $payload