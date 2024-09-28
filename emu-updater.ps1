<#
    ===============================================================
                          Emulator Auto-Downloader
                               Version: v.2.1
                               
    GitHub Repository: https://github.com/dbalcar/Emulator-Auto-downloads

    This script automatically downloads and updates various emulators
    from their latest releases hosted on GitHub or official websites.
    
    Supported Emulators:
    - Vita3K
    - XENIA
    - XEMU
    - Ryujinx
    - Redream
    - PCSX2
    - PPSSPP
    - MAME
    - Duckstation
    - BigPEmu
    - RPCS3

    Author: David Balcar
    License:

    For support, visit the repository above.
    ===============================================================
#>

# Load required assembly for folder browsing
Add-Type -AssemblyName System.Windows.Forms

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

# Function to create the INI file if it's missing
function Create-IniFile {
    param (
        [string]$iniFilePath,
        [string]$emupath
    )

    # Content of the INI file
    $content = @"
[Emulators]
emupath = $emupath


# change emupath to your download location example: r:\emulator-updates
# The script will look for this file and get the emupath and append that to the download directory.
# For example, if downloading MAME and the emupath is set to r:\emulator-updates, then the download location will be r:\emulator-updates\MAME
"@

    try {
        # Create the INI file with the specified content
        Set-Content -Path $iniFilePath -Value $content
        Write-Host "INI file created successfully at $iniFilePath."
    } catch {
        Write-Error "Failed to create INI file: $_"
        exit 1
    }
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

# Function to browse for a folder (GUI)
function Browse-Folder {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select a folder for emulator downloads"
    $folderBrowser.ShowNewFolderButton = $true

    $result = $folderBrowser.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    } else {
        return $null
    }
}

# Check if INI file exists
if (-not (Test-Path $iniFilePath)) {
    Write-Warning "INI file not found at $iniFilePath."

    # Ask the user if they want to create the INI file
    $response = Read-Host "Would you like to create the INI file? (y/n)"
    if ($response -eq 'y') {
        # Let the user select the emulator path using a folder browser dialog
        $emupath = Browse-Folder

        if ($null -eq $emupath) {
            Write-Host "No path selected. Exiting script."
            exit 1
        }

        # Create the INI file
        Create-IniFile -iniFilePath $iniFilePath -emupath $emupath

        Write-Host "Restarting the script..."
        Start-Sleep -Seconds 2

        # Restart the script
        & $PSCommandPath
        exit 0
    } else {
        Write-Host "Exiting script. Please create the INI file manually."
        exit 1
    }
}

# Main script starts here
$emupath = Get-EmulatorPath -iniFilePath $iniFilePath

if ($null -eq $emupath) {
    Write-Error "Emulator path is not defined in the INI file. Edit the emd.ini file with the correct path to download the Emulators."
    exit 1
}

# Use the retrieved emulator path in the script logic
# Assuming you want to replace the "N:\*\" with $emupath
$path = $emupath
# Now you can use the $path variable where needed in the script

Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Welcome to the Emulator Downloader"
Write-Host " "
Write-Host "https://github.com/dbalcar/Emulator-Auto-downloads"
Write-Host " "
Write-Host "Using emulator path: $path"
Write-Host "Setting path to: $path"
Write-Host " "


# Main script starts here
$emupath = Get-EmulatorPath -iniFilePath $iniFilePath

if ($null -eq $emupath) {
    Write-Error "Emulator path is not defined in the INI file. Edit the emd.ini file with the correct path to download the Emulators."
    exit 1
}

# Use the retrieved emulator path in the script logic
# Assuming you want to replace the "N:\*\" with $emupath
$path = $emupath
# Now you can use the $path variable where needed in the script

Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Welcome to the Emulator Downloader"
Write-Host " "
Write-Host "https://github.com/dbalcar/Emulator-Auto-downloads"
Write-Host " "
Write-Host "Using emulator path: $path"
Write-Host "Setting path to: $path"
Write-Host " "


# Main script starts here
$emupath = Get-EmulatorPath -iniFilePath $iniFilePath

if ($null -eq $emupath) {
    Write-Error "Emulator path is not defined in the INI file. Edit the emd.ini file with the correct path to download the Emulators"
    exit 1
}

# Use the retrieved emulator path in the script logic
$path = $emupath
#Write-Host ""
#Write-Host ""
#Write-Host "`n`n`nWelcome to the Emulator Downloader"
#Write-Host "https://github.com/dbalcar/Emulator-Auto-downloads"
#Write-Host ""
#Write-Host ""
Write-Host "Using emulator download path: $path"
#Write-Host "Setting path to: $path"
Write-Host ""

