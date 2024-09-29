# Temporarily bypass the execution policy for this session
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
# $host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(100, 100)

<#
    ===============================================================
                          Emulator Auto-Downloader
                               Version: v.2.6
                               
    GitHub Repository: https://github.com/dbalcar/Emulator-Auto-downloads

    This script allows you to download various emulators
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
	- CEMU
	- Dolphin
	- AppleWin

    Author: David Balcar
    License: GPL3

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
        Write-Host "emd.ini file created successfully at $iniFilePath."
    } catch {
        Write-Error "Failed to create emd.ini file: $_"
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
        Write-Error "Failed to read emd.ini file."
        return $null
    }

    # Check if the section exists
    if (-not $ini.ContainsKey($section)) {
        Write-Error "Section '$section' not found in the emd.ini file."
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
    $response = Read-Host "Would you like to create the emd.ini file? (y/n)"
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
        Start-Sleep -Seconds 1

        # Restart the script
        & $PSCommandPath
        exit 0
    } else {
        Write-Host "Exiting script. Please create the emd.ini file manually."
        exit 1
    }
}

# Main script starts here
$emupath = Get-EmulatorPath -iniFilePath $iniFilePath

if ($null -eq $emupath) {
    Write-Error "Emulator path is not defined in the INI file. Edit the emd.ini file with the correct path to download the Emulators"
    exit 1
}

