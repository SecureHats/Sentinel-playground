#Check if the Az module is installed, if not install it
# This will auto install the Az.Accounts module if it is not installed
#Requires -Module Az.Resources

[CmdletBinding(DefaultParameterSetName = "CloudRepo")]
param (
    [Parameter(ParameterSetName = "CloudRepo")]
    [String]$repoUri,

    [Parameter(ParameterSetName = "LocalRepo")]
    [String]$repoDirectory,

    [Parameter(Mandatory = $true)]
    [String]$WorkspaceName,

    [Parameter(Mandatory = $false)]
    [String]$subscriptionId,
    
    [Parameter(Mandatory = $false)]
    [String]$CustomTableName = 'SecureHats'
)

Write-Output "Validating if required module is installed"
$AzModule = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue

$PSVersionTable

#Write-Output 'Installing Operation Insights module 2.3.0'
#Install-Module Az.OperationalInsights -RequiredVersion 2.3.0 -Repository PSGallery -Force | Out-Null

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

function Set-AzMonitorFunction {
    param (
        [Parameter(Mandatory = $true)]
        [String]$DisplayName,

        [Parameter(Mandatory = $true)]
        [String]$KqlQuery,

        [Parameter(Mandatory = $false)]
        [String]$Category = 'SecureHats'

    )

    New-AzOperationalInsightsSavedSearch `
        -ResourceGroupName $workspace.ResourceGroupName `
        -WorkspaceName $workspace.ResourceName `
        -SavedSearchId (New-Guid).Guid `
        -DisplayName $DisplayName `
        -Category $Category `
        -Query "$KqlQuery" `
        -FunctionAlias $DisplayName
}

Write-Output "Retrieving Log Analytics workspace [$($WorkspaceName)]"
$workspace = Get-AzResource `
    -Name "$WorkspaceName" `
    -ResourceType 'Microsoft.OperationalInsights/workspaces'

if ($null -eq $workspace) {
    Write-Warning "Log Analytics workspace [$($WorkspaceName)] could not be found in this subscription"
    break
}

if ($PSCmdlet.ParameterSetName -eq "CloudRepo") {
    $uriArray = $repoUri.Split("/")
    $gitOwner = $uriArray[3]
    $gitRepo = $uriArray[4]
    $gitPath = $uriArray[7]
    
    $apiUri = "https://api.github.com/repos/$gitOwner/$gitRepo/contents/$gitPath"

    $response = (Invoke-WebRequest $apiUri).Content `
        | ConvertFrom-Json `
        | Where-Object { $_.Name -like "*$($uriArray[8])*" -and $_.type -eq 'dir' }

    $parsers = $response `
        | Where-Object { $_.Name -notlike "*.*" } `
        | Select-Object Name

    Write-Output "Parsers: $parsers"
    
    foreach ($folder in $parsers.Name) {
        $apiUri = "https://api.github.com/repos/$gitOwner/$gitRepo/contents/$gitPath/$folder"
        Write-Host "New URL: [$apiUri]"
        $webResponse = (Invoke-WebRequest $apiUri).Content | ConvertFrom-Json
        $templateUris = ($webResponse | Where-Object { $_.download_url -like "*.*" }).download_url
        
        foreach ($templateUri in $templateUris) {
            $kqlQuery = (Invoke-RestMethod -Method Get -Uri $templateUri) -replace '<CustomLog>', ($CustomTableName + '_CL')
        }

        Set-AzMonitorFunction -DisplayName (($webResponse.name) -split "\.")[0] -KqlQuery "$($kqlQuery)"
    }
}
elseif ($PSCmdlet.ParameterSetName -eq "LocalRepo") {
    $parsers = @(Get-ChildItem `
        -Path $repoDirectory `
        -File `
        -Recurse `
        -Include "*.csl", "*.txt")

        foreach ($file in $parsers) {
            Write-Output "Retrieving content from data file [$file]"
            $kqlQuery = Get-Content $file.FullName -Raw
            Set-AzMonitorFunction -DisplayName $file.BaseName -KqlQuery "$($kqlQuery)"
        }
}
