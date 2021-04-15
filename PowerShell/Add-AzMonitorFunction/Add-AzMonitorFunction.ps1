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

function Set-AzMonitorFunction {
    param (
        [Parameter(Mandatory = $true)]
        [String]$DisplayName,

        [Parameter(Mandatory = $true)]
        [String]$KqlQuery,

        [Parameter(Mandatory = $false)]
        [String]$Category = 'SecureHats'

    )

    $payload = @{
        ResourceGroupName    = $workspace.ResourceGroupName
        ResourceProviderName = 'Microsoft.OperationalInsights'
        ResourceType         = "workspaces/$($workspace.ResourceName)/savedSearches"
        ApiVersion           = '2020-08-01'
        Name                 = $DisplayName
        Method               = 'DELETE'
    }

    $query = Invoke-AzRestMethod @payload

    if(-not($existing.StatusCode -eq '200')){
        New-AzOperationalInsightsSavedSearch `
            -ResourceGroupName $workspace.ResourceGroupName `
            -WorkspaceName $workspace.ResourceName `
            -SavedSearchId $DisplayName `
            -DisplayName $DisplayName `
            -Category $Category `
            -Query "$KqlQuery" `
            -FunctionAlias $DisplayName
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
        [object]$responseBody
    )

    foreach ($responseobject in $responseBody) {
        if ($responseobject.type -eq 'dir') {
            $responseobject = (Invoke-WebRequest (PathBuilder -uri $responseobject.html_url)).Content | ConvertFrom-Json
            Write-Output $responseobject
            pause
        }
    
        foreach ($fileObject in $responseobject) {
            if ($fileObject.name -like "*.csl") {
                $kqlQuery = (Invoke-RestMethod -Method Get -Uri $fileObject.download_url) -replace '<CustomLog>', ($CustomTableName + '_CL')
                Set-AzMonitorFunction -DisplayName (($fileObject.name) -split "\.")[0] -KqlQuery "$($kqlQuery)"
            }
            else {
                Write-Output "Nothing to progress"
            }       
        }
    }
    
}

Write-Output "Retrieving Log Analytics workspace [$($WorkspaceName)]"
$workspace = @{
        ResourceGroupName    = $workspace.ResourceGroupName
        ResourceProviderName = 'Microsoft.OperationalInsights'
        ResourceType         = "workspaces"
        ApiVersion           = '2020-08-01'
        Method               = 'GET'
    }

if ($null -eq $workspace) {
    Write-Warning "Log Analytics workspace [$($WorkspaceName)] could not be found in this subscription"
    break
}

if ($DataProvidersArray) {
    $dataProviders = $DataProvidersArray | ConvertFrom-Json

    foreach ($provider in $dataProviders) {
        Write-Output "Provider: $provider"
        $returnUri = PathBuilder -uri $RepoUri -provider $provider 
        
        $response = (Invoke-WebRequest $returnUri).Content | ConvertFrom-Json
        processResponse -responseBody $response
    }
}
else {
    $returnUri = PathBuilder -uri $RepoUri -provider $provider
    
    $response = (Invoke-WebRequest $returnUri).Content | ConvertFrom-Json
    processResponse -responseBody $response
}