# Use the retrieved emulator path in the script logic
$path = $emupath
# $path variable where needed in the script

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

	elseif ($name -eq "CEMU") {
        # CEMU download logic
		# Create the CEMU directory under the defined emupath
		$cemuDownloadPath = Join-Path $emupath "CEMU"

		# Check if the CEMU directory exists, if not, create it
	if (-not (Test-Path -Path $cemuDownloadPath)) {
		Write-Host "Creating directory: $cemuDownloadPath"
		New-Item -Path $cemuDownloadPath -ItemType Directory -Force
}

		# GitHub API URL to get the latest release for the CEMU project
	$apiUrl = "https://api.github.com/repos/cemu-project/Cemu/releases/latest"

		# Define User-Agent header as GitHub API requires it for proper access
	$headers = @{
		"User-Agent" = "Mozilla/5.0"
}

		# Fetch the latest release information from GitHub
	try {
		Write-Host "Fetching latest release information from GitHub..."
		$release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
		Write-Host "Successfully fetched latest release information."
	} catch {
		Write-Error "Failed to retrieve latest release info from GitHub: $_"
		exit 1
}

		# Find the asset that ends with "windows-x64.zip"
	$asset = $release.assets | Where-Object { $_.name -like "*windows-x64.zip" }

	if (-not $asset) {
		Write-Error "File 'windows-x64.zip' not found in the latest release."
		exit 1
}

		# Define the download URL and the target file path
	$downloadUrl = $asset.browser_download_url
	$targetFilePath = Join-Path $cemuDownloadPath $asset.name

	# Debugging: Check if $downloadUrl and $targetFilePath are correctly set
	Write-Host "Download URL: $downloadUrl"
	Write-Host "Target File Path: $targetFilePath"

	# Ensure $downloadUrl and $targetFilePath are not null or empty
	if (-not $downloadUrl) {
		Write-Error "The download URL is null or empty."
		exit 1
}

	if (-not $targetFilePath) {
		Write-Error "The target file path is null or empty."
		exit 1
}

	# Use Start-BitsTransfer to download the file
	try {
		Write-Host "Downloading CEMU release..."
		Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
		Write-Host "Download completed successfully. File saved to $targetFilePath"
	} catch {
		Write-Error "Failed to download 'windows-x64.zip': $_"
		exit 1
}
	}

	elseif ($name -eq "Dolphin") {
        # Dolphin download logic
		# Create the Dolphin directory under the defined emupath
	$dolphinDownloadPath = Join-Path $emupath "Dolphin"

		# Check if the Dolphin directory exists, if not, create it
	if (-not (Test-Path -Path $dolphinDownloadPath)) {
		Write-Host "Creating directory: $dolphinDownloadPath"
		New-Item -Path $dolphinDownloadPath -ItemType Directory -Force
}
		# Define the Dolphin download page URL
	$dolphinUrl = "https://dolphin-emu.org/download/"

		# Fetch the webpage containing the download info
	try {
		Write-Host "Fetching the Dolphin download page..."
		$webpage = Invoke-WebRequest -Uri $dolphinUrl -UseBasicParsing
		Write-Host "Successfully fetched the Dolphin download page."
	} catch {
		Write-Error "Failed to fetch Dolphin download page: $_"
		exit 1
}

		# Parse the webpage to find the first link with the file name that ends with "x64.7z" under "Development versions"
	$downloadLink = $webpage.Links | Where-Object { $_.href -match "x64.7z" } | Select-Object -First 1

	if (-not $downloadLink) {
		Write-Error "Could not find a download link for 'x64.7z'."
		exit 1
}

		# Check if the link is relative (doesn't start with 'http' or 'https')
	if ($downloadLink.href -notmatch "^https?://") {
		# If it's relative, construct the full URL
		$downloadUrl = "https://dolphin-emu.org" + $downloadLink.href
	} else {
		# If it's already an absolute URL, just use it
    $downloadUrl = $downloadLink.href
}

		# Extract the file name from the link
	$fileName = [System.IO.Path]::GetFileName($downloadUrl)

		# Define the target file path with the filename
	$targetFilePath = Join-Path $dolphinDownloadPath $fileName

		# Debugging: Check if $downloadUrl and $targetFilePath are correctly set
	Write-Host "Download URL: $downloadUrl"
	Write-Host "Target File Path: $targetFilePath"

		# Use Start-BitsTransfer to download the file
	try {
		Write-Host "Downloading the Dolphin emulator release..."
		Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
		Write-Host "Download completed successfully. File saved to $targetFilePath"
	} catch {
		Write-Error "Failed to download 'x64.7z': $_"
}
	}
	
	elseif ($name -eq "AppleWin") {
        # AppleWin download logic
		# Append the 'AppleWin' folder to the base path
	$applewinDownloadPath = Join-Path $emupath "AppleWin"

		# Check if the AppleWin directory exists, if not, create it
	if (-not (Test-Path -Path $applewinDownloadPath)) {
		Write-Host "Creating directory: $applewinDownloadPath"
		New-Item -Path $applewinDownloadPath -ItemType Directory -Force
}
		# GitHub API URL to get the latest release for the AppleWin project
	$apiUrl = "https://api.github.com/repos/AppleWin/AppleWin/releases/latest"

		# Define User-Agent header as GitHub API requires it for proper access
	$headers = @{
		"User-Agent" = "Mozilla/5.0"
}
		# Fetch the latest release information from GitHub
	try {
		Write-Host "Fetching latest release information from GitHub..."
		$release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
		Write-Host "Successfully fetched latest release information."
	} catch {
		Write-Error "Failed to retrieve latest release info from GitHub: $_"
		exit 1
}
		# Find the asset that starts with "applewin"
	$asset = $release.assets | Where-Object { $_.name -like "applewin*" }

	if (-not $asset) {
		Write-Error "No file starting with 'applewin' found in the latest release."
		exit 1
}
		# Define the download URL and the target file path
	$downloadUrl = $asset.browser_download_url
	$targetFilePath = Join-Path $applewinDownloadPath $asset.name

		# Debugging: Check if $downloadUrl and $targetFilePath are correctly set
		Write-Host "Download URL: $downloadUrl"
		Write-Host "Target File Path: $targetFilePath"

		# Ensure $downloadUrl and $targetFilePath are not null or empty
	if (-not $downloadUrl) {
		Write-Error "The download URL is null or empty."
		exit 1
}
	if (-not $targetFilePath) {
		Write-Error "The target file path is null or empty."
		exit 1
}
		# Use Start-BitsTransfer to download the file
	try {
		Write-Host "Downloading AppleWin release..."
		Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
		Write-Host "Download completed successfully. File saved to $targetFilePath"
	} catch {
		Write-Error "Failed to download 'AppleWin': $_"
		exit 1
}
	}
	elseif ($name -eq "Lime3DS") {
        # Lime3DS download logic
		# Append the 'Lime3DS' folder to the base path
	$lime3DSDownloadPath = Join-Path $emupath "Lime3DS"

		# Check if the Lime3DS directory exists, if not, create it
	if (-not (Test-Path -Path $lime3DSDownloadPath)) {
			Write-Host "Creating directory: $lime3DSDownloadPath"
    New-Item -Path $lime3DSDownloadPath -ItemType Directory -Force
}
		# GitHub API URL to get the latest release for the Lime3DS project
	$apiUrl = "https://api.github.com/repos/Lime3DS/Lime3DS/releases/latest"

		# Define User-Agent header as GitHub API requires it for proper access
	$headers = @{
    "User-Agent" = "Mozilla/5.0"
}
		# Fetch the latest release information from GitHub
	try {
		Write-Host "Fetching latest release information from GitHub..."
		$release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
		Write-Host "Successfully fetched latest release information."
	} catch {
		Write-Error "Failed to retrieve latest release info from GitHub: $_"
		exit 1
}
		# Filter for assets that end with 'msys2.zip' and 'msvc.zip'
	$assetsToDownload = $release.assets | Where-Object { $_.name -match "(msys2\.zip|msvc\.zip)" }

	if (-not $assetsToDownload) {
		Write-Error "No files ending with 'msys2.zip' or 'msvc.zip' found in the latest release."
		exit 1
}
		# Loop through the assets and download each one
	foreach ($asset in $assetsToDownload) {
    $downloadUrl = $asset.browser_download_url
    $fileName = $asset.name
    $targetFilePath = Join-Path $lime3DSDownloadPath $fileName

		# Debugging: Check if $downloadUrl and $targetFilePath are correctly set
    Write-Host "Download URL: $downloadUrl"
    Write-Host "Target File Path: $targetFilePath"

		# Ensure $downloadUrl and $targetFilePath are not null or empty
    if (-not $downloadUrl) {
        Write-Error "The download URL is null or empty."
        exit 1
    }
    if (-not $targetFilePath) {
        Write-Error "The target file path is null or empty."
        exit 1
    }
    # Use Start-BitsTransfer to download the file
    try {
        Write-Host "Downloading $fileName..."
        Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
        Write-Host "Download completed successfully. File saved to $targetFilePath"
    } catch {
        Write-Error "Failed to download '$fileName': $_"
        exit 1
    }
}

Write-Host "All files downloaded successfully."

}
}


  
Write-Host "
             ########                               ########             
         ##------------+#                       #+------------##         
       #----#-######-#----#                   #------######------#       
     #----#------------#----#################----##----##----##----#     
    #---#------###------#----------------------+#----#    #-----#---#    
    +--#-------###--------#-------------------#------#    #------#--+    
   #--#--------###--------++-----------------++--##----##----##---#--#   
   #--#---##############---#---####---####---#-#    #------#    #-#--#   
   #--#---##############---#---#..-------#---#-#    #------#    #-#--#   
  ----#--------###---------#-----------------#--####---##---####--#----  
  #----#-------###--------#-------------------#------#    #------#----#  
  #-----#------###-------#---------------------#-----#    #-----#-----#  
  #-------#------------#----++++++++++++++++++---#----####----#-------#  
 #---#-------########----+++++++++++++++++++++++----########--------#--# 
 #---#-----------------++++###################++++------------------#--# 
 #--#-----------------+++#                     #+++-----------------#--# 
 +--+----------------++#                         #++-------------------+ 
