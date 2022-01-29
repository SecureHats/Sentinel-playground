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
        [string]$WorkspaceName,

        [Parameter(Mandatory = $false,
            Position = 2)]
        [switch]$SetDefaults
    )

    $context = Get-AzContext

    if (!$context) {
        Connect-AzAccount -UseDeviceAuthentication
        $context = Get-AzContext
    }

    $SubscriptionId = $context.Subscription.Id
    $logo = "
     _____                           __  __      __
    / ___/___  _______  __________  / / / /___ _/ /______
    \__ \/ _ \/ ___/ / / / ___/ _ \/ /_/ / __ `/ __/ ___/
   ___/ /  __/ /__/ /_/ / /  /  __/ __  / /_/ / /_(__  )
  /____/\___/\___/\__,_/_/   \___/_/ /_/\__,_/\__/____/
    `n"

    Clear-Host
    Write-Host $logo -ForegroundColor White
    Write-Output "Connected to Azure with subscriptionId: $($SubscriptionId)`n"

    $apiVersion     = "?api-version=2021-10-01-preview"
    $baseUri        = "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/${WorkspaceName}"
    $templatesUri   = "$baseUri/providers/Microsoft.SecurityInsights/alertRuleTemplates$apiVersion"
    $alertUri       = "$baseUri/providers/Microsoft.SecurityInsights/alertRules"

    $alertRulesTemplates = ((Invoke-AzRestMethod -Path "$($templatesUri)" -Method GET).Content | ConvertFrom-Json).value
    $alerts = ((Invoke-AzRestMethod -Path "$($alertUri)$($apiVersion)" -Method GET).Content | ConvertFrom-Json).value

    $i = 0
    foreach ($item in $alertRulesTemplates) {
        if ($item.kind -eq "Scheduled") {
            foreach ($alert in $alerts) {
                if ($alert.properties.alertRuleTemplateName -in $item.name -or $alert.properties.displayName -eq $item.properties.displayName) {
                    Write-Verbose "$($item.properties.displayName)"
                    $alertUriGuid = $alertUri +'/'+ $($alert.name) + $apiVersion
                    $i++
                    Write-Host "Processing $($i) of $($alerts.count): $($item.properties.displayname)" -ForegroundColor Green

                    $properties = @{
                        queryFrequency        = $alert.properties.queryFrequency
                        queryPeriod           = $alert.properties.queryPeriod
                        triggerOperator       = $alert.properties.triggerOperator
                        triggerThreshold      = $alert.properties.triggerThreshold
                        severity              = $item.properties.severity
                        query                 = $item.properties.query
                        entityMappings        = $item.properties.entityMappings
                        templateVersion       = $item.properties.version
                        displayName           = $alert.properties.displayName
                        description           = $item.properties.description
                        enabled               = $alert.properties.enabled
                        suppressionDuration   = $alert.properties.suppressionDuration
                        suppressionEnabled    = $alert.properties.suppressionEnabled
                        alertRuleTemplateName = $item.name
                    }

                    if ($SetDefaults) {
                        $properties.queryFrequency        = $item.properties.queryFrequency
                        $properties.queryPeriod           = $item.properties.queryPeriod
                        $properties.triggerOperator       = $item.properties.triggerOperator
                        $properties.triggerThreshold      = $item.properties.triggerThreshold
                        $properties.displayName           = $item.properties.displayName
                        $properties.enabled               = $true
                        $properties.suppressionEnabled    = [bool]$item.properties.suppressionEnabled
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
                                Write-Verbose "Rule was not created from template, recreating rule"
                                Invoke-AzRestMethod -Path $alertUriGuid -Method DELETE
                                Invoke-AzRestMethod -Path $alertUriGuid -Method PUT -Payload ($alertBody | ConvertTo-Json -Depth 10)
                            } else {
                                Write-Host "Warning: "(($result.Content | ConvertFrom-Json).error.message) -ForegroundColor Red
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
