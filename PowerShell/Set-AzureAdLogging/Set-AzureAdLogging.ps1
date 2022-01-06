[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceName,

    [Parameter(Mandatory = $false)]
    [string]$RuleName = "Log Analytics ($WorkspaceName)",

    [Parameters(Mandatory = $false)]
    [array]$categories = @('AuditLogs', `
            'SignInLogs', `
            'NonInteractiveUserSignInLogs', `
            'ServicePrincipalSignInLogs', `
            'ManagedIdentitySignInLogs', `
            'ProvisioningLogs', `
            'ADFSSignInLogs', `
            'RiskyUsers', `
            'UserRiskEvents'
    )
)

Import-Module Az
Login-AzAccount

$token = (Get-AzAccessToken).accessToken
$workspace = Get-AzResource -ResourceType "Microsoft.OperationalInsights/workspaces" -Name $WorkspaceName

# Setup Diagnostics Settings

$uri = https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/{0}?api-version=2017-04-01-preview -f $RuleName

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

$categoryHash = New-Object System.Collections.ArrayList
foreach ($item in $categories) {
    $currentItem = [PSCustomObject]@{
        category = $item
        enabled  = "true"
    }
    $null = $categoryHash.Add($currentItem)
}

$payload = @{
    id         = "providers/microsoft.aadiam/diagnosticSettings/$ruleName"
    type       = "Microsoft.Insights/diagnosticSettings"
    name       = "Log Analytics"
    properties = @{
        workspaceId = "$($workspace.ResourceId)"
        logs        = $categoryHash
    }
} | ConvertTo-Json -Depth 10

$argHash = @{
    Uri     = $uri
    Headers = $headers
    Body    = $payload
    Method  = 'PUT'
}

Invoke-RestMethod @argHash