# $host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(100, 100)
# Define the log file location
$logFile = "logfile.txt"
# Start transcript logging - This is for debugging
#Start-Transcript -Path $logFile -Append
$scriptVersion = "v2.9.2"
<#
   ===============================================================
                          Emulator Auto-Downloader
          
	This script downloads the latest stable / dev releases of emulators 
    for Windows x86_64, including:
	
	AppleWin
	BigPEmu
	CEMU
	Dolphin
	Duckstation
	Lime3DS
	MAME
	melonDS
	PCSX2
	PPSSPP
	Redream
	RetroArch
	RPCS3
	Ryujinx - not working
	shadps4
	TeknoParrot
	Vita3K
	VICE
	WinUAE
	XEMU
	XENIA 
    
	from their official websites or github.

    GitHub Repository: https://github.com/dbalcar/Emulator-Auto-downloads

    Copyright (c) 2024 David Balcar

    All emulator names and software are the property of their respective
    owners. This script is provided as-is without any warranty or 
    guarantee of functionality.

    The author of this script is not affiliated with any the emulator
    projects or any emulator developers. This script is for personal 
    use only to automate the process of downloading files from public 
    sources.
    
    Author: David Balcar
    License: GPL3

    For any support or issues, visit the github respository
    ===============================================================
#>

# Clear the screen and set the console background to black
$Host.UI.RawUI.BackgroundColor = "Black"

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
        Write-Host "emd.ini file created successfully at $iniFilePath."  -ForegroundColor "Green" -BackgroundColor "Black"
    } catch {
        Write-Error "Failed to create emd.ini file: $_"  -ForegroundColor "Red" -BackgroundColor "Black"
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
        Write-Error "Key '$key' not found in section '$section'." -ForegroundColor "Red" -BackgroundColor "Black"
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
            Write-Host "No path selected. Exiting..."
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
        Write-Host "Exiting script. Please create the emd.ini file manually." -ForegroundColor "Red" -BackgroundColor "Black"
        exit 1
    }
}

# Main script starts here
$emupath = Get-EmulatorPath -iniFilePath $iniFilePath

