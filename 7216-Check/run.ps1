using namespace System.Net

param($Request, $TriggerMetadata)

# Run some PowerShell logic (replace this with your actual function logic)
$randomNumbers = 1..5 | ForEach-Object { Get-Random -Minimum 10 -Maximum 100 }
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Convert the results into an HTML format
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Function Webpage</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078D4; }
        pre { background: #f4f4f4; padding: 10px; border-radius: 5px; }
        button { padding: 10px 20px; font-size: 16px; }
    </style>
    <script>
        function refreshPage() {
            window.location.reload();
        }
    </script>
</head>
<body>
    <h1>Azure Function Webpage</h1>
    <p>Generated at: <strong>$timestamp</strong></p>
    <p>Random Numbers:</p>
    <pre>$($randomNumbers -join ", ")</pre>
    <button onclick="refreshPage()">Run Again</button>
</body>
</html>
"@

# Return response as HTML
Push-OutputBinding -Name Response -Value @{
    StatusCode = 200
    Headers = @{ "Content-Type" = "text/html" }
    Body = $htmlContent
}
