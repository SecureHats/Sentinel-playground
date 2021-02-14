[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [String]$CustomerId,

    [Parameter(Mandatory = $false)]
    [String]$SharedKey,

    [Parameter(Mandatory = $true)]
    [String]$FilesPath
)

# Specify the name of the record type that you'll be creating
$LogType = "SecureHats"

Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256         = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key     = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash    = [Convert]::ToBase64String($calculatedHash)
    $authorization  = 'SharedKey {0}:{1}' -f $customerId,$encodedHash

    return $authorization
}


# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest `
        -Uri $uri `
        -Method $method `
        -ContentType $contentType `
        -Headers $headers `
        -Body $body `
        -UseBasicParsing

    return $response.StatusCode

}

$Files = @(Get-ChildItem -Path "$FilesPath" -File -Recurse -Filter "*.json")
Write-Output "Found $($Files.Count) data files."

  foreach ($File in $Files) {
    Write-Output "Retrieving content from data file '$File'."
    $json = Get-Content -Path $File.FullName -Raw

    # Submit the data to the API endpoint
    Post-LogAnalyticsData `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -body ([System.Text.Encoding]::UTF8.GetBytes($json)) `
        -logType $logType
}
