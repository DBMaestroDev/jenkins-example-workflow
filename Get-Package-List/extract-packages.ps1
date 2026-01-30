param(
    [string]$FilePath
)

# Read input (file or stdin)
if ($FilePath) {
    if (-not (Test-Path -LiteralPath $FilePath)) {
        Write-Error "File not found: $FilePath"
        exit 2
    }
    $text = Get-Content -Raw -LiteralPath $FilePath
} else {
    $text = [Console]::In.ReadToEnd()
}

# Try to detect if this is a clean JSON file or mixed log output
# If it starts with '[' it's likely clean JSON; otherwise extract the array
$trimmed = $text.TrimStart()

if ($trimmed.StartsWith('[')) {
    # Direct JSON array - use as-is
    $jsonText = $text
} else {
    # Mixed log output - extract JSON array starting with "[{"
    $m = [regex]::Match($text, '\[\s*\{(?s).*\}\s*\]')
    if (-not $m.Success) {
        Write-Error "No JSON array found in input."
        exit 1
    }
    $jsonText = $m.Value
}

# Parse and filter JSON
try {
    $items = $jsonText | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Failed to parse JSON: $_`n$jsonText"
    exit 1
}

# Filter where IsEnabled is true and display requested fields
$items |
    Where-Object { $_.IsEnabled -eq $true } |
    Select-Object Name, @{Name='Deployed';Expression={$_.State}}, IsAdhocPackage, TestResult |
    Format-Table -AutoSize
