# Local test script to verify ServiceNow API connectivity with SSL/TLS bypass
param(
    [string]$TaskId = "TASK0000001",
    [string]$ServiceNowUser = "jenkins_user",
    [string]$ServiceNowPassword = '193],nvWyUZgSGXy}5Oizn;XQ%<OlH.40I3hBXw9lR@!Rg[XHviJf]&bl.NG}*qBrnJ[:$s*R#EpkK>85iCBaGSL.oU0jHpo,n%:'
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ServiceNow API Local Test with SSL/TLS Handling" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ==============================================================================
# SSL/TLS CERTIFICATE HANDLING - SOLUTION
# ==============================================================================
Write-Host ""
Write-Host "[SSL/TLS TEST] Configuring Certificate Validation" -ForegroundColor Yellow

# Bypass certificate validation (for environments with self-signed certs)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Force TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Disable certificate revocation list checking
[System.Net.ServicePointManager]::CheckCertificateRevocationList = $false

Write-Host "Certificate validation bypassed" -ForegroundColor Green
Write-Host "TLS 1.2 enabled" -ForegroundColor Green
Write-Host "CRL checking disabled" -ForegroundColor Green

$endpoint = "https://dev221769.service-now.com"
$table = "sc_task"

Write-Host ""
Write-Host "[TEST 1] Testing API Connectivity" -ForegroundColor Yellow
Write-Host "Endpoint: $endpoint"
Write-Host "Table: $table"
Write-Host "Task ID: $TaskId"

# Build the URL with proper query encoding
$queryValue = [Uri]::EscapeDataString("number=$TaskId")
$fieldsValue = [Uri]::EscapeDataString("number,state,short_description,sys_id,parent")
$url = "$endpoint/api/now/table/$table`?sysparm_query=$queryValue`&sysparm_fields=$fieldsValue`&sysparm_limit=1`&sysparm_display_value=true"

Write-Host ""
Write-Host "Built URL: $url" -ForegroundColor Gray

# Create credential object
Write-Host ""
Write-Host "[TEST 2] Creating Credential Object" -ForegroundColor Yellow
$securePassword = ConvertTo-SecureString $ServiceNowPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($ServiceNowUser, $securePassword)
Write-Host "SUCCESS: Credential object created" -ForegroundColor Green

# Set headers
$headers = @{
    "Accept" = "application/json"
}
Write-Host ""
Write-Host "[TEST 3] Preparing Headers" -ForegroundColor Yellow
Write-Host "Headers: Accept = application/json" -ForegroundColor Gray

# Make the API call
Write-Host ""
Write-Host "[TEST 4] Making ServiceNow API Call" -ForegroundColor Yellow
Write-Host "Method: GET" -ForegroundColor Gray

try {
    Write-Host ""
    Write-Host "Calling using System.Net.WebClient..." -ForegroundColor Gray
    
    # Use WebClient which handles SSL differently than Invoke-RestMethod
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11
    [System.Net.ServicePointManager]::CheckCertificateRevocationList = $false
    
    $webClient = New-Object System.Net.WebClient
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$ServiceNowUser`:$ServiceNowPassword"))
    $webClient.Headers.Add("Authorization", "Basic $auth")
    $webClient.Headers.Add("Accept", "application/json")
    
    $curlOutput = $webClient.DownloadString($url)
    $response = $curlOutput | ConvertFrom-Json

    Write-Host ""
    Write-Host "SUCCESS: API Call Successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[TEST 5] Response Analysis" -ForegroundColor Yellow
    
    if ($response.result -and $response.result.Count -gt 0) {
        Write-Host "Found 1 result" -ForegroundColor Green
        $result = $response.result[0]
        
        Write-Host ""
        Write-Host "Task Details:" -ForegroundColor Cyan
        Write-Host "  Number: $($result.number)" -ForegroundColor Gray
        Write-Host "  State: $($result.state)" -ForegroundColor Gray
        Write-Host "  Short Description: $($result.short_description)" -ForegroundColor Gray
        Write-Host "  Sys ID: $($result.sys_id)" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "Parent Information:" -ForegroundColor Cyan
        if ($result.parent -and $result.parent.display_value) {
            Write-Host "  Parent Display Value: $($result.parent.display_value)" -ForegroundColor Green
            Write-Host "  Parent Value: $($result.parent.value)" -ForegroundColor Gray
        } else {
            Write-Host "  No parent found" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Full Response (JSON):" -ForegroundColor Gray
        Write-Host ($response | ConvertTo-Json) -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "SUCCESS: ALL TESTS PASSED" -ForegroundColor Green
        Write-Host "API is working with SSL/TLS bypass!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        
    } else {
        Write-Host "ERROR: No results found for Task ID $TaskId" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: API Call Failed!" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "CONFIGURATION NEEDED FOR JENKINSFILE" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Add to all PowerShell script blocks:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { " + '$' + "true }" -ForegroundColor Cyan
    Write-Host "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12" -ForegroundColor Cyan
    Write-Host "[System.Net.ServicePointManager]::CheckCertificateRevocationList = " + '$' + "false" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Use withCredentials with string binding for endpoint:" -ForegroundColor Gray
    Write-Host 'withCredentials([string(credentialsId: "servicenow-endpoint", variable: "SERVICENOW_ENDPOINT")])' -ForegroundColor Cyan
    
    exit 1
}