if ($null -eq $emupath) {
    Write-Error "Emulator path is not defined in the INI file. Edit the emd.ini file with the correct path to download the Emulators"  -ForegroundColor "Red" -BackgroundColor "Black"
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
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
        $xemuDownloadPath = Join-Path $emupath "XEMU"
        if (-not (Test-Path -Path $xemuDownloadPath)) {
            Write-Host "Creating directory: $xemuDownloadPath"
            New-Item -Path $xemuDownloadPath -ItemType Directory -Force
        }
        $apiUrl = "https://api.github.com/repos/xemu-project/xemu/releases/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            #Write-Host "Successfully fetched release information."
        } catch {
            Write-Error "Failed to retrieve latest release info: $_"
            exit 1
        }

        $version = $release.tag_name
        #Write-Host "Latest xemu release version: $version"
        $asset = $release.assets | Where-Object { $_.name -eq "xemu-win-release.zip" }

        if (-not $asset) {
            Write-Error "xemu-win-release.zip not found in the latest release."
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFileName = "xemu-win-release-$version.zip"
        $targetFilePath = Join-Path $xemuDownloadPath $targetFileName

        #Write-Host "Downloading xemu-win-release.zip from: $downloadUrl"
        #Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "XEMU download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download xemu-win-release.zip: $_" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
elseif ($name -eq "Ryujinx") {
        # Ryujinx download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
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
            #exit 1
        }

        $version = $release.tag_name
        #Write-Host "Latest Ryujinx release version: $version"
        $asset = $release.assets | Where-Object { $_.name -like "ryujinx*$version*win_x64.zip" }

        if (-not $asset) {
            Write-Error "File with the name 'ryujinx' containing version '$version' and ending in 'win_x64.zip' not found in the latest release."
            #exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFileName = "Ryujinx-$version-win_x64.zip"
        $targetFilePath = Join-Path $ryujinxDownloadPath $targetFileName

        #Write-Host "Downloading Ryujinx from: $downloadUrl"
        #Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Ryujinx download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
elseif ($name -eq "XENIA") {
        # XENIA download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
        $xeniaDownloadPath = Join-Path $emupath "XENIA"
        if (-not (Test-Path -Path $xeniaDownloadPath)) {
            Write-Host "Creating directory: $xeniaDownloadPath"
            New-Item -Path $xeniaDownloadPath -ItemType Directory -Force
        }
        $apiUrl = "https://api.github.com/repos/xenia-canary/xenia-canary/releases/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            #Write-Host "Successfully fetched release information."
        } catch {
            Write-Error "Failed to retrieve latest release info: $_"
            #exit 1
        }

        $asset = $release.assets | Where-Object { $_.name -eq "xenia_canary.zip" }

        if (-not $asset) {
            Write-Error "File 'xenia_canary.zip' not found in the latest release."
            #exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFilePath = Join-Path $xeniaDownloadPath "xenia_canary.zip"

        # Write-Host "Downloading XENIA from: $downloadUrl"
        # Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "XENIA download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
    elseif ($name -eq "Vita3K") {
        # Vita3K download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
        $vita3kDownloadPath = Join-Path $emupath "Vita3K"
        if (-not (Test-Path -Path $vita3kDownloadPath)) {
            #Write-Host "Creating directory: $vita3kDownloadPath"
            New-Item -Path $vita3kDownloadPath -ItemType Directory -Force
        }

        $apiUrl = "https://api.github.com/repos/Vita3K/Vita3K/releases/tags/continuous"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            #Write-Host "Successfully fetched release information."
        } catch {
            Write-Error "Failed to retrieve latest release info: $_"
            #exit 1
        }

        $asset = $release.assets | Where-Object { $_.name -eq "windows-latest.zip" }

        if (-not $asset) {
            Write-Error "File 'windows-latest.zip' not found in the continuous release."
            #exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFilePath = Join-Path $vita3kDownloadPath "windows-latest.zip"

        # Write-Host "Downloading Vita3K from: $downloadUrl"
        # Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Vita3K download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
    elseif ($name -eq "Redream") {
        # Redream download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
        $redreamDownloadPath = Join-Path $emupath "Redream"
        if (-not (Test-Path -Path $redreamDownloadPath)) {
            #Write-Host "Creating directory: $redreamDownloadPath"
            New-Item -Path $redreamDownloadPath -ItemType Directory -Force
        }

        $redreamUrl = "https://redream.io/download"

        try {
            $webpage = Invoke-WebRequest -Uri $redreamUrl -UseBasicParsing
            #Write-Host "Successfully fetched Redream download page."
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

        #Write-Host "Downloading Redream from: $secondDownloadLink"
        #Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $secondDownloadLink -Destination $targetFilePath
            Write-Host "Redream download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download '$fileName': $_" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
elseif ($name -eq "PCSX2") {
        # PCSX2 download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
        $pcsx2DownloadPath = Join-Path $emupath "PCSX2"
        if (-not (Test-Path -Path $pcsx2DownloadPath)) {
            #Write-Host "Creating directory: $pcsx2DownloadPath"
            New-Item -Path $pcsx2DownloadPath -ItemType Directory -Force
        }

        $apiUrl = "https://api.github.com/repos/PCSX2/pcsx2/releases"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $releases = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            #Write-Host "Successfully fetched releases information."
        } catch {
            Write-Error "Failed to retrieve releases info: $_"
            exit 1
        }

        $preRelease = $releases | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1

        if (-not $preRelease) {
            Write-Error "No pre-release version found."
            exit 1
        }

        #Write-Host "Latest pre-release version: $($preRelease.tag_name)"
        $asset = $preRelease.assets | Where-Object { $_.name -like "*windows-x64-Qt.7z" }

        if (-not $asset) {
            Write-Error "File ending with 'windows-x64-Qt.7z' not found in the latest pre-release."
            exit 1
        }

        $downloadUrl = $asset.browser_download_url
        $targetFilePath = Join-Path $pcsx2DownloadPath $asset.name

        #Write-Host "Downloading PCSX2 from: $downloadUrl"
        #Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "PCSX2 download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
elseif ($name -eq "PPSSPP") {
    # PPSSPP download logic
	Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
    # Append the 'PPSSPP' folder to the base path
    $ppssppDownloadPath = Join-Path $emupath "PPSSPP"

    # Check if the PPSSPP directory exists, if not, create it
    if (-not (Test-Path -Path $ppssppDownloadPath)) {
        #Write-Host "Creating directory: $ppssppDownloadPath"
        New-Item -Path $ppssppDownloadPath -ItemType Directory -Force
    }

    # Define the PPSSPP builds page URL
    $ppssppBuildsUrl = "https://builds.ppsspp.org/"

    # Fetch the webpage containing the builds info
    try {
        $webpage = Invoke-WebRequest -Uri $ppssppBuildsUrl -UseBasicParsing
        #Write-Host "Successfully fetched PPSSPP builds webpage."
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
    #Write-Host "Download URL: $downloadUrl"
    #Write-Host "Target File Path: $targetFilePath"

    # Use Start-BitsTransfer to download the file
    try {
        Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
        Write-Host "PPSSPP download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
    } catch {
        Write-Error "Failed to download '$fileName': $_" -ForegroundColor "Red" -BackgroundColor "Black"
    }
}

elseif ($name -eq "MAME") {
        # MAME download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
        $mameDownloadPath = Join-Path $emupath "MAME"
        if (-not (Test-Path -Path $mameDownloadPath)) {
            #Write-Host "Creating directory: $mameDownloadPath"
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

        # Write-Host "Downloading MAME from: $downloadUrl" -ForegroundColor "Green" -BackgroundColor "Black"
        # Write-Host "Saving file to: $outputFilePath" -ForegroundColor "Green" -BackgroundColor "Black"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $outputFilePath
            Write-Host "MAME download completed successfully. File saved as $outputFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download MAME the file using Start-BitsTransfer." -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
elseif ($name -eq "Duckstation") {
        # Duckstation download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
        $duckstationDownloadPath = Join-Path $emupath "Duckstation"
        if (-not (Test-Path -Path $duckstationDownloadPath)) {
            #Write-Host "Creating directory: $duckstationDownloadPath"
            New-Item -Path $duckstationDownloadPath -ItemType Directory -Force
        }

        $apiUrl = "https://api.github.com/repos/stenzek/duckstation/releases/tags/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            #Write-Host "Successfully fetched latest Duckstation release information."
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

        # Write-Host "Downloading Duckstation from: $downloadUrl"
        # Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "Duckstation download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download 'duckstation-windows-x64-release.zip': $_" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
elseif ($name -eq "BigPEmu") {
        # BigPEmu download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
        $bigPemuDownloadPath = Join-Path $emupath "BigEmu"
        if (-not (Test-Path -Path $bigPemuDownloadPath)) {
           #Write-Host "Creating directory: $bigPemuDownloadPath"
            New-Item -Path $bigPemuDownloadPath -ItemType Directory -Force
        }

        $downloadPageUrl = "https://www.richwhitehouse.com/jaguar/index.php?content=download"

        try {
            #Write-Host "Fetching the webpage: $downloadPageUrl"
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

        #Write-Host "Found .zip file URL: $firstZipUrl"
        $fileName = [System.IO.Path]::GetFileName($firstZipUrl)
        $outputFilePath = Join-Path -Path $bigPemuDownloadPath -ChildPath $fileName

        # Write-Host "Downloading BigPEmu from: $firstZipUrl"
        # Write-Host "Saving to: $outputFilePath"

        try {
            Start-BitsTransfer -Source $firstZipUrl -Destination $outputFilePath
            Write-Host "BigPEmu download completed successfully. File saved as $outputFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download BigPEmu" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
elseif ($name -eq "RPCS3") {
        # RPCS3 download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
        $rpcs3DownloadPath = Join-Path $emupath "RPCS3"
        if (-not (Test-Path -Path $rpcs3DownloadPath)) {
            #Write-Host "Creating directory: $rpcs3DownloadPath"
            New-Item -Path $rpcs3DownloadPath -ItemType Directory -Force
        }

        $apiUrl = "https://api.github.com/repos/RPCS3/rpcs3-binaries-win/releases/latest"
        $headers = @{ "User-Agent" = "Mozilla/5.0" }

        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            #Write-Host "Successfully fetched latest RPCS3 release information."
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

        # Write-Host "Downloading RPCS3 from: $downloadUrl"
        # Write-Host "Saving to: $targetFilePath"

        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
            Write-Host "RPCS3 download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download '$($asset.name)': $_" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
elseif ($name -eq "CEMU") {
        # CEMU download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
		# Create the CEMU directory under the defined emupath
		$cemuDownloadPath = Join-Path $emupath "CEMU"

		# Check if the CEMU directory exists, if not, create it
	if (-not (Test-Path -Path $cemuDownloadPath)) {
		#Write-Host "Creating directory: $cemuDownloadPath"
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
		#Write-Host "Fetching latest release information from GitHub..."
		$release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
		#Write-Host "Successfully fetched latest release information."
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
	#Write-Host "Download URL: $downloadUrl"
	#Write-Host "Target File Path: $targetFilePath"

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
		#Write-Host "Downloading CEMU release..."
		Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
		Write-Host "CEMU download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
	} catch {
		Write-Error "Failed to download 'windows-x64.zip': $_" -ForegroundColor "Red" -BackgroundColor "Black"
		exit 1
}
	}

elseif ($name -eq "Dolphin") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
		# Dolphin download logic
		# Append 'Dolphin' to the path
$downloadPath = Join-Path -Path $emupath -ChildPath "Dolphin"
# Create the Dolphin directory under the defined emupath
# Ensure the directory exists; create it if it doesn't
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force
}

# URL for the Dolphin download page
$dolphinUrl = "https://dolphin-emu.org/download/"

# Fetch the HTML content of the download page
try {
    $webContent = Invoke-WebRequest -Uri $dolphinUrl
} catch {
    Write-Error "Failed to fetch the Dolphin Emulator download page. $_"
    exit 1
}

# Find the first download link that matches 'https://dl.dolphin-emu.org/builds/{folder}/{folder}/dolphin-master-####-?-x64.7z'
$downloadLink = $webContent.Links | Where-Object {
    $_.href -match "^https://dl\.dolphin-emu\.org/builds/\d+/\d+/dolphin-master-\d+-\d+-x64\.7z$"
} | Select-Object -First 1

if (-not $downloadLink) {
    Write-Error "No download link found for a file that matches 'dolphin-master-####-?-x64.7z'."
    exit 1
}

# Get the full download URL
$downloadUrl = $downloadLink.href

# Define the destination file path
$fileName = [System.IO.Path]::GetFileName($downloadUrl)
$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $fileName

#Write-Host "Downloading $fileName from $downloadUrl to $destinationFilePath"

# Start the BITS transfer to download the file
try {
    Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
    Write-Host "Dolphin download completed successfully. File saved to $destinationFilePath"   -ForegroundColor "Green" -BackgroundColor "Black"
} catch {
    Write-Error "Failed to download the file using BITS: $_" -ForegroundColor "Red" -BackgroundColor "Black"
    exit 1

}
	}
	
elseif ($name -eq "AppleWin") {
        # AppleWin download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
		# Append the 'AppleWin' folder to the base path
	$applewinDownloadPath = Join-Path $emupath "AppleWin"

		# Check if the AppleWin directory exists, if not, create it
	if (-not (Test-Path -Path $applewinDownloadPath)) {
		#Write-Host "Creating directory: $applewinDownloadPath"
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
		#Write-Host "Fetching latest release information from GitHub..."
		$release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
		#Write-Host "Successfully fetched latest release information."
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
		# Write-Host "Download URL: $downloadUrl"
		# Write-Host "Target File Path: $targetFilePath"

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
		#Write-Host "Downloading AppleWin release..."
		Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
		Write-Host "AppleWin download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
	} catch {
		Write-Error "Failed to download 'AppleWin': $_" -ForegroundColor "Red" -BackgroundColor "Black"
		exit 1
}
	}
	
elseif ($name -eq "Lime3DS") {
	# Lime3DS download logic
	Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
	# Append the 'Lime3DS' folder to the base path
	$lime3DSDownloadPath = Join-Path $emupath "Lime3DS"

		# Check if the Lime3DS directory exists, if not, create it
	if (-not (Test-Path -Path $lime3DSDownloadPath)) {
			#Write-Host "Creating directory: $lime3DSDownloadPath"
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
		#Write-Host "Fetching latest release information from GitHub..."
		$release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
		#Write-Host "Successfully fetched latest release information."
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
    #Write-Host "Download URL: $downloadUrl"
    #Write-Host "Target File Path: $targetFilePath"

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
        # Write-Host "Downloading $fileName..."
        Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
        Write-Host "Lime3DS download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
    } catch {
        Write-Error "Failed to download '$fileName': $_" -ForegroundColor "Red" -BackgroundColor "Black"
        exit 1
    }
	}
	}
	
elseif ($name -eq "RetroArch") {
    # RetroArch download logic
	Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
    # Define the URL for RetroArch platforms page
    $baseUrl = "https://www.retroarch.com/?page=platforms"

    # Define the base path where the files will be downloaded (change this to your desired download location)
    $downloadPathBase = Join-Path -Path $emupath -ChildPath "RetroArch"

    # Ensure the base download directory exists, if not, create it
    if (-not (Test-Path -Path $downloadPathBase)) {
        #Write-Host "Creating base directory: $downloadPathBase"
        New-Item -Path $downloadPathBase -ItemType Directory -Force
    }

    # Function to download files using BITS
    function Download-File {
        param (
            [string]$sourceUrl,
            [string]$destinationPath
        )

        #Write-Host "Downloading file from $sourceUrl"
        try {
            Start-BitsTransfer -Source $sourceUrl -Destination $destinationPath
            Write-Host "RetroArch download completed: $destinationPath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download $sourceUrl. Error: $_" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }

    # Fetch the main webpage from the base URL
    try {
        #Write-Host "Fetching RetroArch platforms page from: $baseUrl"
        $webpage = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing
    } catch {
        Write-Error "Failed to fetch the platforms page from $baseUrl. Error: $_"
        exit 1
    }

    # Parse the HTML content to find the section for "Windows 11 / 10 / 8.1 / 8 / 7"
    $windowsSection = $webpage.Content -match '<h4>Windows 11 / 10 / 8.1 / 8 / 7</h4>'
    if (-not $windowsSection) {
        Write-Error "Could not find the Windows section on the page."
        exit 1
    }

    # Extract the download link that contains "/windows/x86_64/"
    $downloadLink = $null
    $lines = $webpage.Content -split "`n"
    foreach ($line in $lines) {
        if ($line -match 'href="(.*?/windows/x86_64/.*?)"') {
            $downloadLink = $matches[1]
            #Write-Host "Download link found: $downloadLink" -ForegroundColor Cyan
            break
        }
    }

    # If no download link is found, exit with an error
    if (-not $downloadLink) {
        Write-Error "Failed to find the download link for the Windows x86_64 version."
        exit 1
    }

    # Now strip the filename (if any) from the downloadLink and keep only the directory part
    $directoryUrl = $downloadLink -replace '[^/]+$', '' # Removes the last part after the last '/' to get the directory URL
    $fullDirectoryUrl = $directoryUrl
    #Write-Host "Directory URL for downloads: $fullDirectoryUrl" -ForegroundColor Yellow

    # Extract the version number right after /stable/
    if ($fullDirectoryUrl -match '/stable/([^/]+)/') {
        $version = $matches[1]
        #Write-Host "Extracted version number: $version" -ForegroundColor Green
    } else {
        Write-Host "Unable to extract version number from the URL: $fullDirectoryUrl" -ForegroundColor Red
        Write-Error "Could not extract version number from the directory URL."
        exit 1
    }

    # Create a subdirectory under the base path with the version number
    $versionedDownloadPath = Join-Path -Path $downloadPathBase -ChildPath $version

    # Ensure the versioned download directory exists, if not, create it
    if (-not (Test-Path -Path $versionedDownloadPath)) {
        #Write-Host "Creating versioned directory: $versionedDownloadPath"
        New-Item -Path $versionedDownloadPath -ItemType Directory -Force
    }

    # Define the files to download
    $filesToDownload = @("RetroArch.7z", "RetroArch_cores.7z")

    foreach ($file in $filesToDownload) {
        # Construct the full download URL by appending the filename to the directory URL
        $downloadUrl = $fullDirectoryUrl + $file
        $targetFilePath = Join-Path -Path $versionedDownloadPath -ChildPath $file

        # Download the file using BITS
        Download-File -sourceUrl $downloadUrl -destinationPath $targetFilePath
    }

    Write-Host "RetroArch files downloaded successfully to $versionedDownloadPath" -ForegroundColor "Green" -BackgroundColor "Black"
}

elseif ($name -eq "shadps4") {
		# shadps4 download logic
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
		# Append 'shadps4' to the path
	$downloadPath = Join-Path -Path $emupath -ChildPath "shadps4"

# Ensure the directory exists
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force
}

# GitHub API URL for latest release of shadPS4
$githubApiUrl = "https://api.github.com/repos/shadps4-emu/shadPS4/releases/latest"

# Use Invoke-RestMethod to get the latest release information
try {
    $releaseInfo = Invoke-RestMethod -Uri $githubApiUrl -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
} catch {
    Write-Error "Failed to fetch release information from GitHub. $_"
    exit 1
}

# Find the asset URL for the file that starts with "shadps4-win64-"
$asset = $releaseInfo.assets | Where-Object { $_.name -like "shadps4-win64-qt*" }

if (-not $asset) {
    Write-Error "No asset found with a name starting with 'shadps4-win64-qt'."
    exit 1
}

# Get the download URL
$downloadUrl = $asset.browser_download_url

# Define the destination file path
$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $asset.name

# Write-Host "Downloading $($asset.name) from $downloadUrl to $destinationFilePath"

# Start the BITS transfer to download the file
try {
    Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
    Write-Host "shadps4 downloaded successfully. File saved to $destinationFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
} catch {
    Write-Error "Failed to download the file. $_" -ForegroundColor "Red" -BackgroundColor "Black"
    exit 1
}
}

elseif ($name -eq "TeknoParrot (Web installer)") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
		# Append 'TeknoParrot' to the path
	$downloadPath = Join-Path -Path $emupath -ChildPath "TeknoParrot"

# Ensure the directory exists; create it if it doesn't
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force
}

# GitHub API URL for latest release of TPBootstrapper
$githubApiUrl = "https://api.github.com/repos/nzgamer41/TPBootstrapper/releases/latest"

# Fetch the latest release information using Invoke-RestMethod
try {
    $releaseInfo = Invoke-RestMethod -Uri $githubApiUrl -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
} catch {
    Write-Error "Failed to fetch release information from GitHub: $_"
    exit 1
}

# Find the asset URL for TPBootstrapper.zip
$asset = $releaseInfo.assets | Where-Object { $_.name -eq "TPBootstrapper.zip" }

if (-not $asset) {
    Write-Error "No asset found with the name 'TPBootstrapper.zip'."
    exit 1
}

# Get the download URL for TPBootstrapper.zip
$downloadUrl = $asset.browser_download_url

# Define the full destination file path
$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $asset.name

#Write-Host "Downloading $($asset.name) from $downloadUrl to $destinationFilePath"

# Start the BITS transfer to download the file
try {
    Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
    Write-Host "TeknoParrot downloaded successfully. File saved to $destinationFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
} catch {
    Write-Error "Failed to download the TeknoParrot (web installer) $_" -ForegroundColor "Red" -BackgroundColor "Black"
    exit 1
}
	}
elseif ($name -eq "WinUAE") {
	Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
    # WinUAE download logic
	# Append 'WinUAE' to the path
$downloadPath = Join-Path -Path $emupath -ChildPath "WinUAE"

# Ensure the directory exists; create it if it doesn't
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force
}

# URL for the WinUAE download page
$winuaeUrl = "https://www.winuae.net/download/"

# Fetch the HTML content of the download page
try {
    $webContent = Invoke-WebRequest -Uri $winuaeUrl
} catch {
    Write-Error "Failed to fetch the WinUAE download page. $_"
    exit 1
}

# Find the download link that starts with 'WinUAE' and ends with '_x64.zip'
# The download link usually contains 'href' attributes, so we look for that in the parsed HTML
$downloadLink = $webContent.Links | Where-Object {
    $_.href -match "WinUAE.*_x64\.zip"
}

if (-not $downloadLink) {
    Write-Error "No download link found for a file that starts with 'WinUAE' and ends with '_x64.zip'."
    exit 1
}

# Construct the full URL for the download
$downloadUrl = $downloadLink.href

# Ensure the download URL is a full URL (if relative, prepend the base URL)
if ($downloadUrl -notmatch "^https?://") {
    $downloadUrl = [uri]::new($winuaeUrl, $downloadUrl).AbsoluteUri
}

# Define the destination file path
$fileName = [System.IO.Path]::GetFileName($downloadUrl)
$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $fileName

# Write-Host "Downloading $fileName from $downloadUrl to $destinationFilePath"

# Start the BITS transfer to download the file
try {
    Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
    Write-Host "WinUAE downloaded successfully. File saved to $destinationFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
} catch {
    Write-Error "Failed to download WinUAE $_" -ForegroundColor "Red" -BackgroundColor "Black"
    exit 1
}
	}
	
elseif ($name -eq "VICE") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
		# VICE download logic	
		# Append 'VICE' to the path
$downloadPath = Join-Path -Path $emupath -ChildPath "VICE"

# Ensure the directory exists; create it if it doesn't
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force
}

# GitHub API URL for latest pre-release of VICE
$githubApiUrl = "https://api.github.com/repos/VICE-Team/svn-mirror/releases"

# Use Invoke-RestMethod to get all releases information
try {
    $releases = Invoke-RestMethod -Uri $githubApiUrl -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
} catch {
    Write-Error "Failed to fetch release information from GitHub: $_"
    exit 1
}

# Get the first pre-release (checking for prerelease attribute)
$preRelease = $releases | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1

if (-not $preRelease) {
    Write-Error "No pre-release found."
    exit 1
}

# Output the name of the pre-release to confirm it's correct
#Write-Host "Found pre-release: $($preRelease.tag_name)"

# Updated regex patterns for the file names based on the format you provided
$gtkPattern = "^GTK3VICE-\d+\.\d+-win64-r\d+\.7z$"
$sdlPattern = "^SDL2VICE-\d+\.\d+-win64-r\d+\.7z$"

# Flag to track if any file is downloaded
$downloadedAnyFile = $false

# Print the list of asset names to verify
#Write-Host "List of files in pre-release:"
#$preRelease.assets | ForEach-Object {
#    Write-Host "Asset: $($_.name)"
#}

# Loop through the assets in the pre-release
$preRelease.assets | ForEach-Object {
    $assetName = $_.name
    $downloadUrl = $_.browser_download_url

    # Match the file name against the GTK3VICE and SDL2VICE patterns
    if ($assetName -match $gtkPattern -or $assetName -match $sdlPattern) {
        # Define the destination file path
        $destinationFilePath = Join-Path -Path $downloadPath -ChildPath $assetName

        #Write-Host "Downloading $assetName from $downloadUrl to $destinationFilePath"

        # Start the BITS transfer to download the file
        try {
            Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
            Write-Host "VICE downloaded successfully. File saved to $destinationFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
            $downloadedAnyFile = $true
        } catch {
            Write-Error "Failed to download $_.name" -ForegroundColor "Red" -BackgroundColor "Black"
        }
    }
}

# Check if no file was downloaded
if (-not $downloadedAnyFile) {
    Write-Host "No files matching the patterns were found in the pre-release."
}
}
	
elseif ($name -eq "Xenia Manager") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow    
		# Xenia Manager download logic
	$downloadDir = Join-Path $emupath "Xenia Manager"

# Ensure the download directory exists
if (-not (Test-Path $downloadDir)) {
    New-Item -Path $downloadDir -ItemType Directory
}

# GitHub API URL to get the latest release info
$apiUrl = "https://api.github.com/repos/xenia-manager/xenia-manager/releases/latest"

# Set a User-Agent header for the request (required by GitHub API)
$headers = @{ "User-Agent" = "Mozilla/5.0" }

# Fetch the latest release info from GitHub
$response = Invoke-RestMethod -Uri $apiUrl -Headers $headers

# Extract the release version (e.g., v1.0.0) and assets (downloads) from the API response
$releaseVersion = $response.tag_name  # e.g., "v1.0.0"
$asset = $response.assets | Where-Object { $_.name -eq "xenia_manager.zip" }

# Ensure we found the xenia_manager.zip asset
if (-not $asset) {
    Write-Error "No asset found for 'xenia_manager.zip' in the latest release"
    exit
}

# Extract the download URL for xenia_manager.zip
$downloadLink = $asset.browser_download_url

# Define the full path where the file will be downloaded (with the release version appended)
$fileName = "xenia_manager_$releaseVersion.zip"
$destinationPath = Join-Path $downloadDir $fileName

# Debugging: Output the constructed download URL and destination path
# Write-Host "Download Link: $downloadLink"
# Write-Host "File Name: $fileName"
# Write-Host "Destination Path: $destinationPath"
# Write-Host "Downloading $fileName to $destinationPath..."

# Start the BITS transfer to download the file
        try {
			Start-BitsTransfer -Source $downloadLink -Destination $destinationPath
			Write-Host "Xenia Manager downloaded successfully. File saved to $destinationFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download $filename" -ForegroundColor "Red" -BackgroundColor "Black"
        }
	}

elseif ($name -eq "mGBA") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow    
		# mGBA download logic
$downloadDir = Join-Path $emupath "mGBA"

# Ensure the download directory exists
if (-not (Test-Path $downloadDir)) {
    New-Item -Path $downloadDir -ItemType Directory
}

# URL of the mGBA download page
$downloadPageUrl = "https://mgba.io/downloads.html"

# Download the HTML content of the download page
$response = Invoke-WebRequest -Uri $downloadPageUrl

# Debugging: Output the raw HTML content to ensure we're getting the correct HTML
# Write-Host "HTML Content fetched from the website:"
# Write-Host "=============================================="
# Write-Host $response.Content
# Write-Host "=============================================="

# Parse the HTML to find the first link that contains 'mGBA-build-latest-win64.7z'
$downloadLinkFound = $response.Content -match 'https://s3\.amazonaws\.com/mgba/mGBA-build-latest-win64\.7z'

# Ensure we found the download link
if (-not $downloadLinkFound) {
    Write-Error "No download link found for 'mGBA-build-latest-win64.7z'"
    exit
}

# The matched link is stored in $matches[0] after the regex match
$downloadLink = $matches[0]

# Extract the file name from the URL
$fileName = [System.IO.Path]::GetFileName($downloadLink)

# Define the full path where the file will be downloaded
$destinationPath = Join-Path $downloadDir $fileName

# Debugging: Output the constructed download URL and destination path
# Write-Host "Download Link: $downloadLink"
# Write-Host "File Name: $fileName"
# Write-Host "Destination Path: $destinationPath"

# Start the BITS transfer to download the file
#Write-Host "Downloading $fileName to $destinationPath..."
        try {
			Start-BitsTransfer -Source $downloadLink -Destination $destinationPath
			Write-Host "mGBA download completed! files saved to: $destinationPath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download $filename" -ForegroundColor "Red" -BackgroundColor "Black"
        }
	}

elseif ($name -eq "Rosalie's Mupen GUI") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow    
		# Rosalie's Mupen GUI download logic
$downloadDir = Join-Path $emupath "RMG"

# Ensure the download directory exists
if (-not (Test-Path $downloadDir)) {
    New-Item -Path $downloadDir -ItemType Directory
}

# GitHub API URL for the latest release of the repository
$repoApiUrl = "https://api.github.com/repos/Rosalie241/RMG/releases/latest"

# Set the User-Agent header required by GitHub API
$headers = @{ "User-Agent" = "Mozilla/5.0" }

# Fetch the latest release information from GitHub
$response = Invoke-RestMethod -Uri $repoApiUrl -Headers $headers

# Look for the asset that starts with "RMG-Portable-Windows64-"
$asset = $response.assets | Where-Object { $_.name -like "RMG-Portable-Windows64-*" }

# Ensure we found the asset
if ($null -eq $asset) {
    Write-Error "No file found that matches 'RMG-Portable-Windows64-*'"
    exit
}

# Extract the download URL for the file
$downloadUrl = $asset.browser_download_url
$fileName = $asset.name

# Define the full path where the file will be downloaded
$destinationPath = Join-Path $downloadDir $fileName

# Start the BITS transfer to download the file
#Write-Host "Downloading $fileName to $destinationPath..."
        try {
			Start-BitsTransfer -Source $downloadUrl -Destination $destinationPath
			Write-Host "Rosalie's Mupen GUI download complete. File saved to: $destinationPath" -ForegroundColor "Green" -BackgroundColor "Black"
        } catch {
            Write-Error "Failed to download $filename" -ForegroundColor "Red" -BackgroundColor "Black"
        }
	}
	
elseif ($name -eq "Stella") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
		# Stella download logic
$downloadDir = Join-Path $emupath "Stella"

# Ensure the download directory exists
if (-not (Test-Path $downloadDir)) {
    New-Item -Path $downloadDir -ItemType Directory
}

# GitHub API URL for the latest release of the repository
$repoApiUrl = "https://api.github.com/repos/stella-emu/stella/releases/latest"

# Set the User-Agent header required by GitHub API
$headers = @{ "User-Agent" = "Mozilla/5.0" }

# Fetch the latest release information from GitHub
$response = Invoke-RestMethod -Uri $repoApiUrl -Headers $headers

# Look for the asset that starts with "Stella-" and ends with "-windows.zip"
$asset = $response.assets | Where-Object { $_.name -like "Stella-*-windows.zip" }

# Ensure we found the asset
if ($null -eq $asset) {
    Write-Error "No file found that matches 'Stella-*-windows.zip'"
    exit
}

# Extract the download URL for the file
$downloadUrl = $asset.browser_download_url
$fileName = $asset.name

# Define the full path where the file will be downloaded
$destinationPath = Join-Path $downloadDir $fileName

# Start the BITS transfer to download the file
#Write-Host "Downloading $fileName to $destinationPath..."
        try {
			Start-BitsTransfer -Source $downloadUrl -Destination $destinationPath
			Write-Host "Stella download complete. File saved to: $destinationPath" -ForegroundColor "Green" -BackgroundColor "Black"		
        } catch {
            Write-Error "Failed to download $filename" -ForegroundColor "Red" -BackgroundColor "Black"
        }
	}

elseif ($name -eq "Supermodel") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow
		# Supermodel download logic
$downloadDir = Join-Path $emupath "Supermodel"

# Ensure the download directory exists
if (-not (Test-Path $downloadDir)) {
    New-Item -Path $downloadDir -ItemType Directory
}

# URL of the Supermodel3 download page
$downloadPageUrl = "https://supermodel3.com/Download.html"

# Download the HTML content of the download page
$response = Invoke-WebRequest -Uri $downloadPageUrl

# Debugging: Output the raw HTML content to ensure we're getting the correct HTML
# Write-Host "HTML Content fetched from the website:"
# Write-Host "=============================================="
# Write-Host $response.Content
# Write-Host "=============================================="

# Parse the HTML content line-by-line to find the first link that contains 'Supermodel_' and ends with '_Win64.zip'
$relativeDownloadLink = $response.Content -split "`n" | Where-Object { $_ -match 'href=".*Supermodel_.*_Win64\.zip"' } | Select-Object -First 1

# Ensure we found the relative download link
if (-not $relativeDownloadLink) {
    Write-Error "No download link found for 'Supermodel_*_Win64.zip'"
    exit
}

# Extract the relative download link using a proper match
if ($relativeDownloadLink -match 'href="([^"]+)"') {
    $relativeDownloadLink = $matches[1]
} else {
    Write-Error "Failed to extract the download link from the HTML"
    exit
}

# Ensure the relative URL starts with '/'
if ($relativeDownloadLink -notmatch '^/') {
    $relativeDownloadLink = "/$relativeDownloadLink"
}

# Construct the full URL by appending the base URL
$downloadLink = "https://supermodel3.com$relativeDownloadLink"

# Extract the file name from the URL
$fileName = [System.IO.Path]::GetFileName($downloadLink)

# Loosened validation: We will allow any file name that starts with 'Supermodel_' and ends with '_Win64.zip'
if (-not ($fileName -like 'Supermodel_*_Win64.zip')) {
    Write-Error "The file name format is incorrect: $fileName"
    exit
}

# Define the full path where the file will be downloaded
$destinationPath = Join-Path $downloadDir $fileName

# Debugging: Output the constructed download URL and destination path
# Write-Host "Download Link: $downloadLink"
# Write-Host "File Name: $fileName"
# Write-Host "Destination Path: $destinationPath"
	
	# Start the BITS transfer to download the file
#Write-Host "Downloading $fileName to $destinationPath..."
        try {
			Start-BitsTransfer -Source $downloadLink -Destination $destinationPath
			Write-Host "Supermodel download complete. File saved to: $destinationPath" -ForegroundColor "Green" -BackgroundColor "Black"	
        } catch {
            Write-Error "Failed to download Supermodel" -ForegroundColor "Red" -BackgroundColor "Black"
        }
	}
	
elseif ($name -eq "mupen64plus") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow    
		# mupen64plus download logic
		# Append 'mupen64plus' to the path
$downloadPath = Join-Path -Path $emupath -ChildPath "mupen64plus"

# Ensure the directory exists; create it if it doesn't
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force
}

