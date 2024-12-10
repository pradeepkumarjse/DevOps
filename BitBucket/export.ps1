# Configurations
$Username = ""
$Password = ""
$Workspace = ""
$ApiUrl = "https://api.bitbucket.org/2.0/repositories/$Workspace"
$OutputDir = "repos"
$Page = 1

# Create output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

do {
    try {
        # Construct the full API URL for the current page
        $FullApiUrl = $ApiUrl + "?page=" + $Page
        Write-Host "Fetching page $Page from URL: $FullApiUrl"

        # Ensure the correct curl binary is called
        $CurlCommand = @"
& 'curl.exe' -s -u `"${Username}:${Password}`" --request GET --url `"${FullApiUrl}`"
"@

        # Execute the curl command
        $ResponseJson = Invoke-Expression $CurlCommand

        # Parse the JSON response
        $Response = $ResponseJson | ConvertFrom-Json

        # Extract repository slugs
        $RepoSlugs = $Response.values | ForEach-Object { $_.slug }

        # Exit if no repositories are found
        if (-not $RepoSlugs) {
            Write-Host "No more repositories found."
            break
        }

        # Download each repository
foreach ($RepoSlug in $RepoSlugs) {
    Write-Host "Downloading $RepoSlug..."

    # Prepare download URLs
    $ZipUrlMain = "https://bitbucket.org/$Workspace/$RepoSlug/get/main.zip"
    $ZipUrlMaster = "https://bitbucket.org/$Workspace/$RepoSlug/get/master.zip"

    # Get the current date in YYYY-MM-DD format
    $CurrentDate = (Get-Date -Format "yyyy-MM-dd")

    $OutputFile = Join-Path -Path $OutputDir -ChildPath "$RepoSlug-$CurrentDate.zip"

    # Try downloading main.zip
    $CurlCommandMain = @"
& 'curl.exe' -s -w "%{http_code}" -o `"${OutputFile}`" -u `"${Username}:${Password}`" --request GET `"${ZipUrlMaster}`"
"@

    # Execute the curl command and capture the response code
    $HttpResponseMain = Invoke-Expression $CurlCommandMain

    if ($HttpResponseMain -eq "200") {
        Write-Host "Downloaded master.zip for $RepoSlug"
        continue
    } else {
        Write-Host "master.zip not found for $RepoSlug (HTTP $HttpResponseMain). Trying main.zip..."

        # Fallback to downloading master.zip
        $CurlCommandMaster = @"
& 'curl.exe' -s -w "%{http_code}" -o `"${OutputFile}`" -u `"${Username}:${Password}`" --request GET `"${ZipUrlMain}`"
"@

        # Execute the curl command and capture the response code
        $HttpResponseMaster = Invoke-Expression $CurlCommandMaster

        if ($HttpResponseMaster -eq "200") {
            Write-Host "Downloaded main.zip for $RepoSlug"
        } else {
            Write-Host "Failed to download $RepoSlug (HTTP $HttpResponseMaster)"
        }
    }
}

        # Check for the "next" page
        $NextPage = $Response.next
        if (-not $NextPage) {
            Write-Host "All repositories processed."
            break
        }

        # Increment the page number
        $Page++

    } catch {
        Write-Host "Failed to fetch repositories: $($_.Exception.Message)"
        break
    }

} while ($true)

Write-Host "All repositories downloaded."
