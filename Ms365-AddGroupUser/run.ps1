<# 

.SYNOPSIS
    
    This function is used to add a user from a distribution group in Microsoft 365.

.DESCRIPTION
             
    This function is used to add a user from a distribution group in Microsoft 365.
    
    The function requires the following environment variables to be set:
        
    Ms365_AuthAppId - Application Id of the service principal
    Ms365_AuthSecretId - Secret Id of the service principal
    Ms365_TenantId - Tenant Id of the Microsoft 365 tenant
        
    The function requires the following modules to be installed:
        
    Microsoft.Graph

.INPUTS

    UserEmail - user email address that exists in the tenant
    GroupName - group name that exists in the tenant
    TenantId - string value of the tenant id, if blank uses the environment variable Ms365_TenantId
    TicketId - optional - string value of the ticket id used for transaction tracking
    SecurityKey - Optional, use this as an additional step to secure the function

    JSON Structure

    {
        "UserEmail": "email@address.com",
        "GroupName": "Group Name",
        "TenantId": "12345678-1234-1234-123456789012",
        "TicketId": "123456,
        "SecurityKey", "optional"
    }

.OUTPUTS 

    JSON response with the following fields:

    Message - Descriptive string of result
    TicketId - TicketId passed in Parameters
    ResultCode - 200 for success, 500 for failure
    ResultStatus - "Success" or "Failure"

#>

using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Add User to Group function triggered."

$resultCode = 200
$message = ""

$UserEmail = $Request.Body.UserEmail
$GroupName = $Request.Body.GroupName
$TenantId = $Request.Body.TenantId
$TicketId = $Request.Body.TicketId
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $userEmail) {
    $message = "UserEmail cannot be blank."
    $resultCode = 500
}

if (-Not $groupName) {
    $message = "GroupName cannot be blank."
    $resultCode = 500
}

if (-Not $TenantId) {
    $TenantId = $env:Ms365_TenantId
}

Write-Host "User Email: $UserEmail"
Write-Host "Group Name: $GroupName"
Write-Host "Tenant Id: $TenantId"
Write-Host "Ticket Id: $TicketId"

#Connect to Graph
$secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
    $credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

    Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $TenantId
    # Retrieve group details from Microsoft Graph
    $GroupObject = Get-MgGroup -Filter "displayName eq '$GroupName'"

    if (-not $GroupObject) {
        Write-Host "Group '$GroupName' not found."
        return "Request failed. Group '$GroupName' not found."
    }

    # Debug: Print group properties
    Write-Host "Group ID: $($GroupObject.Id)"
    Write-Host "MailEnabled: $($GroupObject.MailEnabled)"
    Write-Host "SecurityEnabled: $($GroupObject.SecurityEnabled)"
    Write-Host "GroupTypes: $($GroupObject.GroupTypes -join ', ')"
    
function Add-UserToGraphGroup
{
    $GroupObject = Get-MgGroup -Filter "displayName eq '$GroupName'"

    Write-Host $GroupObject.DisplayName
    Write-Host $GroupObject.Id

    $UserObject = Get-MgUser -Filter "userPrincipalName eq '$UserEmail'"

    Write-Host $UserObject.userPrincipalName
    Write-Host $UserObject.Id

   
    if (-Not $GroupObject) {
        $message = "Request failed. Group `"$GroupName`" could not be found to add user `"$UserEmail`" to."
        $resultCode = 500
    }

    if (-Not $UserObject) {
        $message = "Request failed. User `"$UserEmail`" not be found to add to group `"$GroupName`"."
        $resultCode = 500
    }

    $GroupMembers = Get-MgGroupMember -GroupId $GroupObject.Id

    if ($GroupMembers.Id -Contains $UserObject.Id) {
        $message = "Request failed. User `"$UserEmail`" is already a member of group `"$GroupName`"."
        $resultCode = 500
    } 

    if ($resultCode -Eq 200) {
        New-MgGroupMember -GroupId $GroupObject.Id -DirectoryObjectId $UserObject.Id
        $message = "Request completed. `"$UserEmail`" has been added to group `"$GroupName`"."
    }
}

# Function to add a user to a Distribution List or Mail-Enabled Security Group using Exchange Online
function Add-UserToExchangeGroup {
    param (
        [string]$UserEmail,
        [string]$GroupName
    )

    Write-Host "🔌 Connecting to Exchange Online using App-Only Authentication..."
    try {
        $AppId = "$env:Ms365_AuthAppId"
        $TenantId = "Saxllp.com"
        $CertificateThumbprint = "$env:ExchangeOnline_Thumbprint"
        $Password = ConvertTo-SecureString -String "Password" -Force -AsPlainText

        Write-Host "🔑 Connecting to Exchange Online using App-Only Authentication..."
try {
    Connect-ExchangeOnline -ManagedIdentity -Organization "saxllp.onmicrosoft.com" -ManagedIdentityAccountId 1cc85f9a-8e18-4246-8ef2-bed7a73158a0

    Write-Host "📩 Adding user '$UserEmail' to Exchange group '$GroupName'..."
        
    # Add user to the distribution group or mail-enabled security group
    Add-DistributionGroupMember -Identity $GroupName -Member $UserEmail -BypassSecurityGroupManagerCheck

    Write-Host "✅ Successfully added '$UserEmail' to the Exchange group."
        return "Success: '$UserEmail' added to Exchange group."        
}
catch {
    Write-Host "❌ Exchange Online Connection Failed: $_"
    return "Request failed. Error connecting to Exchange Online: $_"
}
    } finally {
        Write-Host "🔌 Disconnecting from Exchange Online..."
        Disconnect-ExchangeOnline -Confirm:$false
    }
}

    # Determine group type
    if ($GroupObject.MailEnabled -eq $true -and $GroupObject.SecurityEnabled -eq $true) {
        Write-Host "This is a Mail-Enabled Security Group. Attempting to add user via Exchange Online..."
        return Add-UserToExchangeGroup -UserEmail $UserEmail -GroupName $GroupName
        Disconnect-MgGraph
    }
    elseif ($GroupObject.MailEnabled -eq $true -and -not ($GroupObject.GroupTypes -contains "Unified")) {
        Write-Host "This is a Distribution List. Attempting to add user via Exchange Online..."
        return Add-UserToExchangeGroup -UserEmail $UserEmail -GroupName $GroupName
        Disconnect-MgGraph
    }
    else {
        Write-Host "The group is eligible for Microsoft Graph member addition."
        return Add-UserToGraphGroup -UserEmail $UserEmail -GroupId $GroupObject.Id
    }

$body = @{
    Message = $message
    TicketId = $TicketId
    ResultCode = $resultCode
    ResultStatus = if ($resultCode -eq 200) { "Success" } else { "Failure" }
} 

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
