# Function to compare Dolphin versions
function Compare-DolphinVersion {
    param (
        [string]$version1,
        [string]$version2
    )

    # Extract numeric parts and compare
    $v1 = [int]($version1 -replace 'dolphin-master-5.0-', '' -replace '-x64', '')
    $v2 = [int]($version2 -replace 'dolphin-master-5.0-', '' -replace '-x64', '')

    return $v1 -gt $v2
}

# Function to download the latest Dolphin development version if it is greater than a specified version
function Download-Latest-Dolphin {
    # Define the base URL and the current version
    $baseUrl = "https://dolphin-emu.org/download/"
    $currentVersion = "dolphin-master-5.0-21728-x64"

    # Fetch the content of the download page
    $pageContent = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing

    # Extract the download URL for the latest Windows x64 development version
    $htmlContent = $pageContent.Content

    # Use regex to find the links under the "Development versions" section
    $developmentSection = $htmlContent -split '<h2>Development versions</h2>', 2
    if ($developmentSection.Count -lt 2) {
        Write-Host "Development versions section not found."
        return
    }

    $links = $developmentSection[1] -split '<h2>', 2 | Select-Object -First 1
    $downloadLinks = Select-String -InputObject $links -Pattern 'href="([^"]*dolphin-master-5\.0-[0-9]+-x64\.7z)"' -AllMatches |
        ForEach-Object { $_.Matches } |
        ForEach-Object { $_.Groups[1].Value }

    # Find the latest version greater than the current version
    $latestVersionUrl = $null
    foreach ($link in $downloadLinks) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($link)
        if (Compare-DolphinVersion -version1 $fileName -version2 $currentVersion) {
            $latestVersionUrl = "https://dolphin-emu.org" + $link
            break
        }
    }

    # Check if a valid download URL was found
    if (-not $latestVersionUrl) {
        Write-Host "No new version found greater than $currentVersion."
        return
    }

    # Extract the filename from the download URL
    $fileName = [System.IO.Path]::GetFileName($latestVersionUrl)
    $downloadPath = "N:\emulator-updates\Dolphin\$fileName"

    # Check if directory exists, if not, create it
    $directory = [System.IO.Path]::GetDirectoryName($downloadPath)
    if (-not (Test-Path -Path $directory)) {
        Write-Host "Creating directory $directory..."
        New-Item -ItemType Directory -Path $directory
    }

    # Download the file
    Write-Host "Downloading Dolphin from $latestVersionUrl to $downloadPath..."
    try {
        Invoke-WebRequest -Uri $latestVersionUrl -OutFile $downloadPath
        Write-Host "Dolphin downloaded to $downloadPath"
    }
    catch {
        Write-Host "Failed to download Dolphin: ${_}"
    }
}

# Execute the function
Download-Latest-Dolphin
