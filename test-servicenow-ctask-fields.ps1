param(
    [Parameter(Mandatory=$false)]
    [string]$CtaskId = "CTASK0010001"
)

# ServiceNow configuration
$endpoint = "https://dev221769.service-now.com"
$table = "change_task"

# Credentials
$username = "jenkins_user"
$password = "Passw0rd!Jenkins123"

# Build the URL to get all fields for the change task
$queryValue = [Uri]::EscapeDataString("number=$CtaskId")
$url = $endpoint + "/api/now/table/" + $table + "?sysparm_query=" + $queryValue + "&sysparm_limit=1&sysparm_display_value=true"

Write-Host "Querying change_task fields to find notes field..." -ForegroundColor Cyan
Write-Host ""

# Handle SSL/TLS certificate validation issues
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11
[System.Net.ServicePointManager]::CheckCertificateRevocationList = $false

try {
    $webClient = New-Object System.Net.WebClient
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$username`:$password"))
    $webClient.Headers.Add("Authorization", "Basic $auth")
    $webClient.Headers.Add("Accept", "application/json")
    
    $jsonOutput = $webClient.DownloadString($url)
    $response = $jsonOutput | ConvertFrom-Json
    
    if (!$response.result -or $response.result.Count -eq 0) {
        Write-Host "ERROR: CTASK $CtaskId not found" -ForegroundColor Red
        exit 1
    }
    
    $ctask = $response.result[0]
    
    Write-Host "Available fields containing 'note' or 'comment':" -ForegroundColor Yellow
    Write-Host ""
    
    $ctask | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like "*note*" -or $_.Name -like "*comment*" -or $_.Name -like "*work*" } | ForEach-Object {
        $fieldName = $_.Name
        $fieldValue = $ctask.$fieldName
        Write-Host "Field: $fieldName" -ForegroundColor Green
        Write-Host "  Value: $fieldValue"
        Write-Host ""
    }
    
    Write-Host "All fields in change_task record:" -ForegroundColor Yellow
    Write-Host ""
    $ctask | Get-Member -MemberType NoteProperty | ForEach-Object {
        Write-Host "$($_.Name): $($ctask.$($_.Name))" -ForegroundColor White
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
