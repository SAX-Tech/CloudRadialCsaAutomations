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

# Output group details to logs
foreach ($group in $groups) {
    Write-Host "Group DisplayName: $($group.DisplayName), Group Id: $($group.Id)"
}

# Optional: You can also output to $message to include in the response if needed.
$message = "Retrieved groups: " + ($groups | ForEach-Object { $_.DisplayName }) -join ", "

# Return result code and message
return @{
    StatusCode = $resultCode
    Message    = $message
}
