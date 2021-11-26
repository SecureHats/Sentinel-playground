<#
.Synopsis
   Helper function that updates existing detection rules in Microsoft Sentinel
.DESCRIPTION
   This helper function updates the existing detection rules in the Microsoft Sentinel portal to match the latest version available in the Alert Templates Catalog
.EXAMPLE
   Update-DetectionRules -ResourceGroupName 'MyResourceGroup' -WorkspaceName 'MyWorkspace'
#>
function Update-DetectionRules {
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Graph access token
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string]$ResourceGroupName,

        # Graph access token
        [Parameter(Mandatory = $true,
            Position = 1)]
        [string]$WorkspaceName
    )

    $context = Get-AzContext

    if (!$context) {
        Connect-AzAccount
        $context = Get-AzContext
    }

    $SubscriptionId = $context.Subscription.Id

    Write-Host "Connected to Azure with subscription: " + $context.Subscription

    $apiVersion     = "api-version=2021-10-01-preview"
    $baseUri        = "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/${WorkspaceName}"
    $templatesUri   = "$baseUri/providers/Microsoft.SecurityInsights/alertRuleTemplates?apiVersion"
    $alertUri       = "$baseUri/providers/Microsoft.SecurityInsights/alertRules/?$apiVersion"

    $alertRulesTemplates = ((Invoke-AzRestMethod -Path "$($templatesUri)" -Method GET).Content | ConvertFrom-Json).value
    $alerts = ((Invoke-AzRestMethod -Path "$($alertUri)" -Method GET).Content | ConvertFrom-Json).value

    $i = 0
    foreach ($item in $alertRulesTemplates) {
        if ($item.kind -eq "Scheduled") {
            foreach ($alert in $alerts) {
                if ($alert.properties.alertRuleTemplateName -in $item.name -or $alert.properties.displayName -eq $item.properties.displayName) {
                    $alertUriGuid = $alertUri + $alert.name + '?api-version=2021-10-01-preview'
                    $i++
                    Write-Host "Processing $($i) of $($alerts.count): $($item.properties.displayname)" -ForegroundColor Yellow

                    $properties = @{
                        queryFrequency        = $item.properties.queryFrequency
                        queryPeriod           = $item.properties.queryPeriod
                        triggerOperator       = $item.properties.triggerOperator
                        triggerThreshold      = $item.properties.triggerThreshold
                        severity              = $item.properties.severity
                        query                 = $item.properties.query
                        entityMappings        = $item.properties.entityMappings
                        templateversion       = $item.properties.version
                        displayName           = $item.properties.displayName
                        description           = $item.properties.description
                        enabled               = $true
                        suppressionDuration   = "PT5H"
                        suppressionEnabled    = $false
                        alertRuleTemplateName = $item.name
                    }

                    if ($item.properties.techniques) {
                        $properties.techniques = $item.properties.techniques
                    }
                    if ($item.properties.tactics) {
                        $properties.tactics = $item.properties.tactics
                    }

                    $alertBody = @{}
                    $alertBody | Add-Member -NotePropertyName kind -NotePropertyValue $item.kind -Force
                    $alertBody | Add-Member -NotePropertyName properties -NotePropertyValue $properties

                    try {
                        $result = Invoke-AzRestMethod -Path $alertUriGuid -Method PUT -Payload ($alertBody | ConvertTo-Json -Depth 10)
                        if ($result.statusCode -eq 400) {
                            # if the existing built-in rule was not created from a template (old versions)
                            if ((($result.Content | ConvertFrom-Json).error.message) -match 'already exists and was not created by a template') {
                                Invoke-AzRestMethod -Path $alertUriGuid -Method DELETE
                                pause 10
                                Invoke-AzRestMethod -Path $alertUriGuid -Method PUT -Payload ($alertBody | ConvertTo-Json -Depth 10)
                            }
                        }
                    }
                    catch {
                        Write-Verbose $_
                        Write-Error "Unable to create alert rule with error code: $($_.Exception.Message)" -ErrorAction Stop
                    }
                    break
                }
            }
        }
    }
}