# GitHub API URL for latest release of Mupen64Plus
$githubApiUrl = "https://api.github.com/repos/mupen64plus/mupen64plus-core/releases/latest"

# Fetch the latest release information from GitHub
try {
    $releaseInfo = Invoke-RestMethod -Uri $githubApiUrl -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
} catch {
    Write-Error "Failed to fetch release information from GitHub: $_"
    exit 1
}

# Find the asset that starts with 'mupen64plus-bundle-win64'
$asset = $releaseInfo.assets | Where-Object { $_.name -like "mupen64plus-bundle-win64*" }

if (-not $asset) {
    Write-Error "No asset found with the name starting with 'mupen64plus-bundle-win64'."
    exit 1
}

# Get the download URL and asset name
$downloadUrl = $asset.browser_download_url
$assetName = $asset.name

# Define the full destination file path
$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $assetName

#Write-Host "Downloading $assetName from $downloadUrl to $destinationFilePath"

# Start the BITS transfer to download the file
try {
    Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
    Write-Host "mupen64plus download complete. File saved to: $destinationFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
} catch {
    Write-Error "Failed to download mupen64plus $_" -ForegroundColor "Red" -BackgroundColor "Black"
    exit 1
}
}	
elseif ($name -eq "melonDS") {
		Write-Host "$name selected, proceeding with download." -ForegroundColor Yellow    
		# melonDS download logic
    $downloadPath = Join-Path -Path $emupath -ChildPath "melonDS"
    
    if (-not (Test-Path -Path $downloadPath)) {
        #Write-Host "Creating directory: $downloadPath"
        New-Item -Path $downloadPath -ItemType Directory -Force
    }
    
    # GitHub API URL to get the latest release for the melonDS project
    $apiUrl = "https://api.github.com/repos/melonDS-emu/melonDS/releases/latest"
    
    $headers = @{
        "User-Agent" = "Mozilla/5.0"
    }
    
    try {
        #Write-Host "Fetching latest melonDS release information from GitHub..." -ForegroundColor Cyan
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        Write-Host "Successfully fetched latest melonDS release information." -ForegroundColor Green
    } catch {
        Write-Error "Failed to retrieve latest release info from GitHub: $_"
        return
    }
    
    $asset = $release.assets | Where-Object { $_.name -like "*win_x64.zip" }
    
    if (-not $asset) {
        Write-Error "File ending with 'win_x64.zip' not found in the latest release."
        return
    }
    
    $downloadUrl = $asset.browser_download_url
    $targetFilePath = Join-Path -Path $downloadPath -ChildPath $asset.name
    
    # Write-Host "Download URL: $downloadUrl" -ForegroundColor Cyan
    # Write-Host "Target File Path: $targetFilePath" -ForegroundColor Cyan
    
    try {
        #Write-Host "Downloading the latest melonDS release..." -ForegroundColor Green
        Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
        Write-Host "melonDS download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
    } catch {
        Write-Error "Failed to download the file: $_" -ForegroundColor "Red" -BackgroundColor "Black"
    }
}
}

