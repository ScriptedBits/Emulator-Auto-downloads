# Function to download the latest version of RPCS3
function Download-Latest-RPCS3 {
    # Define the compatibility URL
    $compatibilityUrl = "https://rpcs3.net/compatibility?b"

    # Fetch the content of the compatibility page
    $pageContent = Invoke-WebRequest -Uri $compatibilityUrl -UseBasicParsing

    # Extract the download URL for the latest Windows version
    $downloadUrl = $pageContent.Links |
        Where-Object { $_.href -match "win64\.7z" } |
        Select-Object -First 1 |
        ForEach-Object { $_.href }

    # If the URL is relative, prepend the base URL
    if ($downloadUrl -notmatch "^https?://") {
        $downloadUrl = "https://rpcs3.net" + $downloadUrl
    }

    # Extract the filename from the download URL
    $fileName = [System.IO.Path]::GetFileName($downloadUrl)
    $downloadPath = "N:\emulator-updates\RPCS3\$fileName"

    # Check if directory exists, if not, create it
    $directory = [System.IO.Path]::GetDirectoryName($downloadPath)
    if (-not (Test-Path -Path $directory)) {
        Write-Host "Creating directory $directory..."
        New-Item -ItemType Directory -Path $directory
    }

    # Download the file
    Write-Host "Downloading RPCS3 from $downloadUrl to $downloadPath..."
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
        Write-Host "RPCS3 downloaded to $downloadPath"
    }
    catch {
        Write-Host "Failed to download RPCS3: $($_)"
    }
}

# Execute the function
Download-Latest-RPCS3
