using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Get Group function triggered."

# Setup
$resultCode = 200
$message = ""

# Connect to Microsoft Graph
$secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
$credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $env:Ms365_TenantId

# Get groups from O365
$groups = Get-MgGroup -Sort "displayName"
$groupNames = $groups | ForEach-Object { $_.DisplayName }

Write-Host "Retrieved groups: $($groupNames -join ', ')"

# Prepare list in CloudRadial format
$groupChoices = @()
foreach ($name in $groupNames) {
    $groupChoices += @{
        label = $name
        value = $name
    }
}

# Get CloudRadial API token
# Get CloudRadial API token
$tokenUrl = "https://saxtechnology.us.cloudradial.com/api/beta/token"
$formId = "231"
$formUrl = "https://help.saxtechnology.com/app/service/request/$formID"

$clientId = $env:API_USERNAME
$clientSecret = $env:API_PASSWORD

$tokenBody = @{
    clientId = $clientId
    clientSecret = $clientSecret
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $tokenBody
$accessToken = $tokenResponse.access_token

# Get the form
$form = Invoke-RestMethod -Method Get -Uri $formUrl -Headers @{
    Authorization = "Bearer $accessToken"
}

# Update dropdown question (based on question ID)
foreach ($q in $form.questions) {
    if ($q.id -eq "groupSelector") {
        $q.options.choices = $groupChoices
    }
}

# PUT updated form back to CloudRadial
$updatedForm = $form | ConvertTo-Json -Depth 10 -Compress
Invoke-RestMethod -Method Put -Uri $formUrl -Headers @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
} -Body $updatedForm

# Output groups as part of Azure Function response (optional)
$response = @{
    groups = $groupNames
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $response
    ContentType = "application/json"
})