# Function to download an emulator
function Download-Emulator {
    param (
        [string]$name
    )

    if ($name -eq "XEMU") {
        # XEMU download logic
        $xemuDownloadPath = Join-Path $emupath "XEMU"
        if (-not (Test-Path -Path $xemuDownloadPath)) {
            Write-Host "Creating directory: $xemuDownloadPath"
            New-Item -Path $xemuDownloadPath -ItemType Directory -Force
        }
        $apiUrl = "https://api.github.com/repos/xemu-project/xemu/releases/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            Write-Host "Successfully fetched release information."
        } catch {
            Write-Error "Failed to retrieve latest release info: $_"
            exit 1
        }

        $version = $release.tag_name
        Write-Host "Latest xemu release version: $version"
        $asset = $release.assets | Where-Object { $_.name -eq "xemu-win-release.zip" }

        if (-not $asset) {
            Write-Error "xemu-win-release.zip not found in the latest release."
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFileName = "xemu-win-release-$version.zip"
        $targetFilePath = Join-Path $xemuDownloadPath $targetFileName

        Write-Host "Downloading xemu-win-release.zip from: $downloadUrl"
        Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Download completed successfully. File saved to $targetFilePath"
        } catch {
            Write-Error "Failed to download xemu-win-release.zip: $_"
        }
    }
    elseif ($name -eq "Ryujinx") {
        # Ryujinx download logic
        $ryujinxDownloadPath = Join-Path $emupath "Ryujinx"
        if (-not (Test-Path -Path $ryujinxDownloadPath)) {
            Write-Host "Creating directory: $ryujinxDownloadPath"
            New-Item -Path $ryujinxDownloadPath -ItemType Directory -Force
        }
        $apiUrl = "https://api.github.com/repos/Ryujinx/release-channel-master/releases/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            Write-Host "Successfully fetched release information."
        } catch {
            Write-Error "Failed to retrieve latest release info: $_"
            exit 1
        }

        $version = $release.tag_name
        Write-Host "Latest Ryujinx release version: $version"
        $asset = $release.assets | Where-Object { $_.name -like "ryujinx*$version*win_x64.zip" }

        if (-not $asset) {
            Write-Error "File with the name 'ryujinx' containing version '$version' and ending in 'win_x64.zip' not found in the latest release."
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFileName = "Ryujinx-$version-win_x64.zip"
        $targetFilePath = Join-Path $ryujinxDownloadPath $targetFileName

        Write-Host "Downloading Ryujinx from: $downloadUrl"
        Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Download completed successfully. File saved to $targetFilePath"
        } catch {
            Write-Error "Failed to download $($asset.name): $_"
        }
    }
    elseif ($name -eq "XENIA") {
        # XENIA download logic
        $xeniaDownloadPath = Join-Path $emupath "XENIA"
        if (-not (Test-Path -Path $xeniaDownloadPath)) {
            Write-Host "Creating directory: $xeniaDownloadPath"
            New-Item -Path $xeniaDownloadPath -ItemType Directory -Force
        }
        $apiUrl = "https://api.github.com/repos/xenia-canary/xenia-canary/releases/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            Write-Host "Successfully fetched release information."
        } catch {
            Write-Error "Failed to retrieve latest release info: $_"
            exit 1
        }

        $asset = $release.assets | Where-Object { $_.name -eq "xenia_canary.zip" }

        if (-not $asset) {
            Write-Error "File 'xenia_canary.zip' not found in the latest release."
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFilePath = Join-Path $xeniaDownloadPath "xenia_canary.zip"

        Write-Host "Downloading XENIA from: $downloadUrl"
        Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Download completed successfully. File saved to $targetFilePath"
        } catch {
            Write-Error "Failed to download $($asset.name): $_"
        }
    }
    elseif ($name -eq "Vita3K") {
        # Vita3K download logic
        $vita3kDownloadPath = Join-Path $emupath "Vita3K"
        if (-not (Test-Path -Path $vita3kDownloadPath)) {
            Write-Host "Creating directory: $vita3kDownloadPath"
            New-Item -Path $vita3kDownloadPath -ItemType Directory -Force
        }

        $apiUrl = "https://api.github.com/repos/Vita3K/Vita3K/releases/tags/continuous"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            Write-Host "Successfully fetched release information."
        } catch {
            Write-Error "Failed to retrieve latest release info: $_"
            exit 1
        }

        $asset = $release.assets | Where-Object { $_.name -eq "windows-latest.zip" }

        if (-not $asset) {
            Write-Error "File 'windows-latest.zip' not found in the continuous release."
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFilePath = Join-Path $vita3kDownloadPath "windows-latest.zip"

        Write-Host "Downloading Vita3K from: $downloadUrl"
        Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Download completed successfully. File saved to $targetFilePath"
        } catch {
            Write-Error "Failed to download $($asset.name): $_"
        }
    }
    elseif ($name -eq "Redream") {
        # Redream download logic
        $redreamDownloadPath = Join-Path $emupath "Redream"
        if (-not (Test-Path -Path $redreamDownloadPath)) {
            Write-Host "Creating directory: $redreamDownloadPath"
            New-Item -Path $redreamDownloadPath -ItemType Directory -Force
        }

        $redreamUrl = "https://redream.io/download"

        try {
            $webpage = Invoke-WebRequest -Uri $redreamUrl -UseBasicParsing
            Write-Host "Successfully fetched Redream download page."
        } catch {
            Write-Error "Failed to fetch Redream download page: $_"
            exit 1
        }

        $downloadLinks = $webpage.Links | Where-Object { $_.href -match "redream.x86_64-windows.*.zip" }

        if ($downloadLinks.Count -lt 2) {
            Write-Error "Could not find the second download link for 'redream.x86_64-windows'."
            exit 1
        }

        $secondDownloadLink = $downloadLinks[1].href

        if ($secondDownloadLink -notmatch "^https?://") {
            $uri = [System.Uri]::new($redreamUrl)
            $secondDownloadLink = [System.Uri]::new($uri, $secondDownloadLink).AbsoluteUri
        }

        $fileName = [System.IO.Path]::GetFileName($secondDownloadLink)
        $targetFilePath = Join-Path $redreamDownloadPath $fileName

        Write-Host "Downloading Redream from: $secondDownloadLink"
        Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $secondDownloadLink -Destination $targetFilePath
            Write-Host "Download completed successfully. File saved to $targetFilePath"
        } catch {
            Write-Error "Failed to download '$fileName': $_"
        }
    }
    elseif ($name -eq "PCSX2") {
        # PCSX2 download logic
        $pcsx2DownloadPath = Join-Path $emupath "PCSX2"
        if (-not (Test-Path -Path $pcsx2DownloadPath)) {
            Write-Host "Creating directory: $pcsx2DownloadPath"
            New-Item -Path $pcsx2DownloadPath -ItemType Directory -Force
        }

        $apiUrl = "https://api.github.com/repos/PCSX2/pcsx2/releases"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $releases = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            Write-Host "Successfully fetched releases information."
        } catch {
            Write-Error "Failed to retrieve releases info: $_"
            exit 1
        }

        $preRelease = $releases | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1

        if (-not $preRelease) {
            Write-Error "No pre-release version found."
            exit 1
        }

        Write-Host "Latest pre-release version: $($preRelease.tag_name)"
        $asset = $preRelease.assets | Where-Object { $_.name -like "*windows-x64-Qt.7z" }

        if (-not $asset) {
            Write-Error "File ending with 'windows-x64-Qt.7z' not found in the latest pre-release."
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFilePath = Join-Path $pcsx2DownloadPath $asset.name

        Write-Host "Downloading PCSX2 from: $downloadUrl"
        Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Download completed successfully. File saved to $targetFilePath"
        } catch {
            Write-Error "Failed to download $($asset.name): $_"
        }
    }
    elseif ($name -eq "PPSSPP") {
    # PPSSPP download logic
    # Append the 'PPSSPP' folder to the base path
    $ppssppDownloadPath = Join-Path $emupath "PPSSPP"

    # Check if the PPSSPP directory exists, if not, create it
    if (-not (Test-Path -Path $ppssppDownloadPath)) {
        Write-Host "Creating directory: $ppssppDownloadPath"
        New-Item -Path $ppssppDownloadPath -ItemType Directory -Force
    }

    # Define the PPSSPP builds page URL
    $ppssppBuildsUrl = "https://builds.ppsspp.org/"

    # Fetch the webpage containing the builds info
    try {
        $webpage = Invoke-WebRequest -Uri $ppssppBuildsUrl -UseBasicParsing
        Write-Host "Successfully fetched PPSSPP builds webpage."
    } catch {
        Write-Error "Failed to fetch PPSSPP builds webpage: $_"
        exit 1
    }

    # Use regex to extract the latest PPSSPP build version link (we are looking for something like 'v1.17.1-1187-g6b383e40e0/ppsspp_win.zip')
    $regexPattern = 'href="(\/builds\/v[\d\.\-\w]+\/ppsspp_win\.zip)"'
    $versionMatch = Select-String -InputObject $webpage.Content -Pattern $regexPattern -AllMatches

    if (-not $versionMatch.Matches) {
        Write-Error "Could not extract the PPSSPP download link from the webpage."
        #exit 1
    }

    # Extract the first match for the download URL part
    $relativeDownloadUrl = $versionMatch.Matches[0].Groups[1].Value

    # Construct the full download URL
    $downloadUrl = "https://builds.ppsspp.org" + $relativeDownloadUrl

    # Extract the file name from the link
    $fileName = "ppsspp_win.zip"

    # Define the target file path with the filename
    $targetFilePath = Join-Path $ppssppDownloadPath $fileName

    # Debugging: Check if $downloadUrl and $targetFilePath are correctly set
    Write-Host "Download URL: $downloadUrl"
    Write-Host "Target File Path: $targetFilePath"

    # Use Start-BitsTransfer to download the file
    try {
        Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
        Write-Host "Download completed successfully. File saved to $targetFilePath"
    } catch {
        Write-Error "Failed to download '$fileName': $_"
    }


}

    elseif ($name -eq "MAME") {
        # MAME download logic
        $mameDownloadPath = Join-Path $emupath "MAME"
        if (-not (Test-Path -Path $mameDownloadPath)) {
            Write-Host "Creating directory: $mameDownloadPath"
            New-Item -Path $mameDownloadPath -ItemType Directory -Force
        }

        $apiUrl = "https://api.github.com/repos/mamedev/mame/releases/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0"; "Accept" = "application/vnd.github.v3+json" }

        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        } catch {
            Write-Error "Failed to get latest release information from GitHub."
            return
        }

        $assets = $response.assets
        if (-not $assets -or $assets.Count -eq 0) {
            Write-Error "No assets found in the latest release."
            return
        }

        $firstAsset = $assets[0]
        $downloadUrl = $firstAsset.browser_download_url
        $fileName = $firstAsset.name
        $outputFilePath = Join-Path -Path $mameDownloadPath -ChildPath $fileName

        Write-Host "Downloading MAME from: $downloadUrl"
        Write-Host "Saving file to: $outputFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $outputFilePath
            Write-Host "Download completed successfully. File saved as $outputFilePath"
        } catch {
            Write-Error "Failed to download the file using Start-BitsTransfer."
        }
    }
    elseif ($name -eq "Duckstation") {
        # Duckstation download logic
        $duckstationDownloadPath = Join-Path $emupath "Duckstation"
        if (-not (Test-Path -Path $duckstationDownloadPath)) {
            Write-Host "Creating directory: $duckstationDownloadPath"
            New-Item -Path $duckstationDownloadPath -ItemType Directory -Force
        }

        $apiUrl = "https://api.github.com/repos/stenzek/duckstation/releases/tags/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            Write-Host "Successfully fetched latest Duckstation release information."
        } catch {
            Write-Error "Failed to retrieve latest release info from GitHub: $_"
            exit 1
        }

        $asset = $release.assets | Where-Object { $_.name -eq "duckstation-windows-x64-release.zip" }

        if (-not $asset) {
            Write-Error "File 'duckstation-windows-x64-release.zip' not found in the latest release."
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFilePath = Join-Path $duckstationDownloadPath "duckstation-windows-x64-release.zip"

        Write-Host "Downloading Duckstation from: $downloadUrl"
        Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Download completed successfully. File saved to $targetFilePath"
        } catch {
            Write-Error "Failed to download 'duckstation-windows-x64-release.zip': $_"
        }
    }
    elseif ($name -eq "BigPEmu") {
        # BigPEmu download logic
        $bigPemuDownloadPath = Join-Path $emupath "BigEmu"
        if (-not (Test-Path -Path $bigPemuDownloadPath)) {
            Write-Host "Creating directory: $bigPemuDownloadPath"
            New-Item -Path $bigPemuDownloadPath -ItemType Directory -Force
        }

        $downloadPageUrl = "https://www.richwhitehouse.com/jaguar/index.php?content=download"

        try {
            Write-Host "Fetching the webpage: $downloadPageUrl"
            $htmlContent = Invoke-WebRequest -Uri $downloadPageUrl -UseBasicParsing
        } catch {
            Write-Error "Failed to fetch the webpage. Please check the URL and your network connection."
            return
        }

        $zipLinks = Select-String -InputObject $htmlContent.Content -Pattern 'href="([^"]+\.zip)"' -AllMatches

        if (-not $zipLinks.Matches) {
            Write-Error "No .zip files found on the page."
            return
        }

        $firstZipUrl = $zipLinks.Matches[0].Groups[1].Value

        if ($firstZipUrl -notmatch "^https?:\/\/") {
            $uri = New-Object System.Uri($downloadPageUrl)
            $firstZipUrl = [System.IO.Path]::Combine($uri.GetLeftPart("Scheme"), $firstZipUrl)
        }

        Write-Host "Found .zip file URL: $firstZipUrl"
        $fileName = [System.IO.Path]::GetFileName($firstZipUrl)
        $outputFilePath = Join-Path -Path $bigPemuDownloadPath -ChildPath $fileName

        Write-Host "Downloading BigPEmu from: $firstZipUrl"
        Write-Host "Saving to: $outputFilePath"

        try {
            Start-BitsTransfer -Source $firstZipUrl -Destination $outputFilePath
            Write-Host "Download completed successfully. File saved as $outputFilePath"
        } catch {
            Write-Error "Failed to download the .zip file."
        }
    }
    elseif ($name -eq "RPCS3") {
        # RPCS3 download logic
        $rpcs3DownloadPath = Join-Path $emupath "RPCS3"
        if (-not (Test-Path -Path $rpcs3DownloadPath)) {
            Write-Host "Creating directory: $rpcs3DownloadPath"
            New-Item -Path $rpcs3DownloadPath -ItemType Directory -Force
        }

        $apiUrl = "https://api.github.com/repos/RPCS3/rpcs3-binaries-win/releases/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            Write-Host "Successfully fetched latest RPCS3 release information."
        } catch {
            Write-Error "Failed to retrieve latest release info from GitHub: $_"
            exit 1
        }

        $asset = $release.assets | Where-Object { $_.name -like "*win64.7z" }

        if (-not $asset) {
            Write-Error "File ending with 'win64.7z' not found in the latest release."
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFilePath = Join-Path $rpcs3DownloadPath $asset.name

        Write-Host "Downloading RPCS3 from: $downloadUrl"
        Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Download completed successfully. File saved to $targetFilePath"
        } catch {
            Write-Error "Failed to download '$($asset.name)': $_"
        }
    }
}

