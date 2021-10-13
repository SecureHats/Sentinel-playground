[CmdletBinding(DefaultParameterSetName = "CloudRepo")]
param (
    [Parameter(ParameterSetName = "CloudRepo")]
    [String]$RepoUri,

    [Parameter(ParameterSetName = "LocalRepo")]
    [String]$RepoDirectory,

    [Parameter(Mandatory = $true)]
    [String]$WorkspaceName,

    [Parameter(Mandatory = $false)]
    [Array]$DataProvidersArray,

    [Parameter(Mandatory = $false)]
    [String]$subscriptionId,

    [Parameter(Mandatory = $false)]
    [String]$CustomTableName = 'SecureHats'
)

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
$rfc1123date = [DateTime]::UtcNow.ToString("r")

Function Build-Signature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]$workspaceId,

        [Parameter(Mandatory = $true)]
        [SecureString]$workspaceKey,

        [Parameter(Mandatory = $true)]
        [Int32]$contentLength

    )

    $xHeaders       = "x-ms-date:" + $rfc1123date
    $stringToHash   = "POST" + "`n" + $contentLength + "`n" + "application/json" + "`n" + $xHeaders + "`n" + "/api/logs"
    $bytesToHash    = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes       = [Convert]::FromBase64String((ConvertFrom-SecureString -SecureString $workspaceKey -AsPlainText))
    $sha256         = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key     = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash    = [Convert]::ToBase64String($calculatedHash)
    $authorization  = 'SharedKey {0}:{1}' -f $workspaceId, $encodedHash

    return $authorization
}

