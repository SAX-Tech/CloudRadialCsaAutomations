using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Get Group function triggered."

$resultCode = 200
$message = ""


    #Connect to Graph
    $secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
    $credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

    Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $env:Ms365_TenantId
    get-mggroup -sort displayName