# Main script loop
$exit = $false

# emulators not displayed due to downloads not working - waiting on project update
# "Ryujinx",
#"PPSSPP",

# Define the list of emulators in a simple array to avoid hardcoded numbering
$emulatorNames = @(
    "AppleWin",
    "BigPEmu",
    "CEMU",
    "Dolphin",
    "Duckstation",
    "Lime3DS",
    "MAME",
    "melonDS",
    "PCSX2",
    "Redream",
    "RetroArch",
    "RPCS3",
    "shadps4",
    "TeknoParrot (Web installer)",
    "Vita3K",
    "VICE",
    "WinUAE",
    "XEMU",
    "XENIA",
    "mupen64plus", 
	"Rosalie's Mupen GUI",
	"Stella",
	"Supermodel",
	"mGBA",
	"Xenia Manager"
)

# Sort the emulator names alphabetically
$sortedEmulatorNames = $emulatorNames | Sort-Object

# Function to display the menu in two centered columns, aligned to "Select an option:"
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
     ###++###                                               ##+++###     " -ForegroundColor "Blue" -BackgroundColor "Black"

    
    	
function DisplayCyclingText {
    param (
        [string]$textToDisplay,      # The text we want to display with the cycling effect
        [int]$totalTimeInMilliseconds = 500  # Total time in milliseconds (3 seconds)
    )

    # Convert the text to an array of characters
    $finalCharacters = $textToDisplay.ToCharArray()

    # Calculate the total number of characters in the string
    $charCount = $finalCharacters.Length

    # Set a reasonable cycle limit per character (how many different letters it can show before the final one)
    $maxCyclesPerLetter = 3

    # Calculate the total number of steps (cycles)
    $totalCycles = $charCount * $maxCyclesPerLetter

    # Calculate the delay per cycle to ensure the entire animation fits within the desired total time
    $delayPerCycle = [math]::Ceiling($totalTimeInMilliseconds / $totalCycles)

    # Iterate over each character in the final string
    for ($i = 0; $i -lt $finalCharacters.Length; $i++) {
        # Get the final character for this position
        $finalChar = $finalCharacters[$i]

        # If the character is a letter, cycle through the alphabet
        if ($finalChar -match '[a-zA-Z]') {
            $currentChar = [char]65  # Start with 'A'

            # If the final character is lowercase, adjust the starting point to 'a'
            if ($finalChar -match '[a-z]') {
                $currentChar = [char]97  # Start with 'a'
            }

            # Cycle through the alphabet, showing $maxCyclesPerLetter characters
            for ($cycle = 1; $cycle -le $maxCyclesPerLetter; $cycle++) {
                # Display current character in green on black background
                Write-Host -NoNewline $currentChar -ForegroundColor Green -BackgroundColor Black
                Start-Sleep -Milliseconds $delayPerCycle

                # Overwrite the previous character
                [System.Console]::SetCursorPosition([System.Console]::CursorLeft - 1, [System.Console]::CursorTop)

                # Move to the next letter
                $currentChar = [char]([int][char]$currentChar + 1)

                # Wrap around after 'Z' or 'z'
                if ($currentChar -eq [char]91) { $currentChar = [char]65 }   # After 'Z', reset to 'A'
                if ($currentChar -eq [char]123) { $currentChar = [char]97 }  # After 'z', reset to 'a'

                # Exit early if the current character matches the final character
                if ($currentChar -eq $finalChar) { break }
            }

            # Print the final correct character (once the loop finishes)
            Write-Host -NoNewline $finalChar -ForegroundColor Green -BackgroundColor Black
        }
        else {
            # If it's not a letter, print the character immediately (spaces, numbers, punctuation, etc.)
            Write-Host -NoNewline $finalChar -ForegroundColor Green -BackgroundColor Black
        }
    }

    # Move to the next line when done
    Write-Host ""
}

