# Local test script to verify ServiceNow API connectivity and query format
param(
    [string]$ChangeRequestId = "CHG0030002",
    [string]$ServiceNowUser = "jenkins_user",
    [string]$ServiceNowPassword = 'd9gWr:+}kRI7W>x77q%dd<aK@5575wA2E[i#(]e+7!cQiTpHw5tVdDJMG$P1siu5u(XvEp{9=d_w;v(dzo(6@uv4MWS@rFM!{$Xu'
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ServiceNow API Local Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$endpoint = "https://dev252278.service-now.com"
$table = "change_request"

Write-Host "" 
Write-Host "[TEST 1] Testing API Connectivity" -ForegroundColor Yellow
Write-Host "Endpoint: $endpoint"
Write-Host "Table: $table"
Write-Host "Change Request ID: $ChangeRequestId"

# Build the URL with proper query encoding
$queryValue = [Uri]::EscapeDataString("number=$ChangeRequestId")
$url = "$endpoint/api/now/table/$table`?sysparm_query=$queryValue&sysparm_limit=1"

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
Write-Host "Credential: Using PSCredential with Basic Auth" -ForegroundColor Gray

try {
    Write-Host ""
    Write-Host "Calling Invoke-RestMethod..." -ForegroundColor Gray
    $response = Invoke-RestMethod -Uri $url -Method Get -Credential $credential -Headers $headers -ErrorAction Stop

    Write-Host ""
    Write-Host "SUCCESS: API Call Successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[TEST 5] Response Analysis" -ForegroundColor Yellow
    
    if ($response.result.Count -gt 0) {
        Write-Host "Found $($response.result.Count) result(s)" -ForegroundColor Green
        $change = $response.result[0]
        
        Write-Host ""
        Write-Host "Change Request Details:" -ForegroundColor Cyan
        Write-Host "  Number: $($change.number)" -ForegroundColor Gray
        Write-Host "  State: $($change.state)" -ForegroundColor Gray
        Write-Host "  Short Description: $($change.short_description)" -ForegroundColor Gray
        Write-Host "  Assignment Group: $($change.assignment_group)" -ForegroundColor Gray
        Write-Host "  Assignment: $($change.assigned_to)" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "Full Response (JSON):" -ForegroundColor Gray
        Write-Host ($change | ConvertTo-Json -Depth 10) -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "SUCCESS: ALL TESTS PASSED" -ForegroundColor Green
        Write-Host "API is working correctly!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        
    } else {
        Write-Host ""
        Write-Host "ERROR: No results found for Change Request ID: $ChangeRequestId" -ForegroundColor Red
        Write-Host "Response body:" -ForegroundColor Gray
        Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor Gray
    }

} catch {
    Write-Host ""
    Write-Host "ERROR: API Call Failed!" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        Write-Host ""
        Write-Host "Response Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        Write-Host "Response Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
        
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            $reader.Close()
            Write-Host ""
            Write-Host "Error Response Body:" -ForegroundColor Gray
            Write-Host $errorBody -ForegroundColor Red
        } catch {
            Write-Host "Could not read error response body" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "FAILED: Check details above" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Test completed at: $(Get-Date)" -ForegroundColor Gray
