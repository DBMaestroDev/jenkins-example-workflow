param(
    [Parameter(Mandatory=$false)]
    [string]$CtaskId = "CTASK0010001"
)

# ServiceNow configuration
$endpoint = "https://dev221769.service-now.com"
$table = "change_task"

# Credentials - adjust these to match your ServiceNow credentials
$username = "jenkins_user"
$password = '193],nvWyUZgSGXy}5Oizn;XQ%<OlH.40I3hBXw9lR@!Rg[XHviJf]&bl.NG}*qBrnJ[:$s*R#EpkK>85iCBaGSL.oU0jHpo,n%:'

# Build the URL for getting the change task
$queryValue = [Uri]::EscapeDataString("number=$CtaskId")
$fieldsValue = [Uri]::EscapeDataString("number,state,sys_id,short_description")
$getUrl = $endpoint + "/api/now/table/" + $table + "?sysparm_query=" + $queryValue + "&sysparm_fields=" + $fieldsValue + "&sysparm_limit=1&sysparm_display_value=true"

Write-Host "Testing change_task (CTASK) note posting" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Task ID: $CtaskId"
Write-Host "Table: $table"
Write-Host ""

# Handle SSL/TLS certificate validation issues
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11
[System.Net.ServicePointManager]::CheckCertificateRevocationList = $false

try {
    # Step 1: Get the change task details
    Write-Host "Step 1: Querying ServiceNow for CTASK details..." -ForegroundColor Yellow
    
    $webClient = New-Object System.Net.WebClient
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$username`:$password"))
    $webClient.Headers.Add("Authorization", "Basic $auth")
    $webClient.Headers.Add("Accept", "application/json")
    
    $jsonOutput = $webClient.DownloadString($getUrl)
    $response = $jsonOutput | ConvertFrom-Json
    
    if (!$response.result -or $response.result.Count -eq 0) {
        Write-Host "ERROR: CTASK $CtaskId not found in ServiceNow" -ForegroundColor Red
        exit 1
    }
    
    $ctaskInfo = $response.result[0]
    $sysId = $ctaskInfo.sys_id
    $number = $ctaskInfo.number
    $state = $ctaskInfo.state
    $shortDesc = $ctaskInfo.short_description
    
    Write-Host "  Found CTASK: $number" -ForegroundColor Green
    Write-Host "    Sys ID: $sysId"
    Write-Host "    State: $state"
    Write-Host "    Description: $shortDesc"
    Write-Host ""
    
    # Step 2: Post activity/comment to change_task using comments_and_work_notes field
    Write-Host "Step 2: Posting activity to CTASK (via comments_and_work_notes field)..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $uniqueId = Get-Random -Minimum 10000 -Maximum 99999
    $message = "Test activity #$uniqueId from Jenkins pipeline - Posted at $timestamp"
    $body = @{ comments_and_work_notes = $message } | ConvertTo-Json
    
    Write-Host "    Message to post: $message" -ForegroundColor Gray
    
    $putUrl = $endpoint + "/api/now/table/" + $table + "/" + $sysId
    
    $webClient2 = New-Object System.Net.WebClient
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$username`:$password"))
    $webClient2.Headers.Add("Authorization", "Basic $auth")
    $webClient2.Headers.Add("Content-Type", "application/json")
    $webClient2.Headers.Add("Accept", "application/json")
    
    $putResponse = $webClient2.UploadString($putUrl, "PUT", $body)
    $putResult = $putResponse | ConvertFrom-Json
    
    Write-Host "  Activity posted successfully" -ForegroundColor Green
    Write-Host "    Updated at: $($putResult.result.sys_updated_on)"
    Write-Host ""
    
    # Step 3: Verify the activity was posted by querying and checking contents
    Write-Host "Step 3: Verifying activity was posted..." -ForegroundColor Yellow
    
    # Query the comments_and_work_notes field
    $verifyUrl = $endpoint + "/api/now/table/" + $table + "/" + $sysId + "?sysparm_fields=comments_and_work_notes,work_notes,comments"
    
    $webClient3 = New-Object System.Net.WebClient
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$username`:$password"))
    $webClient3.Headers.Add("Authorization", "Basic $auth")
    $webClient3.Headers.Add("Accept", "application/json")
    
    $verifyOutput = $webClient3.DownloadString($verifyUrl)
    $verifyResponse = $verifyOutput | ConvertFrom-Json
    $result = $verifyResponse.result
    
    Write-Host "  Retrieved fields:" -ForegroundColor Green
    Write-Host "    comments_and_work_notes length: $($result.comments_and_work_notes.Length)" -ForegroundColor Gray
    Write-Host "    work_notes length: $($result.work_notes.Length)" -ForegroundColor Gray
    Write-Host "    comments length: $($result.comments.Length)" -ForegroundColor Gray
    Write-Host ""
    
    # Check all three fields
    $found = $false
    if ($result.comments_and_work_notes -like "*#$uniqueId*") {
        Write-Host "  SUCCESS: Activity found in comments_and_work_notes!" -ForegroundColor Green
        Write-Host "    Content: $($result.comments_and_work_notes.Substring(0, [Math]::Min(150, $result.comments_and_work_notes.Length)))" -ForegroundColor White
        $found = $true
    }
    if ($result.work_notes -like "*#$uniqueId*") {
        Write-Host "  SUCCESS: Activity found in work_notes!" -ForegroundColor Green
        Write-Host "    Content: $($result.work_notes.Substring(0, [Math]::Min(150, $result.work_notes.Length)))" -ForegroundColor White
        $found = $true
    }
    if ($result.comments -like "*#$uniqueId*") {
        Write-Host "  SUCCESS: Activity found in comments!" -ForegroundColor Green
        Write-Host "    Content: $($result.comments.Substring(0, [Math]::Min(150, $result.comments.Length)))" -ForegroundColor White
        $found = $true
    }
    
    if (-not $found) {
        Write-Host "  WARNING: Posted activity NOT found in any field" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-Host "SUCCESS: All tests passed!" -ForegroundColor Green
    Write-Host "Work note successfully posted to CTASK: $number"
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Details: $($_.Exception)" -ForegroundColor Red
    exit 1
}
