using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Get Group function triggered."

$resultCode = 200
$message = ""

# Connect to Graph
$secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
$credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $env:Ms365_TenantId

# Get the groups and log the results
$groups = Get-MgGroup -Sort "displayName"
Write-Host "Retrieved groups:"

# Create a list of groups
$groupNames = $groups | ForEach-Object { $_.DisplayName }

# Log the group names
Write-Host "Group Names: $($groupNames -join ", ")"

# Prepare the response
$response = @{
    groups = $groupNames
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $response
    ContentType = "application/json"
})
