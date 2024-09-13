# Get the current working directory
$currentPath = Get-Location

# Define the INI file path dynamically from the current directory
$iniFilePath = Join-Path $currentPath "emd.ini"

# Function to read the INI file into a hashtable
function Read-IniFile {
    param (
        [string]$filePath
    )

    if (-not (Test-Path $filePath)) {
        Write-Error "INI file not found at $filePath"
        return $null
    }

    $ini = @{}
    $section = ""
    foreach ($line in Get-Content $filePath) {
        $line = $line.Trim()
        if ($line -match "^\[(.+)\]$") {
            $section = $matches[1]
            if (-not $ini.ContainsKey($section)) {
                $ini[$section] = @{}
            }
        }
        elseif ($line -match "^(.*?)\s*=\s*(.*?)$") {
            $key, $value = $matches[1], $matches[2]
            $ini[$section][$key] = $value
        }
    }

    return $ini
}

# Function to get the emulator path from the INI file
function Get-EmulatorPath {
    param (
        [string]$iniFilePath,
        [string]$key = "emupath",          # Default key to search for is 'emupath'
        [string]$section = "Emulators"     # Default section is 'Emulators'
    )

    # Read the INI file
    $ini = Read-IniFile -filePath $iniFilePath

    if ($null -eq $ini) {
        Write-Error "Failed to read INI file."
        return $null
    }

    # Check if the section exists
    if (-not $ini.ContainsKey($section)) {
        Write-Error "Section '$section' not found in the INI file."
        return $null
    }

    # Check if the key exists in the section
    if (-not $ini[$section].ContainsKey($key)) {
        Write-Error "Key '$key' not found in section '$section'."
        return $null
    }

    # Return the path associated with the key
    return $ini[$section][$key]
}

# Main script starts here
$emupath = Get-EmulatorPath -iniFilePath $iniFilePath

if ($null -eq $emupath) {
    Write-Error "Emulator path could not be retrieved from the INI file."
    exit 1
}

# Use the retrieved emulator path in your script logic
# Assuming you want to replace the "N:\*\" with $emupath
$path = $emupath

# Now you can use the $path variable where needed in your script
Write-Host "Using emulator path: $path"

# Example usage in your script
# Assuming somewhere in your script, you have this:
# 'path = "N:\*\"' --> and you want to replace this with $path

Write-Host "Setting path to: $path"





# Define the URLs and download paths
$emulators = @{
    "Vita3K" = @{
        "url" = "https://github.com/Vita3K/Vita3K/releases/download/continuous/windows-latest.zip"
        "path" = "$path\Vita3K\Vita3K-windows-latest.zip"
        "prefix" = "Vita3K-"
    }
    "XENIA" = @{
        "url" = "https://github.com/xenia-canary/xenia-canary/releases/download/experimental/xenia_canary.zip"
        "path" = "$path\XENIA\xenia_canary.zip"
        "prefix" = "XENIA-"
    }
    "XEMU" = @{
        "baseUrl" = "https://github.com/xemu-project/xemu/releases/download/"
        "version" = "v0.7.126"  # Current known version
        "file" = "xemu-win-release.zip"
        "basePath" = "$path\XEMU\"
        "prefix" = "XEMU-"
    }
    "Ryujinx" = @{
        "baseUrl" = "https://github.com/Ryujinx/release-channel-master/releases/download/"
        "version" = "1.1.1330"  # Current known version
        "filePrefix" = "ryujinx-"
        "fileSuffix" = "-win_x64.zip"
        "basePath" = "$path\Ryujinx\"
        "prefix" = "Ryujinx-"
    }
    "Redream" = @{
        "baseUrl" = "https://redream.io/download/"
        "version" = "v1.5.0-1120"  # Current known version
        "filePrefix" = "redream.x86_64-windows-"
        "fileSuffix" = ".zip"
        "basePath" = "$path\Redream\"
        "prefix" = "Redream-"
    }
    "PSX2" = @{
        "baseUrl" = "https://github.com/PCSX2/pcsx2/releases/download/"
        "version" = "v1.7.5901"  # Current known version
        "fileSuffix" = "-windows-x64-Qt.7z"
        "basePath" = "$path\PSX2\"
        "prefix" = "PSX2-"
    }
    "PPSSPP" = @{
        "baseUrl" = "https://builds.ppsspp.org/builds/"
        "version" = "v1.17.1-762-gcfcca0ed1"  # Current known version
        "file" = "ppsspp_win.zip"
        "basePath" = "$path\PPSSPP\"
        "prefix" = "PPSSPP-"
    }
    "MAME" = @{
        "baseUrl" = "https://github.com/mamedev/mame/releases/"
        "version" = "mame0266"  # Current known version
        "file" = "mame0266b_64bit.exe"
        "basePath" = "$path\MAME\"
        "prefix" = "MAME-"
    }
    "Duckstation" = @{
        "url" = "https://github.com/stenzek/duckstation/releases/download/latest/duckstation-windows-x64-release.zip"
        "path" = "$path\Duckstation\duckstation-windows-x64-release.zip"
        "prefix" = "Duckstation-"
    }
    "BigPEmu" = @{
        "baseUrl" = "https://www.richwhitehouse.com/jaguar/builds/"
        "version" = "114"  # Current known version
        "filePrefix" = "BigPEmu_"
        "fileSuffix" = ".zip"
        "basePath" = "$path\BigPEmu\"
        "prefix" = "BigPEmu-"
    }
    "RPCS3" = @{
        "compatibilityUrl" = "https://rpcs3.net/compatibility?b"
        "basePath" = "$path\RPCS3\"
    }
}