# Usage: Define the text to be displayed and call the function
$text = "          Welcome to the Emulator Auto-Downloader - Version: $scriptVersion"
DisplayCyclingText -textToDisplay $text -totalTimeInMilliseconds 500

	Write-Host "            https://github.com/dbalcar/Emulator-Auto-downloads" -ForegroundColor "Green" -BackgroundColor "Black"
    Write-Host "                Emulator download path: $path" -ForegroundColor "Green" -BackgroundColor "Black"

    Write-Host ""
    
    # Display the "Select an option:" line and capture the starting position
    $optionText = "                            Select an option:"
    Write-Host $optionText -ForegroundColor "Green" -BackgroundColor "Black"
    Write-Host ""

    # Calculate where to start aligning the emulator columns based on the "Select an option:" text length
    $startPos = $optionText.Trim().Length

    # Prepare emulators for two columns display
    $halfCount = [math]::Ceiling($sortedEmulatorNames.Count / 2)

    # Split the sorted emulators into two columns
    $column1 = $sortedEmulatorNames[0..($halfCount - 1)]
    $column2 = $sortedEmulatorNames[$halfCount..($sortedEmulatorNames.Count - 1)]

    # Set the width of the first column, including the number and emulator name
    $col1Width = 25  # Adjust this to minimize space between columns

    # Output the emulators in two columns, aligned with "Select an option:"
    for ($i = 0; $i -lt $halfCount; $i++) {
        # Left column (Column 1) with a 2-character number and fixed width for the emulator name
        $col1 = "{0,2}. {1,-$col1Width}" -f ($i + 1), $column1[$i]

        # Right column (Column 2) with a 2-character number and aligned similarly
        $col2 = if ($i -lt $column2.Count) { "{0,2}. {1}" -f ($i + 1 + $halfCount), $column2[$i] } else { "" }

        # Combine columns without excessive spaces between them
        $outputLine = "$col1$col2"

        # Pad the line to start after the "Select an option:" text
        $paddedLine = $outputLine.PadLeft($startPos + $outputLine.Length)

        # Display the centered line
        Write-Host $paddedLine -ForegroundColor "Green" -BackgroundColor "Black"
    }

    Write-Host ""
    Write-Host "  'all' to download all of the emulators" -ForegroundColor "Green" -BackgroundColor "Black"
    Write-Host "  'exit' to exit" -ForegroundColor "Green" -BackgroundColor "Black"
    Write-Host ""
}

# Main script loop
$exit = $false

while (-not $exit) {
    Show-Menu
    # Display the prompt and capture the choice
    Write-Host "Choose the emulator to download (1-$($emulatorNames.Count), 'all' to download all, or 'exit' to quit)" -ForegroundColor Green
    $choice = Read-Host

    # Input validation: if it's a number between 1 and the number of emulators, cast to int; otherwise, make lowercase
    if ($choice -match '^\d+$') {
        $choice = [int]$choice
    } else {
        $choice = $choice.ToLower()
    }

    # Handle user input
    switch ($choice) {
        # Individual emulator download based on selection
        { $_ -ge 1 -and $_ -le $emulatorNames.Count } {
            $emulator = $sortedEmulatorNames[$choice - 1]
            if ($emulator) {
                Download-Emulator -name $emulator
            } else {
                Write-Host "Invalid emulator selection." -ForegroundColor Yellow
            }
        }

        # Download all emulators
        "all" {
            foreach ($emulator in $sortedEmulatorNames) {
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
            Write-Host "Invalid choice. Please enter a valid number between 1 and $($emulatorNames.Count), or type 'all' to download all, or 'exit' to quit."
        }
    }
}

# Stop transcript logging - for debugging ONLY
# Stop-Transcript
