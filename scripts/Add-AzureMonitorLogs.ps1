[CmdletBinding()]
param (

    [Parameter(Mandatory = $true)]
    [String]$WorkspaceName,

    [Parameter(Mandatory = $true)]
    [String]$LogType

    [Parameter(Mandatory = $true)]
    [String]$FilesPath
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

    #building the signature
    $xHeaders = "x-ms-date:" + $rfc1123date
    $stringToHash = "POST" + "`n" + $contentLength + "`n" + "application/json" + "`n" + $xHeaders + "`n" + "/api/logs"
    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String((ConvertFrom-SecureString -SecureString $workspaceKey -AsPlainText))
    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $workspaceId, $encodedHash

    return $authorization
}

# Function to send data to the custom table
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

    #$signature = Build-Signature @parameters

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
    return $response.StatusCode
}

try {
    Write-Output "Looking for requested workspace [$($WorkspaceName)]"
    $workspaceParams = @{
        Method               = 'GET'
        ApiVersion           = '2020-08-01'
        ResourceProviderName = 'Microsoft.OperationalInsights/workspaces'
    }

    $workspace = ((Invoke-AzRestMethod @workspaceParams).Content `
        | ConvertFrom-Json).value | Where-Object Name -eq $WorkspaceName

    $splitArray = $workspace.id -split '/'
    $ResourceGroupName  = $splitArray[4]
    $WorkspaceName      = $splitArray[8]
    $workspaceId        = $workspace.properties.customerId

}
catch {
    Write-Warning -Message "Log Analytics workspace [$($WorkspaceName)] not found in the current context"
    break
}

$workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKeys `
    -ResourceGroupName $ResourceGroupName `
    -Name $WorkspaceName).PrimarySharedKey `
    | ConvertTo-SecureString -AsPlainText -Force

$files = @(Get-ChildItem -Path "$($FilesPath)" `
        -File -Recurse -Include "*.json", "*.csv")

foreach ($file in $files) {
    switch ($file.extension) {
        ".json" {
            Write-Output "Processing [$file]"
            $content = Get-Content -Path $file.FullName -Raw
        }
        ".csv" {
            Write-Output "Processing [$file]"
            $content = Get-Content -Path $file.FullName -Raw `
            | ConvertFrom-Csv `
            | ConvertTo-Json
        }
        default {
            Write-Output "No valid file type found"
        }
    }

    # Submit the data to the API endpoint
    Write-Output "Sending data to Data Log Collector table [$($logType)]"
    $result = Set-LogAnalyticsData `
            -WorkspaceId $workspaceId -WorkspaceKey $workspaceKey `
            -body ([System.Text.Encoding]::UTF8.GetBytes($content)) `
            -logType $logType

    if(-not($result -eq 200)) {
        Write-Warning: "Unable to send data to Data Log Collector table"
        break
    }
}
