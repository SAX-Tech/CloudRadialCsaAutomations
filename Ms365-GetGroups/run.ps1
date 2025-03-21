$groups = Get-MgGroup -Sort "displayName"
Write-Host "Retrieved groups:"

# Output group details to logs
foreach ($group in $groups) {
    Write-Host "Group DisplayName: $($group.DisplayName), Group Id: $($group.Id)"
}
# Create a list of groups
$groupNames = $groups | ForEach-Object { $_.DisplayName }

# Log the group names
Write-Host "Group Names: $($groupNames -join ", ")"

# Optional: You can also output to $message to include in the response if needed.
$message = "Retrieved groups: " + ($groups | ForEach-Object { $_.DisplayName }) -join ", "
# Prepare the response
$response = @{
    groups = $groupNames
}

# Return result code and message
# Return the group data in JSON format
return @{
StatusCode = $resultCode
    Message    = $message
    Body = $response | ConvertTo-Json -Depth 3
}