# Function to download a file
function Download-Emulator {
    param (
        [string]$name
    )

    # Initialize variables
    $url = $null
    $path = $null

    if ($name -eq "XEMU") {
        # Get the latest version from the GitHub releases API
        $apiUrl = "https://api.github.com/repos/xemu-project/xemu/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $latestVersion = $response.tag_name

        # Check if the latest version is greater than the current known version
        if ($latestVersion -gt $emulators[$name]["version"]) {
            $emulators[$name]["version"] = $latestVersion
        }

        $url = $emulators[$name]["baseUrl"] + $emulators[$name]["version"] + "/" + $emulators[$name]["file"]
        $path = $emulators[$name]["basePath"] + $emulators[$name]["prefix"] + $emulators[$name]["version"] + ".zip"
    }
    elseif ($name -eq "Ryujinx") {
        # Get the latest version from the GitHub releases API
        $apiUrl = "https://api.github.com/repos/Ryujinx/release-channel-master/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $latestVersion = $response.tag_name.Split("/")[-1].Split("-")[1]

        # Check if the latest version is greater than the current known version
        if ($latestVersion -gt $emulators[$name]["version"]) {
            $emulators[$name]["version"] = $latestVersion
        }

        $url = $emulators[$name]["baseUrl"] + $emulators[$name]["version"] + "/" + $emulators[$name]["filePrefix"] + $emulators[$name]["version"] + $emulators[$name]["fileSuffix"]
        $path = $emulators[$name]["basePath"] + $emulators[$name]["prefix"] + $emulators[$name]["version"] + ".zip"
    }
    elseif ($name -eq "Redream") {
        # Get the latest version from the Redream download page
        $latestVersion = (Invoke-WebRequest -Uri "https://redream.io/download" -UseBasicParsing).Links |
            Where-Object { $_.href -match "redream\.x86_64-windows-(v[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-g[0-9a-f]+)\.zip" } |
            Select-Object -ExpandProperty href |
            ForEach-Object { $_ -replace ".*/redream\.x86_64-windows-(v[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-g[0-9a-f]+)\.zip", '$1' } |
            Sort-Object { $_ -replace '[^\d]', '' } |
            Select-Object -Last 1

        # Check if the latest version is greater than the current known version
        if ($latestVersion -gt $emulators[$name]["version"]) {
            $emulators[$name]["version"] = $latestVersion
        }

        $url = $emulators[$name]["baseUrl"] + "redream.x86_64-windows-" + $emulators[$name]["version"] + $emulators[$name]["fileSuffix"]
        $path = $emulators[$name]["basePath"] + $emulators[$name]["prefix"] + $emulators[$name]["version"] + ".zip"
    }
    elseif ($name -eq "PSX2") {
        # Get the latest version from the GitHub releases API
        $apiUrl = "https://api.github.com/repos/PCSX2/pcsx2/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $latestVersion = $response.tag_name

        # Check if the latest version is greater than the current known version
        if ($latestVersion -gt $emulators[$name]["version"]) {
            $emulators[$name]["version"] = $latestVersion
        }

        $url = $emulators[$name]["baseUrl"] + $emulators[$name]["version"] + "/" + $response.assets | Where-Object { $_.name -match "\.7z" } | Select-Object -ExpandProperty browser_download_url
        $path = $emulators[$name]["basePath"] + $emulators[$name]["prefix"] + $emulators[$name]["version"] + ".7z"
    Write-Host $Uri
	Write-Host $url
	}
    elseif ($name -eq "PPSSPP") {
        # Get the latest version from the PPSSPP builds page
        $latestVersion = (Invoke-WebRequest -Uri "https://builds.ppsspp.org/builds" -UseBasicParsing).Links |
            Where-Object { $_.href -match "v([\d\.]+-\d+)-g[0-9a-f]+/ppsspp_win.zip" } |
            Select-Object -ExpandProperty href |
            ForEach-Object { $_ -replace ".*/v([\d\.]+-\d+)-g[0-9a-f]+/ppsspp_win.zip", '$1' } |
            Sort-Object { $_ -replace '[^\d]', '' } |
            Select-Object -Last 1

        # Check if the latest version is greater than the current known version
        if ($latestVersion -gt $emulators[$name]["version"]) {
            $emulators[$name]["version"] = $latestVersion
        }

        $url = $emulators[$name]["baseUrl"] + $emulators[$name]["version"] + "/ppsspp_win.zip"
        $path = $emulators[$name]["basePath"] + $emulators[$name]["prefix"] + $emulators[$name]["version"] + ".zip"
    }
    
	 if ($name -eq "MAME") {

# Function to download the first asset from the latest release using Start-BitsTransfer
function Download-FirstAssetFromLatestMAMERelease {
    param (
        [string]$path  # Path where the file will be saved
    )

    # GitHub API URL for the latest release
    $apiUrl = "https://api.github.com/repos/mamedev/mame/releases/latest"

    # Headers for GitHub API request (necessary for GitHub API to work correctly)
    $headers = @{
        "User-Agent" = "Mozilla/5.0"
        "Accept" = "application/vnd.github.v3+json"
    }

    # Send a GET request to the GitHub API to get the latest release info
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers
    } catch {
        Write-Error "Failed to get latest release information from GitHub."
        return
    }

    # Extract the asset information from the latest release
    $assets = $response.assets

    if (-not $assets -or $assets.Count -eq 0) {
        Write-Error "No assets found in the latest release."
        return
    }

    # Get the first asset
    $firstAsset = $assets[0]

    # Extract the download URL and file name of the first asset
    $downloadUrl = $firstAsset.browser_download_url
    $fileName = $firstAsset.name

    # Define the local path to save the file (path provided by the user)
    $outputFilePath = Join-Path -Path $path -ChildPath $fileName

    # Check if the directory exists, if not, create it
    if (-not (Test-Path -Path $path)) {
        Write-Host "Creating directory: $path"
        New-Item -Path $path -ItemType Directory -Force
    }

    Write-Host "Downloading the first asset of the latest MAME release: $fileName"
    Write-Host "Download URL: $downloadUrl"
    Write-Host "Saving file to: $outputFilePath"

    # Download the file using Start-BitsTransfer for faster performance
    try {
        Start-BitsTransfer -Source $downloadUrl -Destination $outputFilePath
        Write-Host "Download completed successfully. File saved as $outputFilePath"
    } catch {
        Write-Error "Failed to download the file using Start-BitsTransfer."
    }
}


# Call the function to download the first asset from the latest release
Download-FirstAssetFromLatestMAMERelease -path $emupath\MAME\


	}
    elseif ($name -eq "BigPEmu") {
        # Function to download the first .zip file from the provided URL
function Download-FirstZipFromRichWhitehouse {
    param (
        [string]$downloadPageUrl,  # The URL of the page to scrape
        [string]$emupath           # The base emupath where the .zip file will be saved
    )

    # Define the full path to save the file (emupath\BigEmu)
    $savePath = Join-Path -Path $emupath -ChildPath "BigEmu"

    # Fetch the HTML content of the page
    try {
        Write-Host "Fetching the webpage: $downloadPageUrl"
        $htmlContent = Invoke-WebRequest -Uri $downloadPageUrl -UseBasicParsing
    } catch {
        Write-Error "Failed to fetch the webpage. Please check the URL and your network connection."
        return
    }

    # Use regex to find all .zip file links in the HTML content
    $zipLinks = Select-String -InputObject $htmlContent.Content -Pattern 'href="([^"]+\.zip)"' -AllMatches

    if (-not $zipLinks.Matches) {
        Write-Error "No .zip files found on the page."
        return
    }

    # Extract the first .zip file link
    $firstZipUrl = $zipLinks.Matches[0].Groups[1].Value

    # Handle relative URLs by constructing the full URL
    if ($firstZipUrl -notmatch "^https?:\/\/") {
        $uri = New-Object System.Uri($downloadPageUrl)
        $firstZipUrl = [System.IO.Path]::Combine($uri.GetLeftPart("Scheme"), $firstZipUrl)
    }

    Write-Host "Found .zip file URL: $firstZipUrl"

    # Create the destination folder if it does not exist
    if (-not (Test-Path -Path $savePath)) {
        Write-Host "Creating directory: $savePath"
        New-Item -Path $savePath -ItemType Directory -Force
    }

    # Extract the file name from the URL
    $fileName = [System.IO.Path]::GetFileName($firstZipUrl)

    # Define the full file path where the .zip file will be saved
    $outputFilePath = Join-Path -Path $savePath -ChildPath $fileName

    Write-Host "Downloading the .zip file to: $outputFilePath"

    # Download the .zip file
    try {
        Start-BitsTransfer -Source $firstZipUrl -Destination $outputFilePath
        Write-Host "Download completed successfully. File saved as $outputFilePath"
    } catch {
        Write-Error "Failed to download the .zip file."
    }
}

# Example: Set the URL and $emupath variable where the file will be saved
$downloadPageUrl = "https://www.richwhitehouse.com/jaguar/index.php?content=download"

# Call the function to download the first .zip file and save it to $emupath\BigEmu
Download-FirstZipFromRichWhitehouse -downloadPageUrl $downloadPageUrl -emupath $emupath
		
		
		
    }
    elseif ($name -eq "Duckstation") {
        $url = $emulators[$name]["url"]
        $path = $emulators[$name]["path"]
    }
    elseif ($name -eq "RPCS3") {
        # Define the compatibility URL
        $compatibilityUrl = $emulators[$name]["compatibilityUrl"]

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
        $path = $emulators[$name]["basePath"] + $fileName
        $url = $downloadUrl
    }
    else {
        $url = $emulators[$name]["url"]
        $path = $emulators[$name]["path"]
    }

    $directory = [System.IO.Path]::GetDirectoryName($path)

    # Check if directory exists, if not, create it
    if (-not (Test-Path -Path $directory)) {
        Write-Host "Creating directory $directory..."
        New-Item -ItemType Directory -Path $directory
    }

    Write-Host "Downloading $name from $url to $path..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $path
        Write-Host "$name downloaded to $path"
    }
    catch {
        Write-Host "Failed to download $name ${_}"
    }
}

