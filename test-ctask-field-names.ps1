param(
    [Parameter(Mandatory=$false)]
    [string]$CtaskId = "CTASK0010001"
)

$endpoint = "https://dev221769.service-now.com"
$username = "jenkins_user"
$password = '193],nvWyUZgSGXy}5Oizn;XQ%<OlH.40I3hBXw9lR@!Rg[XHviJf]&bl.NG}*qBrnJ[:$s*R#EpkK>85iCBaGSL.oU0jHpo,n%:'

# Get the full record to see all fields
$queryValue = [Uri]::EscapeDataString("number=$CtaskId")
$url = $endpoint + "/api/now/table/change_task?sysparm_query=$queryValue&sysparm_limit=1"

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11
[System.Net.ServicePointManager]::CheckCertificateRevocationList = $false

$webClient = New-Object System.Net.WebClient
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$username`:$password"))
$webClient.Headers.Add("Authorization", "Basic $auth")
$webClient.Headers.Add("Accept", "application/json")

$jsonOutput = $webClient.DownloadString($url)
$response = $jsonOutput | ConvertFrom-Json
$record = $response.result[0]

Write-Host "Fields in change_task that might contain notes:" -ForegroundColor Cyan
Write-Host ""

$record | Get-Member -MemberType NoteProperty | ForEach-Object {
    $fieldName = $_.Name
    $fieldValue = $record.$fieldName
    
    # Only show fields with content or fields that might be for notes
    if ($fieldValue -and ($fieldName -like "*comment*" -or $fieldName -like "*note*" -or $fieldName -like "*additional*" -or $fieldName -like "*work*")) {
        Write-Host "$fieldName`:" -ForegroundColor Green
        if ($fieldValue.GetType().Name -eq "String" -and $fieldValue.Length -gt 100) {
            Write-Host "  $($fieldValue.Substring(0,100))..." -ForegroundColor White
        } else {
            Write-Host "  $fieldValue" -ForegroundColor White
        }
        Write-Host ""
    }
}

Write-Host "All available field names:" -ForegroundColor Yellow
$record | Get-Member -MemberType NoteProperty | ForEach-Object { Write-Host "  $($_.Name)" }
