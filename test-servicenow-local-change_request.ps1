# Local test script to verify ServiceNow API connectivity and query format
param(
    [string]$ChangeRequestId = "CHG0030001",
    [string]$ServiceNowUser = "jenkins_user",
    [string]$ServiceNowPassword = '!Q=Ja93@imfR[+g7g8VYB3#TDP3I,G&X9J-7q<Ek.#eqJ*_doL)vAP%%%2{qs85k(8)?K%T0v}N,vfTCWTv(z@1JUz9z@-cp*b4v'
   #[string]$ServiceNowUser = "admin",
   #[string]$ServiceNowPassword = "2QDOdx-vy6-A"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ServiceNow API Local Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$endpoint = "https://dev317594.service-now.com"
$table = "change_request"

Write-Host "" 
Write-Host "[TEST 1] Testing API Connectivity" -ForegroundColor Yellow
Write-Host "Endpoint: $endpoint"
Write-Host "Table: $table"
Write-Host "Change Request ID: $ChangeRequestId"

# Build the URL with proper query encoding
# Limit to fields that jenkins_user should have permission to read
$queryValue = [Uri]::EscapeDataString("number=$ChangeRequestId")
$fieldsValue = [Uri]::EscapeDataString("number,state,short_description,sys_id")
$url = "$endpoint/api/now/table/$table`?sysparm_query=$queryValue&sysparm_fields=$fieldsValue&sysparm_limit=1"

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

$httpStatusCode = $null
$errorType = $null
$errorMessage = $null
$errorDetail = $null

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
        Write-Host "  Sys ID: $($change.sys_id)" -ForegroundColor Gray
        
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
    
    # Capture HTTP status code
    if ($_.Exception.Response) {
        $httpStatusCode = [int]$_.Exception.Response.StatusCode
        Write-Host ""
        Write-Host "HTTP Status Code: $httpStatusCode" -ForegroundColor Red
        Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
        
        # Categorize the error
        if ($httpStatusCode -eq 401) {
            $errorType = "AUTHENTICATION_ERROR"
            Write-Host "Error Type: $errorType - Invalid username or password" -ForegroundColor Red
        } elseif ($httpStatusCode -eq 403) {
            $errorType = "AUTHORIZATION_ERROR"
            Write-Host "Error Type: $errorType - User does not have permission to access this resource" -ForegroundColor Red
        } elseif ($httpStatusCode -eq 404) {
            $errorType = "NOT_FOUND_ERROR"
            Write-Host "Error Type: $errorType - Change request or endpoint not found" -ForegroundColor Red
        } elseif ($httpStatusCode -eq 400) {
            $errorType = "BAD_REQUEST_ERROR"
            Write-Host "Error Type: $errorType - Invalid query parameters or malformed request" -ForegroundColor Red
        } elseif ($httpStatusCode -ge 500) {
            $errorType = "SERVER_ERROR"
            Write-Host "Error Type: $errorType - ServiceNow server error" -ForegroundColor Red
        }
        
        # Try to parse error response body
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            $reader.Close()
            
            Write-Host ""
            Write-Host "Error Response Body:" -ForegroundColor Gray
            Write-Host $errorBody -ForegroundColor Red
            
            # Try to extract error message and detail from JSON response
            try {
                $errorJson = $errorBody | ConvertFrom-Json
                if ($errorJson.error) {
                    $errorMessage = $errorJson.error.message
                    $errorDetail = $errorJson.error.detail
                    Write-Host ""
                    Write-Host "Error Message: $errorMessage" -ForegroundColor Red
                    if ($errorDetail) {
                        Write-Host "Error Detail: $errorDetail" -ForegroundColor Red
                    }
                } elseif ($errorJson.message) {
                    $errorMessage = $errorJson.message
                    $errorDetail = $errorJson.detail
                    Write-Host ""
                    Write-Host "Error Message: $errorMessage" -ForegroundColor Red
                    if ($errorDetail) {
                        Write-Host "Error Detail: $errorDetail" -ForegroundColor Red
                    }
                }
            } catch {
                # Response body is not JSON, display as plain text
            }
        } catch {
            Write-Host "Could not read error response body" -ForegroundColor Gray
        }
    } else {
        # No HTTP response available, likely a network or credential error
        $errorType = "CONNECTIVITY_ERROR"
        $errorMessage = $_.Exception.Message
        Write-Host ""
        Write-Host "Error Type: $errorType" -ForegroundColor Red
        Write-Host "Error Message: $errorMessage" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "FAILED: Check details above" -ForegroundColor Red
    if ($errorType) {
        Write-Host "Error Type Summary: $errorType" -ForegroundColor Red
    }
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Test completed at: $(Get-Date)" -ForegroundColor Gray
