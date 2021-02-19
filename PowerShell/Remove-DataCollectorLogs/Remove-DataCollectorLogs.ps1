[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [String]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [String]$WorkspaceName,

    [Parameter(Mandatory = $true)]
    [String]$CustomTableName
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

try {
    Write-Output "Looking for requested workspace [$($WorkspaceName)]"

    $workspaceParams = @{
        Method               = 'GET'
        ApiVersion           = '2020-08-01'
        ResourceProviderName = 'Microsoft.OperationalInsights/workspaces'
    }

    $workspace = ((Invoke-AzRestMethod @workspaceParams).Content `
        | ConvertFrom-Json).value `
        | Where-Object Name -eq $workspaceName

    $splitArray = $workspace.id -split '/'
}
catch {
    Write-Warning -Message "Log Analytics workspace [$($WorkspaceName)] not found in the current context"
    break
}

try {
    Write-Output -InputObject "Retrieving DataCollectorLog table [$($CustomTableName)]"
    $logtableParams = @{
        SubscriptionId       = $splitArray[2]
        ResourceGroupName    = $splitArray[4]
        ResourceProviderName = $splitArray[6]
        ResourceType         = $splitArray[7]
        Name                 = '{0}/dataCollectorLogs/{1}' -f $splitArray[8], $CustomTableName
        ApiVersion           = '2020-08-01'
    }

    $customLogTable = Invoke-AzRestMethod -Method GET @logtableParams

    if (-not(($customLogTable.Content | ConvertFrom-Json).error)) {
        Write-Warning "Deleting DataCollectorLog table [$($CustomTableName)]"
        $result = Invoke-AzRestMethod -Method DELETE @logtableParams

        if (($result.Content | ConvertFrom-Json).error) {
            Write-Warning "Operation Failed!"
        }
    }
    else {
        Write-Warning "Operation Failed $(($customLogTable.Content | ConvertFrom-Json).error.message)"
        break
    }
}
catch {
    Write-Error -Message $Error
}
