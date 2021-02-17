[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$WorkspaceId,

    [Parameter(Mandatory = $true)]
    [SecureString]$WorkspaceKey,

    [Parameter(Mandatory = $true)]
    [String]$FilesPath,

    [Parameter(Mandatory = $true)]
    [String]$LogType = "SecureHats"
)

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

    #$signature = Build-Signature @parameters

    $payload = @{
        "Headers"     = @{
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

$Files = @(Get-ChildItem `
        -Path "$($FilesPath)" `
        -File `
        -Recurse `
        -Include "*.json", "*.csv")

foreach ($File in $Files) {
    switch ($File.extension) {
        ".json" {
            Write-Output "Retrieving content from data file [$File]"
            $content = Get-Content -Path $File.FullName -Raw
        }
        ".csv" {
            Write-Output "Retrieving content from data file [$File]"
            $content = Get-Content -Path $File.FullName -Raw `
            | ConvertFrom-Csv `
            | ConvertTo-Json
        }
        default {
            Write-Output "No valid file type found"
        }
    }

    # Submit the data to the API endpoint
    Write-Output "Sending data to Log Analytics workspace..."
    Set-LogAnalyticsData `
        -WorkspaceId $WorkspaceId `
        -WorkspaceKey $WorkspaceKey `
        -body ([System.Text.Encoding]::UTF8.GetBytes($content)) `
        -logType $logType
}