# Function to display the menu
function Show-Menu {
	Clear-Host  # Clears the screen before showing the menu
	Write-Host "`n`n`nWelcome to the Emulator Downloader"
	Write-Host "https://github.com/dbalcar/Emulator-Auto-downloads"
	Write-Host "Using emulator path: $path"
	Write-Host ""
	Write-Host ""
	Write-Host "Select an option:"
    Write-Host "1. Download Vita3K"
    Write-Host "2. Download XENIA"
    Write-Host "3. Download XEMU"
    Write-Host "4. Download Ryujinx"
    Write-Host "5. Download Redream"
    Write-Host "6. Download PCSX2"
    Write-Host "7. Download PPSSPP"
    Write-Host "8. Download MAME"
    Write-Host "9. Download Duckstation"
    Write-Host "10. Download BigPEmu"
    Write-Host "11. Download RPCS3"
    Write-Host "12. Download All"
    Write-Host "13. Exit"
}

# Function to display errors, pause, and clear screen
function Handle-Error {
    param (
        [string]$errorMessage
    )
    Write-Error $errorMessage  # Display the error message
    Read-Host -Prompt "Press Enter to continue"  # Pause to let the user read the error
    Clear-Host  # Clear the screen
}

# Main script loop
$exit = $false
while (-not $exit) {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-13)"
    
    switch ($choice) {
        1 { Download-Emulator -name "Vita3K" }
        2 { Download-Emulator -name "XENIA" }
        3 { Download-Emulator -name "XEMU" }
        4 { Download-Emulator -name "Ryujinx" }
        5 { Download-Emulator -name "Redream" }
        6 { Download-Emulator -name "PCSX2" }
        7 { Download-Emulator -name "PPSSPP" }
        8 { Download-Emulator -name "MAME" }
        9 { Download-Emulator -name "Duckstation" }
        10 { Download-Emulator -name "BigPEmu" }
        11 { Download-Emulator -name "RPCS3" }
        12 {
            foreach ($emulator in @("Vita3K", "XENIA", "XEMU", "Ryujinx", "Redream", "PCSX2", "PPSSPP", "MAME", "Duckstation", "BigPEmu", "RPCS3")) {
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
