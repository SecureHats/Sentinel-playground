[CmdletBinding()]
param (

    [Parameter(Mandatory = $true)]
    [String]$WorkspaceName,

    [Parameter(Mandatory = $false)]
    [String]$CustomTableName,

    [Parameter(ParameterSetName = "CloudRepo")]
    [String]$repoUri,

    [Parameter(ParameterSetName = "LocalRepo")]
    [String]$repoDirectory
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

    if(-not($response.StatusCode -eq 200)) {
        Write-Warning "Unable to send data to Data Log Collector table"
        break
    }
    else {
        Write-Output "Uploaded to Data Log Collector table [$($logType + '_CL')] at [$rfc1123date]"
    }
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

    $splitArray         = $workspace.id -split '/'
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

if ($PSCmdlet.ParameterSetName -eq "CloudRepo") {
    $uriArray = $repoUri.Split("/")
    $gitOwner = $uriArray[3]
    $gitRepo = $uriArray[4]
    $gitPath = $uriArray[7]

    $apiUri = "https://api.github.com/repos/$gitOwner/$gitRepo/contents/$gitPath"

    $response = (Invoke-WebRequest $apiUri).Content `
        | ConvertFrom-Json `
        | Where-Object { $_.Name -like "*$($uriArray[8])*" -and $_.type -eq 'dir' }


    $folders = $response `
    | Where-Object { $_.Name -notlike "*.*" } `
    | Select-Object Name

    foreach ($subfolder in $folders.Name) {
        $apiUri = "https://api.github.com/repos/$gitOwner/$gitRepo/contents/$gitPath/$subfolder"
        Write-Host "New URL: [$apiUri]"

        $webResponse = (Invoke-WebRequest $apiUri).Content | ConvertFrom-Json
        $dataUris = ($webResponse `
            | Where-Object { $_.download_url -like "*.json" -or `
                             $_.download_url -like "*.csv"
                            }`
            ).download_url

        foreach ($uri in $dataUris) {
            write-output "uri: [$($uri)]"

            $dataFile = Invoke-RestMethod -Method Get -Uri $uri | ConvertTo-Json
            $namedTable = ($uri -split '/')[-1]
            if ($namedTable -like "*_CL*") {

                #temporarly store initial custom table name
                $_customTableName = $CustomTableName
                $CustomTableName = ($namedTable -replace "_CL.json")
            }

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
    }
}
elseif ($PSCmdlet.ParameterSetName -eq "LocalRepo") {
    $dataFiles = @(Get-ChildItem `
        -Path $repoDirectory `
        -File `
        -Recurse `
        -Include "*.json", "*.csv")

        foreach ($dataFile in $dataFiles) {
            Write-Output "Retrieving content from data file [$dataFile]"
            switch ($dataFile.extension) {
                ".json" {
                    Write-Output "Processing [$dataFile]"
                    $content = Get-Content -Path $dataFile.FullName -Raw
                }
                ".csv" {
                    Write-Output "Processing [$dataFile]"
                    $content = Get-Content -Path $dataFile.FullName -Raw `
                    | ConvertFrom-Csv `
                    | ConvertTo-Json
                }
                default {
                    Write-Output "No valid file type found"
                }
            }

            $paramObject = @{
                "WorkspaceId" = $workspaceId
                "WorkspaceKey" = $workspaceKey
                "body" = ([System.Text.Encoding]::UTF8.GetBytes($content))
            }

            if ($dataFile.Name -like "*_CL") {
                $paramObject.logType = $dataFile.Name
            }
            else {
                $paramObject.logType = $CustomTableName
            }

            Set-LogAnalyticsData @paramObject
            <#`
                -WorkspaceId $workspaceId -WorkspaceKey $workspaceKey `
                -body ([System.Text.Encoding]::UTF8.GetBytes($content)) `
                -logType $CustomTableName
            #>
            }
}
