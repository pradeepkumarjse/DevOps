# Set variables
$workspace = ""
$username = ""
$accessToken = ""
$backupDir = "D:\BITBUCKET-BACKUP"
$logFile ="D:\BITBUCKET-BACKUP\log.txt"

# Initialize the log file
function Log-Message {
    param (
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timestamp] [$type] $message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

# Start logging
Log-Message "Starting repository backup process..."

# Fetch repository list with pagination
try {
    Log-Message "Fetching repository list from workspace '$workspace' with pagination..."
    $headers = @{
        Authorization = "Bearer $accessToken"
    }
    $apiUrl = "https://api.bitbucket.org/2.0/repositories/$workspace"
    $allRepositories = @()

    do {
        # Fetch current page
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $allRepositories += $response.values
        Log-Message "Fetched ${($response.values).Count} repositories from current page."

        # Check for the next page
        $apiUrl = $response.next
    } while ($apiUrl)

    Log-Message "Successfully fetched all ${$allRepositories.Count} repositories."
} catch {
    Log-Message "Error fetching repository list: $_" "ERROR"
    exit 1
}

# Create backup directory
if (!(Test-Path -Path $backupDir)) {
    try {
        New-Item -ItemType Directory -Path $backupDir
        Log-Message "Created backup directory at '$backupDir'."
    } catch {
        Log-Message "Error creating backup directory: $_" "ERROR"
        exit 1
    }
} else {
    Log-Message "Backup directory already exists at '$backupDir'."
}

# Clone and zip each repository
foreach ($repo in $allRepositories) {
    $repoName = $repo.slug
    $repoUrl = $repo.links.clone | Where-Object { $_.name -eq "https" } | Select-Object -ExpandProperty href
    $repoBackupPath = Join-Path $backupDir $repoName
    $zipFilePath = Join-Path $backupDir "$repoName.zip"

    Log-Message "Processing repository '$repoName' from '$repoUrl'..."

    try {
        # Clone the repository
        git clone "https://x-token-auth:dshgghd@bitbucket.org/$workspace/$repoName.git"
        Log-Message "Successfully cloned repository '$repoName' to '$repoBackupPath'."
        
        # Zip the cloned repository
        Compress-Archive -Path "$repoBackupPath\*" -DestinationPath $zipFilePath -Force
        Log-Message "Successfully zipped repository '$repoName' to '$zipFilePath'."

        # Optionally, delete the cloned folder after zipping
        Remove-Item -Recurse -Force $repoBackupPath
        Log-Message "Deleted cloned repository folder '$repoBackupPath'."
    } catch {
        Log-Message "Error processing repository '$repoName': $_" "ERROR"
    }
}

Log-Message "Repository backup process completed."
