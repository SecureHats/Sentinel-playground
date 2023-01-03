
### CSV example

```powershell
Invoke-RestMethod `
    -Uri "https://syslog-1dhn.westeurope-1.ingest.monitor.azure.com/dataCollectionRules/dcr-78aa2a5fe1224524b55df2f4b8152315/streams/Custom-Syslog_CL?api-version=2021-11-01-preview" `
    -Body (Get-Content -Raw 'C:\Downloads\data\syslog.csv' `
    | ConvertFrom-CSV `
    | ConvertTo-Json -AsArray) `
    @requestHeader
```

### JSON example
```powershell
Invoke-RestMethod `
    -Uri "https://syslog-1dhn.westeurope-1.ingest.monitor.azure.com/dataCollectionRules/dcr-78aa2a5fe1224524b55df2f4b8152315/streams/Custom-Syslog_CL?api-version=2021-11-01-preview" `
    -Body (Get-Content -Raw 'C:\Downloads\data\syslog.json') `
    @requestHeader
```

### AccessToken Script

```powershell
function Get-GraphToken {
    # Login Process
    $body = @{
                "client_id" = "d3590ed6-52b3-4102-aeff-aad2292ab01c"
                "resource"  = "https://monitor.azure.com/"
                "scope" = [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")
            }
    
    $authResponse = Invoke-RestMethod `
        -UseBasicParsing `
        -Method Post `
        -Uri "https://login.microsoftonline.com/common/oauth2/devicecode?api-version=1.0" `
        -Body $body
    
    Write-Output $authResponse.message
    $continue = $true
    
    $body = @{
        "client_id"  = "d3590ed6-52b3-4102-aeff-aad2292ab01c"
        "grant_type" = "urn:ietf:params:oauth:grant-type:device_code"
        "code"       = $authResponse.device_code
    }
    while ($continue) {
        Start-Sleep -Seconds $authResponse.interval
        $total += $authResponse.interval

        if ($total -gt ($authResponse.expires_in)) {
            Write-Error "Timeout occurred"
            return
        }          
        try {
            $script:_graphToken = Invoke-RestMethod `
                -UseBasicParsing `
                -Method Post `
                -Uri "https://login.microsoftonline.com/Common/oauth2/token?api-version=1.0 " `
                -Body $body `
                -ErrorAction SilentlyContinue
        } catch {
            $details = $_.ErrorDetails.Message | ConvertFrom-Json
            $continue = $details.error -eq "authorization_pending"
            Write-Output "Waiting for approval: $($continue)"

            if (!$continue) {
                Write-Error $details.error_description
                return
            }
        }
        if($_graphToken)
        {
            $global:requestHeader = @{
            "Token"          = ($_graphToken.access_token | ConvertTo-SecureString -AsPlainText -Force)
            "Authentication" = 'OAuth'
            "Method"         = 'POST'
            "ContentType"    = 'application/json'
        }
            break
        }
    }
}
```
