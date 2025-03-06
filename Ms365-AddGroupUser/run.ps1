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

# DEBUG: Log raw request body
Write-Host "Raw Request Body: $($Request.Body)"

# Ensure the request body is properly converted from JSON
try {
    $Body = $Request.Body | ConvertFrom-Json
} catch {
    Write-Host "Invalid JSON format received."
    $message = "Request failed. Invalid JSON format."
    $resultCode = 500
}

# If JSON was parsed correctly, assign values
if ($resultCode -eq 200) {
    $UserEmail = $Body.UserEmail
    $GroupName = $Body.GroupName
    $TenantId = if ($Body.TenantId) { $Body.TenantId } else { $env:Ms365_TenantId }
    $TicketId = if ($Body.TicketId) { $Body.TicketId } else { "" }
    $SecurityKey = $env:SecurityKey

    # DEBUG: Print extracted values
    Write-Host "Extracted UserEmail: $UserEmail"
    Write-Host "Extracted GroupName: $GroupName"
    Write-Host "Extracted TenantId: $TenantId"
    Write-Host "Extracted TicketId: $TicketId"

    # Validate Security Key
    if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
        Write-Host "Invalid security key"
        $message = "Invalid security key."
        $resultCode = 500
    }

    # Validate required fields
    if (-Not $UserEmail) {
        $message = "UserEmail cannot be blank."
        $resultCode = 500
    }
    if (-Not $GroupName) {
        $message = "GroupName cannot be blank."
        $resultCode = 500
    }
}

# Construct response
$body = @{
    Message = $message
    TicketId = $TicketId
    ResultCode = $resultCode
    ResultStatus = if ($resultCode -eq 200) { "Success" } else { "Failure" }
}

# Send HTTP response
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = if ($resultCode -eq 200) { [HttpStatusCode]::OK } else { [HttpStatusCode]::BadRequest }
    Body = $body
    ContentType = "application/json"
})