#---#--------------+++#                           #+++--------------+#--#
#--+--------------++#                               #++--------------#--#
#+--------------+++#                                 #+++--------------+#
#++------------++#+                                   +#++------------++#
 #+++++-----++++#                                       #++++-----+++++# 
  ##++++++++++##                                         ##++++++++++##  
     ###++###                                               ##+++###     "

# Function to display the menu
function Show-Menu {
    Clear-Host
    Write-Host "
             ########                               ########             
         ##------------+#                       #+------------##         
       #----#-######-#----#                   #------######------#       
     #----#------------#----#################----##----##----##----#     
    #---#------###------#----------------------+#----#    #-----#---#    
    +--#-------###--------#-------------------#------#    #------#--+    
   #--#--------###--------++-----------------++--##----##----##---#--#   
   #--#---##############---#---####---####---#-#    #------#    #-#--#   
   #--#---##############---#---#..-------#---#-#    #------#    #-#--#   
  ----#--------###---------#-----------------#--####---##---####--#----  
  #----#-------###--------#-------------------#------#    #------#----#  
  #-----#------###-------#---------------------#-----#    #-----#-----#  
  #-------#------------#----++++++++++++++++++---#----####----#-------#  
 #---#-------########----+++++++++++++++++++++++----########--------#--# 
 #---#-----------------++++###################++++------------------#--# 
 #--#-----------------+++#                     #+++-----------------#--# 
 +--+----------------++#                         #++-------------------+ 
#---#--------------+++#                           #+++--------------+#--#
#--+--------------++#                               #++--------------#--#
#+--------------+++#                                 #+++--------------+#
#++------------++#+                                   +#++------------++#
 #+++++-----++++#                                       #++++-----+++++# 
  ##++++++++++##                                         ##++++++++++##  
     ###++###                                               ##+++###     "
	 
	Write-Host "`n`n`nWelcome to the Emulator Auto Downloader"
    Write-Host "https://github.com/dbalcar/Emulator-Auto-downloads"
    Write-Host "Emulator download path: $path"
    Write-Host ""
    Write-Host "Select an option:"
    Write-Host ""
    Write-Host "1. AppleWin          9. PPSSPP"
    Write-Host "2. BigPEmu          10. Redream"
    Write-Host "3. CEMU             11. RPCS3"
    Write-Host "4. Dolphin          12. Ryujinx"
    Write-Host "5. Duckstation      13. Vita3K"
    Write-Host "6. Lime3DS          14. XEMU"
    Write-Host "7. MAME             15. XENIA"
    Write-Host "8. PCSX2" 
    Write-Host ""
    Write-Host "'all' to download all emulators"
    Write-Host "'exit' to exit"
    Write-Host ""
}