# Create the function to create and post the request
Function Set-LogAnalyticsData {

    param (
        [Parameter(Mandatory = $true)]
        [String]$workspaceId,

        [Parameter(Mandatory = $true)]
        [securestring]$workspaceKey,

        [Parameter(Mandatory = $true)]
        [Array]$body,

        [Parameter(Mandatory = $true)]
        [String]$logType

    )

    $parameters = @{
        "WorkspaceId"   = $workspaceId
        "WorkspaceKey"  = $workspaceKey
        "contentLength" = $body.Length
    }

    $payload = @{
        "Headers" = @{
            "Authorization" = Build-Signature @parameters
            "Log-Type"      = $logType
            "x-ms-date"     = $rfc1123date
        }
        "method"      = "POST"
        "contentType" = "application/json"
        "uri"         = "https://{0}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01" -f $workspaceId
        "body"        = $body
    }

    $response = Invoke-WebRequest @payload -UseBasicParsing

    if (-not($response.StatusCode -eq 200)) {
        Write-Warning "Unable to send data to Data Log Collector table"
        break
    }
    else {
        Write-Output "Uploaded to Data Log Collector table [$($logType + '_CL')] at [$rfc1123date]"
    }
}
function Set-AzMonitorFunction {
    param (
        [Parameter(Mandatory = $true)]
        [String]$resourceGroupName,

        [Parameter(Mandatory = $true)]
        [String]$displayName,

        [Parameter(Mandatory = $true)]
        [String]$kqlQuery,

        [Parameter(Mandatory = $false)]
        [String]$category = 'SecureHats'

    )

    $payload = @{
        ResourceGroupName    = "$resourceGroupName"
        ResourceProviderName = 'Microsoft.OperationalInsights'
        ResourceType         = "workspaces/$($WorkspaceName)/savedSearches"
        ApiVersion           = '2020-08-01'
        Name                 = "$displayName"
        Method               = 'GET'
    }
    
    $ctx = Invoke-AzRestMethod @payload
    if ($ctx.StatusCode -ne 200) {
        New-AzOperationalInsightsSavedSearch `
            -ResourceGroupName $resourceGroupName `
            -WorkspaceName $workspaceName `
            -SavedSearchId $displayName `
            -DisplayName $displayName `
            -Category $category `
            -Query "$kqlQuery" `
            -FunctionAlias $displayName    
    }

}

function pathBuilder {
    param (
        [Parameter(Mandatory = $true)]
        [String]$uri,

        [Parameter(Mandatory = $false)]
        [String]$provider

    )

    if ($provider) {
        if ($uri[-1] -ne '/') {
            $uri = '{0}{1}' -f $uri, '/'
        }
        $_path = '{0}{1}' -f $uri, $provider
    }
    else {
        $_path = $uri
    }

    $uriArray = $_path.Split("/")
    $gitOwner = $uriArray[3]
    $gitRepo = $uriArray[4]
    $gitPath = $uriArray[7]
    $solution = $uriArray[8]

    $apiUri = "https://api.github.com/repos/$gitOwner/$gitRepo/contents/$gitPath/$solution"

    return $apiUri
}
function processResponse {
    param (
        [Parameter(Mandatory = $true)]
        [string]$resourceGroupName,

        [Parameter(Mandatory = $true)]
        [object]$responseBody
    )

    foreach ($responseObject in $responseBody) {
        if ($responseObject.type -eq 'dir') {
            $responseObject = (Invoke-WebRequest (PathBuilder -uri $responseObject.html_url)).Content | ConvertFrom-Json
            Write-Output $responseObject
        }

        foreach ($fileObject in $responseObject) {
            if ($fileObject.name -like "*.csl") {
                $kqlQuery = (Invoke-RestMethod -Method Get -Uri $fileObject.download_url) -replace '<CustomLog>', ($CustomTableName + '_CL')

                Set-AzMonitorFunction `
                    -resourceGroupName $resourceGroupName `
                    -displayName (($fileObject.name) -split "\.")[0] `
                    -kqlQuery "$($kqlQuery)"
            }
            elseif ($fileObject.name -like "*.json") {
                $dataFile = Invoke-RestMethod -Method Get -Uri $fileObject.download_url | ConvertTo-Json
                $namedTable = ($fileObject.download_url -split '/')[-1]

                if ($namedTable -like "*_CL*") {
                    #temporarly store initial custom table name
                    $_customTableName = $CustomTableName
                    $CustomTableName = ($namedTable -replace "_CL.json")
                }

                $workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKeys `
                    -ResourceGroupName $ResourceGroupName `
                    -Name $WorkspaceName).PrimarySharedKey `
                    | ConvertTo-SecureString -AsPlainText -Force

                Set-LogAnalyticsData `
                    -WorkspaceId $workspaceId `
                    -WorkspaceKey $workspaceKey `
                    -body ([System.Text.Encoding]::UTF8.GetBytes($dataFile)) `
                    -logType $CustomTableName

                #reset to initial value
                if ($_customTableName) {
                    $CustomTableName = $_customTableName
                }
            }
            else {
                Write-Output "Nothing to progress"
            }
        }
    }
}

Write-Output "Validating if required module is installed"
$AzModule = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue

if ($null -eq $AzModule) {
    Write-Warning "The Az PowerShell module is not found"
    #check for Admin Privleges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    if (-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        #Not an Admin, install to current user
        Write-Warning -Message "Can not install the Az module. You are not running as Administrator"
        Write-Warning -Message "Installing Az module to current user Scope"
        Install-Module Az -Scope CurrentUser -Force -Repository PSGallery
    }
    else {
        #Admin, install to all users
        Write-Warning -Message "Installing the Az module to all users"
        Install-Module -Name Az -Force -Repository PSGallery
        Import-Module -Name Az -Force
    }
}

#Check the Azure subscription context
if ($subscriptionId) {
    $subIdContext = (Get-AzContext).Subscription.Id
    if ($subIdContext -ne $subscriptionId) {
        $setSub = Set-AzContext -SubscriptionName $subscriptionId -ErrorAction SilentlyContinue
        if ($null -eq $setSub) {
            Write-Warning "$subscriptionId is not set, please login and run this script again"
            Login-AzAccount
            break
        }
    }
}

Write-Output "Retrieving Log Analytics workspace [$($WorkspaceName)]"

try {
    Write-Output "Looking for requested workspace [$($WorkspaceName)]"
    $workspace = $workspace = Get-AzResource `
        -Name "$WorkspaceName" `
        -ResourceType 'Microsoft.OperationalInsights/workspaces'

    Write-Output "Workspace properties: $($workspace)"
    
    $ResourceGroupName  = $workspace.ResourceGroupName
    $workspaceName      = $workspace.Name
    $workspaceId        = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName).CustomerId.Guid
}
catch {
    Write-Warning -Message "Log Analytics workspace [$($WorkspaceName)] not found in the current context"
    break
}

if ($DataProvidersArray) {
    $dataProviders = $DataProvidersArray | ConvertFrom-Json

    foreach ($provider in $dataProviders) {
        Write-Output "Provider: $provider"
        $returnUri = PathBuilder -uri $RepoUri -provider $provider

        try {
            $response = (Invoke-WebRequest $returnUri).Content | ConvertFrom-Json
            processResponse -resourceGroupName $ResourceGroupName -responseBody $response
        }
        catch {
            Write-Output "No data found to process"
        }
    }
}
else {
    $returnUri = PathBuilder -uri $RepoUri -provider $provider

    $response = (Invoke-WebRequest $returnUri).Content | ConvertFrom-Json
    processResponse -resourceGroupName $ResourceGroupName -responseBody $response
}