# Function to display the menu
function Show-Menu {
    Write-Host "Select an option:"
    Write-Host "1. Download Vita3K"
    Write-Host "2. Download XENIA"
    Write-Host "3. Download XEMU"
    Write-Host "4. Download Ryujinx"
    Write-Host "5. Download Redream"
    Write-Host "6. Download PSX2"
    Write-Host "7. Download PPSSPP"
    Write-Host "8. Download MAME"
    Write-Host "9. Download Duckstation"
    Write-Host "10. Download BigPEmu"
    Write-Host "11. Download RPCS3"
    Write-Host "12. Download All"
    Write-Host "13. Exit"
}

# Main script loop
$exit = $false
while (-not $exit) {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-13)"
    
    switch ($choice) {
        1 {
            Download-Emulator -name "Vita3K"
        }
        2 {
            Download-Emulator -name "XENIA"
        }
        3 {
            Download-Emulator -name "XEMU"
        }
        4 {
            Download-Emulator -name "Ryujinx"
        }
        5 {
            Download-Emulator -name "Redream"
        }
        6 {
            Download-Emulator -name "PSX2"
        }
        7 {
            Download-Emulator -name "PPSSPP"
        }
        8 {
            Download-Emulator -name "MAME"
        }
        9 {
            Download-Emulator -name "Duckstation"
        }
        10 {
            Download-Emulator -name "BigPEmu"
        }
        11 {
            Download-Emulator -name "RPCS3"
        }
        12 {
            foreach ($emulator in $emulators.Keys) {
                Download-Emulator -name $emulator
            }
        }
        13 {
            Write-Host "Exiting..."
            $exit = $true
        }
        default {
            Write-Host "Invalid choice. Please enter a number between 1 and 13."
        }
    }
}