# Main script loop
$exit = $false
while (-not $exit) {
    Show-Menu
    $choice = Read-Host "Choose the emulator to download (1-15, 'all' to download all, or 'exit' to quit)"
    
    # Input validation: if it's a number between 1 and 15, cast to int; otherwise, make lowercase
    if ($choice -match '^\d+$') {
        $choice = [int]$choice
    } else {
        $choice = $choice.ToLower()
    }

    # Handle user input
    switch ($choice) {
        1  { Download-Emulator -name "AppleWin" }
        2  { Download-Emulator -name "BigPEmu" }
        3  { Download-Emulator -name "CEMU" }
        4  { Download-Emulator -name "Dolphin" }
        5  { Download-Emulator -name "Duckstation" }
        6  { Download-Emulator -name "Lime3DS" }
        7  { Download-Emulator -name "MAME" }
        8  { Download-Emulator -name "PCSX2" }
        9  { Download-Emulator -name "PPSSPP" }
        10 { Download-Emulator -name "Redream" }
        11 { Download-Emulator -name "RPCS3" }
        12 { Download-Emulator -name "Ryujinx" }
        13 { Download-Emulator -name "Vita3K" }
        14 { Download-Emulator -name "XEMU" }
        15 { Download-Emulator -name "XENIA" }

        # Download all emulators
        "all" {
            foreach ($emulator in @("AppleWin", "BigPEmu", "CEMU", "Duckstation", "Dolphin", "Lime3DS", "MAME", "PCSX2", "PPSSPP", "Redream", "RPCS3", "Ryujinx", "Vita3K", "XEMU", "XENIA")) {
                Download-Emulator -name $emulator
            }
        }

        # Exit option
        "exit" {
            Write-Host "Exiting..."
            $exit = $true
        }

        # Default case for invalid input
        default {
            Write-Host "Invalid choice. Please enter a number between 1 and 15, or type 'all' to download all, or 'exit' to quit."
        }
    }
}
