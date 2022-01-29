<#
.Synopsis
   Helper function that updates existing detection rules in Microsoft Sentinel
.DESCRIPTION
   This helper function updates the existing detection rules in the Microsoft Sentinel portal to match the latest version available in the Alert Templates Catalog
.EXAMPLE
   Update-DetectionRules -ResourceGroupName 'MyResourceGroup' -WorkspaceName 'MyWorkspace'
#>
function Enable-AlertRules {
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Graph access token
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true,
            Position = 1)]
        [string]$WorkspaceName,

        [Parameter(Mandatory = $false,
            Position = 1)]
        [ValidateSet("AlsidForAD",
            "AWS",
            "AzureActiveDirectory",
            "AzureActiveDirectoryIdentityProtection",
            "AzureActivity",
            "AzureAdvancedThreatProtection",
            "AzureFirewall",
            "AzureInformationProtection",
            "AzureMonitor",
            "AzureSecurityCenter",
            "CEF",
            "CheckPoint",
            "CiscoASA",
            "CiscoUmbrellaDataConnector",
            "CognniSentinelDataConnector",
            "CyberpionSecurityLogs",
            "DNS",
            "EsetSMC",
            "F5",
            "Fortinet",
            "InfobloxNIOS",
            "IoT",
            "MicrosoftCloudAppSecurity",
            "MicrosoftDefenderAdvancedThreatProtection",
            "MicrosoftThreatProtection",
            "Office365",
            "OfficeATP",
            "OfficeIRM",
            "PaloAltoNetworks",
            "ProofpointPOD",
            "PulseConnectSecure",
            "QualysVulnerabilityManagement",
            "SecurityEvents",
            "SophosXGFirewall",
            "SymantecProxySG",
            "Syslog",
            "ThreatIntelligence",
            "ThreatIntelligenceTaxii",
            "TrendMicroXDR",
            "VMwareCarbonBlack",
            "WAF",
            "WindowsFirewall",
            "WindowsSecurityEvents",
            "Zscaler"
        )]
        [array]$DataConnectors
    )

    $context = Get-AzContext

    if (!$context) {
        Connect-AzAccount -UseDeviceAuthentication
        $context = Get-AzContext
    }

    $_context = @{
        'Account'         = $($context.Account)
        'Subscription Id' = $context.Subscription
        'Tenant'          = $context.Tenant
    }

    $SubscriptionId = $context.Subscription.Id
    $logFile = '{0}\failed-rules-{1}.json' -f $($env:USERPROFILE), (get-date -f yyyyMMdd-hhmm)
    $logo = "
     _____                           __  __      __
    / ___/___  _______  __________  / / / /___ _/ / ____
    \__ \/ _ \/ ___/ / / / ___/ _ \/ /_/ / __ `/ __/ ___/
   ___/ /  __/ /__/ /_/ / /  /  __/ __  / /_/ / /_(__  )
  /____/\___/\___/\__,_/_/   \___/_/ /_/\__,_/\__/____/ `n`n"

    Clear-Host
    Write-Host $logo -ForegroundColor White
    $_details = [ordered]@{
        #"Subscription Id"         = $($context.Subscription.id)
        "Subscription Id"         = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
        "Log Analytics workspace" = 'xx-xxx-xxxxxxx'
        "Data Connectors"         = $($DataConnectors)
        "Logfile path"            = $($logFile)
    }

    Write-Output $_details "`n`n"
    Write-Verbose ($_context | ConvertTo-Json)

    $apiVersion = "?api-version=2021-10-01-preview"
    $baseUri = "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/${WorkspaceName}"
    $templatesUri = "$baseUri/providers/Microsoft.SecurityInsights/alertRuleTemplates$apiVersion"
    $alertUri = "$baseUri/providers/Microsoft.SecurityInsights/alertRules"

    if (-not($DataConnectors)) {
        $alertRulesTemplates = ((Invoke-AzRestMethod -Path "$($templatesUri)" -Method GET).Content | ConvertFrom-Json).value
    }
    else {
        $templates = ((Invoke-AzRestMethod -Path "$($templatesUri)" -Method GET).Content | ConvertFrom-Json).value
        foreach ($connector in $DataConnectors) {
            $alertRulesTemplates += ($templates | Where-Object { $_.Properties.RequiredDataConnectors.connectorId -contains $connector -and $_.kind -eq 'Scheduled' })
        }
    }

    Write-Output "$($alertRulesTemplates.count) Alert Rule Templates are found`n"

    foreach ($item in $alertRulesTemplates) {
        foreach ($alert in $alertRulesTemplates) {
            $alertName = (New-Guid).Guid
            Write-Verbose "$($item.properties.displayName)"
            $alertUriGuid = $alertUri + '/' + $($alertName) + $apiVersion
            $i++
            Write-Host "Processing $($i) of $($alertRulesTemplates.count) : $($item.properties.displayname)" -ForegroundColor Green
            $properties = @{
                queryFrequency        = $item.properties.queryFrequency
                queryPeriod           = $item.properties.queryPeriod
                triggerOperator       = $item.properties.triggerOperator
                triggerThreshold      = $item.properties.triggerThreshold
                severity              = $item.properties.severity
                query                 = $item.properties.query
                entityMappings        = $item.properties.entityMappings
                templateVersion       = $item.properties.version
                displayName           = $item.properties.displayName
                description           = $item.properties.description
                enabled               = $true
                suppressionDuration   = 'PT5H'
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
                        Write-Verbose "Rule was not created from template, recreating rule"
                        Invoke-AzRestMethod -Path $alertUriGuid -Method DELETE
                        Invoke-AzRestMethod -Path $alertUriGuid -Method PUT -Payload ($alertBody | ConvertTo-Json -Depth 10)
                    }
                    else {
                        Write-Host "Warning: "(($result.Content | ConvertFrom-Json).error.message) -ForegroundColor Red
                        $currentItem = [PSCustomObject]@{
                            'ruleName'  = $item.properties.displayNAme
                            'tactic'    = $item.properties.tactics
                            'technique' = $item.properties.techniques
                            'error'     = (($result.Content | ConvertFrom-Json).error.message)
                        }
                        $currentItem | ConvertTo-Json | Out-File $logFile -Append
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
