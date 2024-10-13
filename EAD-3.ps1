# Emulator Auto-Downloads
# Copyright (C) 2024 David Balcar
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
$scriptVersion = "v3.1.0"

<#
   ===========================================================================================
                          Emulator Auto-Downloader
   ===========================================================================================
	This script downloads the latest stable / dev releases of emulators 
    and their versions for Windows x86_64, Mac & Linux from their official websites or github.

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

    For any support or issues, Please visit the github respository
    ==========================================================================================
#>

# Set the window size
$Width = 100
$Height = 50
$host.ui.rawui.windowSize = New-Object Management.Automation.Host.Size($Width, $Height)

# set the buffer size as well
$host.ui.rawui.BufferSize = New-Object Management.Automation.Host.Size($Width, 100)

# Clear the screen and set the console background to black
$Host.UI.RawUI.BackgroundColor = "Black"

# Check for Emulator Auto-Downloads updates
# GitHub API URL for the latest release of the script
$repoUrl = "https://api.github.com/repos/dbalcar/Emulator-Auto-downloads/releases/latest"

# Define the paths
$scriptPath = $PSCommandPath              # Full path to the current script
$exePath = Join-Path $PSScriptRoot "EAD-3.exe"  # Path to the exe file (if running from an exe)

# GitHub API URL for the latest release of the script
$repoUrl = "https://api.github.com/repos/dbalcar/Emulator-Auto-downloads/releases/latest"

# Determine the current directory where the script or .exe is running from
$currentDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
}

# Define paths for both the .exe and .ps1 based on the current directory
$exePath = Join-Path $currentDir "EAD-3.exe"
$ps1Path = Join-Path $currentDir "EAD-3.ps1"

# Function to check for updates
function Check-ForUpdate {
    try {
        # Get the latest release info from GitHub
        $latestRelease = Invoke-RestMethod -Uri $repoUrl -Headers @{ "User-Agent" = "PowerShell" }

        # Get the latest version from the GitHub release
        $latestVersion = $latestRelease.tag_name

        Write-Host "Current script version: $scriptVersion"
        Write-Host "Latest available version: $latestVersion"

        # Check if the latest version starts with 'v3'
        if ($latestVersion -match "^v3\.\d+\.\d+$") {
            # Compare versions only if the latest version is within v3.*.*
            if ($scriptVersion -lt $latestVersion) {
                Write-Host "A new version ($latestVersion) is available." -ForegroundColor Yellow

                # Ask the user if they want to update
                $updateResponse = Read-Host "Would you like to update to the latest version? (y/n)"

                if ($updateResponse -eq 'y' -or $updateResponse -eq 'yes') {
                    # Proceed with the update
                    Write-Host "Updating to version $latestVersion..." -ForegroundColor Yellow

                    # Find and download both the .ps1 and .exe files
                    $assets = $latestRelease.assets | Where-Object { $_.name -match '\.ps1$|\.exe$' }

                    if (-not $assets) {
                        Write-Host "No valid assets (.ps1 or .exe) found in the latest release." -ForegroundColor Red
                        return
                    }

                    # Download all matching assets (.ps1 and .exe)
                    foreach ($asset in $assets) {
                        $downloadUrl = $asset.browser_download_url
                        $fileName = $asset.name
                        $destinationFilePath = Join-Path $currentDir $fileName

                        Write-Host "Downloading $fileName from $downloadUrl..."
                        Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath
                        Write-Host "Update downloaded to $destinationFilePath"
                    }

                    # Check if we are running the .exe version or the .ps1 script
                    if ($MyInvocation.MyCommand.Path -match "\.exe$") {
                        Write-Host "Restarting the updated .exe file..."
                        if (Test-Path $exePath) {
                            Start-Process -FilePath $exePath
                        } else {
                            Write-Error "EAD-3.exe not found at $exePath"
                        }
                    } else {
                        Write-Host "Restarting the updated script..."
                        if (Test-Path $ps1Path) {
                            # Restart the script with any original arguments if applicable
                            if ($args.Count -gt 0) {
                                Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$ps1Path`" $args"
                            } else {
                                Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$ps1Path`""
                            }
                        } else {
                            Write-Error "EAD-3.ps1 not found at $ps1Path"
                        }
                    }

                    # Exit the current script to allow the new one to run
                    exit 0
                } else {
                    Write-Host "Continuing with the current version ($scriptVersion)." -ForegroundColor Cyan
                }
            } else {
                Write-Host "You are running the latest version ($scriptVersion)." -ForegroundColor Green
            }
        } else {
            Write-Host "Latest version ($latestVersion) is outside the v3 series. No update will be performed." -ForegroundColor Red
        }

    } catch {
        Write-Error "Failed to check for updates: $_"
    }
}

# Run the update check
Check-ForUpdate

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

        Write-Host "INI file created successfully."

        # Use $PSScriptRoot to get the path of the current script
        $eadExePath = Join-Path -Path $PSScriptRoot -ChildPath "EAD-3.exe"

        # Check if EAD-3.exe exists and run it
        if (Test-Path $eadExePath) {
            Start-Process -FilePath $eadExePath
        } else {
            Write-Error "EAD-3.exe not found in the current script's directory ($PSScriptRoot)."
        }
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

$global:SelectedOS = $null  # Store the OS choice in a global variable

# Define arrays to store emulator names for each OS
$emulatorNamesWin = @("AppleWin", "BigPEmu", "CEMU", "Dolphin", "XEMU", "XENIA", "Vita3K", "Redream", "PCSX2","MAME","Duckstation","RPCS3","Lime3DS","RetroArch","shadPS4","TeknoParrot","WinUAE","VICE","Xenia Manager","mGBA","Rosalie's Mupen GUI","Stella","Supermodel","mupen64plus","melonDS","Sudachi","Mednafen","a7800","Project64","Snes9x","VisualBoyAdvance-m")
$emulatorNamesMac = @("Dolphin", "Vita3K", "Redream", "PCSX2","MAME","Duckstation","CEMU","Lime3DS","shadPS4","RPCS3","a7800","VisualBoyAdvance-m")
$emulatorNamesLinux = @("Vita3K","Redream","PCSX2","BigPEmu","CEMU","Lime3DS","shadPS4","Sudachi","Mednafen","a7800")

# Function to display the OS menu and save the user's choice in a variable
function Select-OS {
    Clear-Host
    Write-Host "
    ===============================================================
    Emulator Auto-Downloader - Version $scriptVersion
	
    Select your Emulator OS version to download
	
    1. Windows (default)
    2. MacOS
    3. Linux
    ===============================================================
    " -ForegroundColor Cyan -BackgroundColor Black

    # Prompt for OS selection
    Write-Host "Choose (1-3, press Enter for Windows): " -ForegroundColor Cyan -BackgroundColor Black -NoNewline
    $osChoice = Read-Host

    # Logic to save the OS choice
    switch ($osChoice) {
        {$_ -eq ""} { $global:SelectedOS = "Windows"; break }  # Default to Windows if nothing is entered
        1 { $global:SelectedOS = "Windows" }
        2 { $global:SelectedOS = "MacOS" }
        3 { $global:SelectedOS = "Linux" }
        default { 
            Write-Host "Invalid selection. Please choose a valid OS option." -ForegroundColor Yellow -BackgroundColor Black
            Select-OS # Call the function again if invalid option
        }
    }

    # Confirm the selected OS with green text and black background
    Write-Host "You selected: $global:SelectedOS" -ForegroundColor Green -BackgroundColor Black
}

# Function to get the emulator list based on selected OS
function Get-EmulatorsForSelectedOS {
    switch ($global:SelectedOS) {
        "Windows" { return $emulatorNamesWin }
        "MacOS" { return $emulatorNamesMac }
        "Linux" { return $emulatorNamesLinux }
        default {
            Write-Host "Invalid OS selection. Exiting..." -ForegroundColor Red
            exit 1
        }
    }
}

# Function to display the emulator menu based on the selected OS
function Show-EmulatorMenu {
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
        [int]$totalTimeInMilliseconds = 5  # Total time in milliseconds (3 seconds)
    )

    # Convert the text to an array of characters
    $finalCharacters = $textToDisplay.ToCharArray()

    # Calculate the total number of characters in the string
    $charCount = $finalCharacters.Length

    # Set a reasonable cycle limit per character (how many different letters it can show before the final one)
    $maxCyclesPerLetter = 2

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
$text = "        Welcome to the Emulator Auto-Downloader - Version: $scriptVersion"
DisplayCyclingText -textToDisplay $text -totalTimeInMilliseconds 500

	Write-Host "            https://github.com/dbalcar/Emulator-Auto-downloads" -ForegroundColor "Green" -BackgroundColor "Black"
    Write-Host "                Emulator download path: $path" -ForegroundColor "Yellow" -BackgroundColor "Black"
    Write-Host ""


    # Get the emulators for the selected OS
    $emulatorsForOS = Get-EmulatorsForSelectedOS | Sort-Object

    if ($emulatorsForOS.Count -eq 0) {
        Write-Host "No emulators available for $global:SelectedOS." -ForegroundColor Yellow
        return
    }

    # Display emulators, adjust formatting for columns if more than 10
    if ($emulatorsForOS.Count -gt 10) {
        $halfCount = [math]::Ceiling($emulatorsForOS.Count / 2)
        $column1 = $emulatorsForOS[0..($halfCount - 1)]
        $column2 = $emulatorsForOS[$halfCount..($emulatorsForOS.Count - 1)]

        for ($i = 0; $i -lt $column1.Count; $i++) {
            $col1 = "            {0,2}. {1,-20}" -f ($i + 1), $column1[$i]  # spaces indentation
            $col2 = if ($i -lt $column2.Count) { "{0,2}. {1}" -f ($i + $halfCount + 1), $column2[$i] } else { "" }
            Write-Host "$col1 $col2" -ForegroundColor Green -BackgroundColor Black
        }
    } else {
        for ($i = 0; $i -lt $emulatorsForOS.Count; $i++) {
            Write-Host "     $($i + 1). $($emulatorsForOS[$i])" -ForegroundColor Green -BackgroundColor Black
        }
    }

    Write-Host ""
    Write-Host "=============================================================="
    Write-Host "Type 'all' to download all emulators for " -ForegroundColor Cyan -NoNewline
	Write-Host "$global:SelectedOS" -ForegroundColor White -NoNewline
	Write-Host "" -ForegroundColor Cyan

	Write-Host "Type 'OS' to change Operating System" -ForegroundColor Cyan
    Write-Host "Type 'exit' to exit the script" -ForegroundColor Cyan
    Write-Host "=============================================================="
    
    # Capture user's emulator selection or special options (all, OS, exit)
    $emuChoice = Read-Host "Choose the emulator to download (1-$($emulatorsForOS.Count)), type 'all', 'OS' or 'exit'"
    
    return $emuChoice, $emulatorsForOS
}


#    Write-Host "Downloading $emulatorName for $global:SelectedOS..." -ForegroundColor Cyan
   

# Function to download the emulator based on the selected OS and emulator
function Download-Emulator {
    param (
        [string]$emulatorName
    )

    # $path = $emupath
    $downloadDir =$emupath
	
	if (-not (Test-Path $downloadDir)) { New-Item -ItemType Directory -Path $downloadDir -Force }

    Write-Host "Downloading $emulatorName for $global:SelectedOS..." -ForegroundColor Cyan

    # Emulator download logic based on OS and emulator name

switch ($global:SelectedOS) {
    "Windows" {
        switch ($emulatorName) {
            "AppleWin" {
                # AppleWin Download Logic for Windows
                $apiUrl = "https://api.github.com/repos/AppleWin/AppleWin/releases/latest"
                try {
                    # Fetch release info from GitHub API
                    $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "Mozilla/5.0" }
                    # Find the asset with a .zip extension
                    $asset = $releaseInfo.assets | Where-Object { $_.name -match "\.zip$" } | Select-Object -First 1
                    if ($asset) {
                        # Construct the download URL and file path
                        $downloadUrl = $asset.browser_download_url
                        $emulatorDir = Join-Path -Path $downloadDir -ChildPath "AppleWin"
                        
                        # Create the AppleWin directory if it doesn't exist
                        if (-not (Test-Path $emulatorDir)) { New-Item -ItemType Directory -Path $emulatorDir -Force }
                        
                        # Append the full file name to the AppleWin directory path
                        $destinationFilePath = Join-Path -Path $emulatorDir -ChildPath $asset.name
                        
                        # Start the download using BITS
                        Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
                        Write-Host "AppleWin downloaded successfully to $destinationFilePath" -ForegroundColor Green
                    } else {
                        Write-Host "No AppleWin .zip release found on GitHub." -ForegroundColor Red
                    }
                } catch {
                    Write-Error "Failed to download AppleWin: $_"
                }
            }
			"Snes9x" {
                    # Snes9x Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
					# Append 'Snes9x' to the download path
					$downloadPath = Join-Path -Path $emupath -ChildPath "Snes9x"

					# Ensure the directory exists; if not, create it
					if (-not (Test-Path -Path $downloadPath)) {
						New-Item -ItemType Directory -Path $downloadPath -Force
					}

					# URL for Snes9x download page
					$snes9xUrl = "https://www.emulator-zone.com/snes/snes9x"

					# Fetch the webpage content
					try {
						$webpage = Invoke-WebRequest -Uri $snes9xUrl -UseBasicParsing
						# Write-Host "Successfully fetched the Snes9x download page."
					} catch {
						Write-Error "Failed to fetch the Snes9x download page: $_"
						exit 1
					}

					# Parse the webpage content to find download links that end with 'win32-x64.zip'
					$downloadLink = $webpage.Links | Where-Object { $_.href -match 'win32-x64\.zip$' } | Select-Object -First 1

					# If no valid download link is found, exit with an error
					if (-not $downloadLink) {
						Write-Error "No download link found for a file ending with 'win32-x64.zip'."
						exit 1
					}

					# Construct the full download URL by appending the base URL if necessary
					$downloadUrl = $downloadLink.href
					if ($downloadUrl -notmatch '^https?://') {
						$downloadUrl = "https://www.emulator-zone.com" + $downloadUrl
					}

					# Extract the file name from the download link
					$fileName = [System.IO.Path]::GetFileName($downloadUrl)

					# Define the full destination file path
					$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $fileName

					# Use BITS to download the file
					# Write-Host "Downloading $fileName from $downloadUrl to $destinationFilePath"
					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
						Write-Host "Download completed successfully. File saved to $destinationFilePath" -ForegroundColor Green
					} catch {
						Write-Error "Failed to download the file using BITS: $_"
						exit 1
					}
			}
			"VisualBoyAdvance-m" {
                    # VisualBoyAdvance-m Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow		

					# Append 'VisualBoyAdvance-m' to the download path
					$downloadPath = Join-Path -Path $emupath -ChildPath "VisualBoyAdvance-m"

					# Ensure the directory exists; if not, create it
					if (-not (Test-Path -Path $downloadPath)) {
						New-Item -ItemType Directory -Path $downloadPath -Force
					}

					# GitHub API URL for the latest release of VisualBoyAdvance-M
					$apiUrl = "https://api.github.com/repos/visualboyadvance-m/visualboyadvance-m/releases/latest"

					# Set the headers required by the GitHub API (User-Agent is mandatory)
					$headers = @{
						"User-Agent" = "PowershellScript"
					}

					# Fetch the latest release information from GitHub
					try {
						# Write-Host "Fetching latest release information from GitHub..." -ForegroundColor Cyan
						$release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
						# Write-Host "Successfully fetched release information." -ForegroundColor Green
					} catch {
						Write-Error "Failed to fetch release information from GitHub: $_"
						exit 1
					}

					# Look for the asset that matches the required file 'visualboyadvance-m-Win-x86_64.zip'
					$asset = $release.assets | Where-Object { $_.name -eq "visualboyadvance-m-Win-x86_64.zip" }

					# Ensure the asset is found
					if (-not $asset) {
						Write-Error "The file 'visualboyadvance-m-Win-x86_64.zip' was not found in the latest release."
						exit 1
					}

					# Get the version from the release tag (e.g., 'v2.1.4')
					$version = $release.tag_name
					# Write-Host "Latest version: $version" -ForegroundColor Cyan

					# Define the download URL and destination path with the version appended to the filename
					$downloadUrl = $asset.browser_download_url
					$fileName = "visualboyadvance-m-Win-x86_64-$version.zip"
					$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $fileName

					# Use BITS to download the file
					# Write-Host "Downloading $fileName from $downloadUrl to $destinationFilePath" -ForegroundColor Cyan
					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
						Write-Host "Download completed successfully. File saved to $destinationFilePath" -ForegroundColor Green
					} catch {
						Write-Error "Failed to download the file using BITS: $_"
						exit 1
					}
			}
			"Project64" {
                    # Project64 Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
					# Append 'Project64' to the download path
					$downloadPath = Join-Path -Path $emupath -ChildPath "Project64"

					# Ensure the directory exists; if not, create it
					if (-not (Test-Path -Path $downloadPath)) {
						New-Item -ItemType Directory -Path $downloadPath -Force
					}

					# URL for Project64 Nightly Builds
					$pj64Url = "https://www.pj64-emu.com/nightly-builds"

					# Fetch the webpage
					try {
						$webpage = Invoke-WebRequest -Uri $pj64Url -UseBasicParsing
						# Write-Host "Successfully fetched the Project64 Nightly Builds page."
					} catch {
						Write-Error "Failed to fetch the Project64 Nightly Builds page: $_"
						exit 1
					}

					# Extract all the download links from the webpage
					$downloadLinks = $webpage.Content -split "`n" | Where-Object { $_ -match '<a href="/file/project64-win32-dev-.*?/"' }

					# Parse the first link that is a zip file (with class 'btn zip')
					$zipLink = $downloadLinks | Where-Object { $_ -match 'class="btn zip"' } | Select-Object -First 1

					# If no zip download link is found, exit with an error
					if (-not $zipLink) {
						Write-Error "No zip download link found for 'project64-win32-dev-*.zip'."
						exit 1
					}

					# Extract the relative URL using a regex pattern
					$relativeDownloadUrl = $zipLink -match 'href="([^"]+)"' | Out-Null; $relativeDownloadUrl = $matches[1]

					# Extract the version number from the relative URL (e.g., project64-win32-dev-4-0-0-6460-fc23fca)
					$version = $relativeDownloadUrl -replace '^.*project64-win32-dev-', '' -replace '/$', ''

					# Construct the full download URL by appending the base URL
					$baseUrl = "https://www.pj64-emu.com"
					$downloadUrl = $baseUrl + $relativeDownloadUrl

					# Extract the file name from the relative URL using the version information
					$fileName = "project64-win32-dev-$version.zip"

					# Define the full destination file path
					$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $fileName

					# Use BITS to download the file
					# Write-Host "Downloading $fileName from $downloadUrl to $destinationFilePath"
					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
						Write-Host "Download completed successfully. File saved to $destinationFilePath" -ForegroundColor Green
					} catch {
						Write-Error "Failed to download the file using BITS: $_"
						exit 1
					}
			}
            "Dolphin" {
                    # Dolphin Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
                    
                    # Define download path for Dolphin
                    $downloadPath = Join-Path -Path $downloadDir -ChildPath "Dolphin"
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

                    # Find the first download link that matches the specified pattern
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

                    # Start the BITS transfer to download the file
                    try {
                        Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
                        Write-Host "Dolphin download completed successfully. File saved to $destinationFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
                    } catch {
                        Write-Error "Failed to download the file using BITS: $_" -ForegroundColor "Red" -BackgroundColor "Black"
                        exit 1
                    }
                }
			"XEMU" {
                    # XEMU Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
					
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
					# debuging
					#Write-Host "Downloading xemu-win-release.zip from: $downloadUrl"
					#Write-Host "Saving to: $targetFilePath"

					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
						Write-Host "XEMU download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
						Write-Error "Failed to download xemu-win-release.zip: $_" -ForegroundColor "Red" -BackgroundColor "Black"
					}
				}

			"Ryujinx" {
                    # Ryujinx Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
										
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
					# Debugging
					#Write-Host "Downloading Ryujinx from: $downloadUrl"
					#Write-Host "Saving to: $targetFilePath"

					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
						Write-Host "Ryujinx download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
						Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
					}
				}

			"XENIA" {
                    # XENIA Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

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
					# Debugging
					# Write-Host "Downloading XENIA from: $downloadUrl"
					# Write-Host "Saving to: $targetFilePath"

					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
					Write-Host "XENIA download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
						Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
					}
				}

			"Vita3K" {
                    # Vita3K Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

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
					# Debugging
					# Write-Host "Downloading Vita3K from: $downloadUrl"
					# Write-Host "Saving to: $targetFilePath"

					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
						Write-Host "Vita3K download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
					Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
				}
			}

			"Redream" {
                    # Redream Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
				"PCSX2" {
                    # Redream Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

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
				# Debugging
				#Write-Host "Downloading PCSX2 from: $downloadUrl"
				#Write-Host "Saving to: $targetFilePath"

				try {
					Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
					Write-Host "PCSX2 download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
				} catch {
					Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
				}
			}
			"MAME" {
                    # MAME Download Logic for Windows
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
					# Debugging
					# Write-Host "Downloading MAME from: $downloadUrl" -ForegroundColor "Green" -BackgroundColor "Black"
					# Write-Host "Saving file to: $outputFilePath" -ForegroundColor "Green" -BackgroundColor "Black"

					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $outputFilePath
						Write-Host "MAME download completed successfully. File saved as $outputFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
						Write-Error "Failed to download MAME the file using Start-BitsTransfer." -ForegroundColor "Red" -BackgroundColor "Black"
					}
				}
			"Duckstation" {
						  # Duckstation Download Logic for Windows
						  Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
						# Debug
						# Write-Host "Downloading Duckstation from: $downloadUrl"
						# Write-Host "Saving to: $targetFilePath"

						try {
							Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
							Write-Host "Duckstation download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
						} catch {
							Write-Error "Failed to download 'duckstation-windows-x64-release.zip': $_" -ForegroundColor "Red" -BackgroundColor "Black"
							}
						}
			"BigPEmu" {
					# BigPEmu Download Logic for Windows
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
					# Debug
					# Write-Host "Downloading BigPEmu from: $firstZipUrl"
					# Write-Host "Saving to: $outputFilePath"

					try {
						Start-BitsTransfer -Source $firstZipUrl -Destination $outputFilePath
						Write-Host "BigPEmu download completed successfully. File saved as $outputFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
						Write-Error "Failed to download BigPEmu" -ForegroundColor "Red" -BackgroundColor "Black"
					}
				}
			"RPCS3" {
					# RPCS3 Download Logic for Windows
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
			"CEMU" {
					# CEMU Download Logic for Windows
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
			"Lime3DS" {
					# Lime3DS Download Logic for Windows
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
            "RetroArch" {
                # RetroArch Download Logic for Windows
                Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

                # Define the URL for RetroArch platforms page
                $baseUrl = "https://www.retroarch.com/?page=platforms"

                # Define the base path where the files will be downloaded (change this to your desired download location)
                $downloadPathBase = Join-Path -Path $emupath -ChildPath "RetroArch"

                # Ensure the base download directory exists, if not, create it
                if (-not (Test-Path -Path $downloadPathBase)) {
                    New-Item -Path $downloadPathBase -ItemType Directory -Force
                }

                # Function to download files using BITS
                function Download-File {
                    param (
                        [string]$sourceUrl,
                        [string]$destinationPath
                    )

                    try {
                        Start-BitsTransfer -Source $sourceUrl -Destination $destinationPath
                        Write-Host "RetroArch download completed: $destinationPath" -ForegroundColor "Green" -BackgroundColor "Black"
                    } catch {
                        Write-Error "Failed to download $sourceUrl. Error: $_" -ForegroundColor "Red" -BackgroundColor "Black"
                    }
                }

                # Fetch the main webpage from the base URL
                try {
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

                # Extract the version number right after /stable/
                if ($fullDirectoryUrl -match '/stable/([^/]+)/') {
                    $version = $matches[1]
                } else {
                    Write-Host "Unable to extract version number from the URL: $fullDirectoryUrl" -ForegroundColor Red
                    Write-Error "Could not extract version number from the directory URL."
                    exit 1
                }

                # Create a subdirectory under the base path with the version number
                $versionedDownloadPath = Join-Path -Path $downloadPathBase -ChildPath $version

                # Ensure the versioned download directory exists, if not, create it
                if (-not (Test-Path -Path $versionedDownloadPath)) {
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
				"shadPS4" {
					# shadPS4 Download Logic for Windows
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

					# Append 'shadps4' to the path
					$downloadPath = Join-Path -Path $emupath -ChildPath "shadps4"

					# Ensure the directory exists
					if (-not (Test-Path -Path $downloadPath)) {
						New-Item -ItemType Directory -Path $downloadPath -Force
					}

					# GitHub API URL for the latest release of shadPS4
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

					# Start the BITS transfer to download the file
					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
						Write-Host "shadps4 downloaded successfully. File saved to $destinationFilePath" -ForegroundColor Green -BackgroundColor Black
					} catch {
						Write-Error "Failed to download the file. $_" -ForegroundColor Red -BackgroundColor Black
						exit 1
					}
				} 
				"TeknoParrot" {
					# TeknoParrot Download Logic for Windows
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow		
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
				"WinUAE" {
						# WinUAE Download Logic for Windows
						Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow	
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
				"VICE" {
						# VICE Download Logic for Windows
						Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow	
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
				"Xenia Manager" {
						# Xenia Manager Download Logic for Windows
						Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow		
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
				"mGBA" {
						# mGBA Download Logic for Windows
						Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow	
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
				"Rosalie's Mupen GUI" {
								# Rosalie's Mupen GUI Download Logic for Windows
								Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow								
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
	
				"Stella" {
								# Stella Download Logic for Windows
								Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow		
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

								# Look for the asset that starts with "Stella-" and ends with " Stella-7.0a-x64.exe "
								$asset = $response.assets | Where-Object { $_.name -like "Stella-*-x64.exe" }

								# Ensure we found the asset
								if ($null -eq $asset) {
									Write-Error "No file found that matches 'Stella-*-x64.exe'"
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

				"Supermodel" {
								# Supermodel Download Logic for Windows
								Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
				"mupen64plus" {
								# mupen64plus Download Logic for Windows
								Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow		
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
				"Sudachi" {
								# Sudachi Download Logic for Windows
								Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
								
								# Append 'Sudachi' to the base path
								$downloadDir = Join-Path -Path $emupath -ChildPath "Sudachi"

								# Ensure the download directory exists, if not, create it
								if (-not (Test-Path -Path $downloadDir)) {
									New-Item -Path $downloadDir -ItemType Directory -Force
								}

								# GitHub API URL to get the latest release info for the repository
								$apiUrl = "https://api.github.com/repos/emuplace/sudachi.emuplace.app/releases/latest"

								# Set a User-Agent header (required by GitHub API)
								$headers = @{ "User-Agent" = "Mozilla/5.0" }

								# Fetch the latest release information from GitHub
								try {
									$response = Invoke-RestMethod -Uri $apiUrl -Headers $headers
									Write-Host "Successfully fetched latest release information from GitHub." -ForegroundColor Green
								} catch {
									Write-Error "Failed to retrieve latest release info from GitHub: $_"
									exit 1
								}

								# Find the asset that starts with 'sudachi-windows-'
								$asset = $response.assets | Where-Object { $_.name -like "sudachi-windows-*" }

								# Ensure we found a matching asset
								if (-not $asset) {
									Write-Error "No asset found that starts with 'sudachi-windows-'"
									exit 1
								}

								# Get the download URL and asset name
								$downloadUrl = $asset.browser_download_url
								$assetName = $asset.name

								# Define the full path where the file will be downloaded
								$destinationPath = Join-Path -Path $downloadDir -ChildPath $assetName

								# Debugging: Output the download URL and destination path
								Write-Host "Download URL: $downloadUrl"
								Write-Host "Destination Path: $destinationPath"

								# Use BITS to download the file
								Write-Host "Downloading $assetName to $destinationPath..."
								try {
									Start-BitsTransfer -Source $downloadUrl -Destination $destinationPath -Priority Foreground
									Write-Host "Download completed successfully! File saved to $destinationPath" -ForegroundColor Green
								} catch {
									Write-Error "Failed to download the file using BITS: $_"
								}
				}
				"Mednafen" {
								# Mednafen Download Logic for Windows
								# Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
								$downloadDir = Join-Path -Path $emupath -ChildPath "Mednafen"
								# Ensure the download directory exists, if not, create it
								if (-not (Test-Path -Path $downloadDir)) {
									New-Item -Path $downloadDir -ItemType Directory -Force
								}

								# URL for Mednafen downloads page
								$mednafenUrl = "https://mednafen.github.io/releases/"

								# Fetch the HTML content from the Mednafen releases page
								try {
									# Write-Host "Fetching Mednafen releases page..."
									$response = Invoke-WebRequest -Uri $mednafenUrl -UseBasicParsing
									# Write-Host "Successfully fetched the releases page."
								} catch {
									Write-Error "Failed to fetch the Mednafen releases page: $_"
									exit 1
								}

								# Find the download link for the latest version that ends with "-win64.zip"
								$downloadLink = $response.Links | Where-Object { $_.href -match "-win64.zip$" } | Select-Object -First 1

								# Ensure we found a valid download link
								if (-not $downloadLink) {
									Write-Error "No download link found for a file that ends with '-win64.zip'."
									exit 1
								}

								# Construct the full download URL (if necessary)
								$downloadUrl = $downloadLink.href
								if ($downloadUrl -notmatch "^https?://") {
									$uri = [System.Uri]::new($mednafenUrl)
									$downloadUrl = [System.Uri]::new($uri, $downloadUrl).AbsoluteUri
								}

								# Extract the filename from the download URL
								$fileName = [System.IO.Path]::GetFileName($downloadUrl)

								# Define the full path where the file will be downloaded
								$destinationPath = Join-Path -Path $downloadDir -ChildPath $fileName

								# Debug Output the download URL and destination path for debugging
								# Write-Host "Download URL: $downloadUrl"
								# Write-Host "Destination Path: $destinationPath"

								# Use BITS to download the file
								# Write-Host "Downloading $fileName to $destinationPath..."
								try {
									Start-BitsTransfer -Source $downloadUrl -Destination $destinationPath -Priority Foreground
									Write-Host "Mednafen download completed successfully! File saved to $destinationPath" -ForegroundColor Green
								} catch {
									Write-Error "Failed to download the file using BITS: $_"
								}
				}
				"a7800" {
								# a7800 Download Logic for Windows
								Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
								# Append 'a7800' to the base path
								$downloadDir = Join-Path -Path $emupath -ChildPath "a7800"

								# Ensure the download directory exists, if not, create it
								if (-not (Test-Path -Path $downloadDir)) {
									New-Item -Path $downloadDir -ItemType Directory -Force
								}

								# GitHub API URL for latest release of a7800
								$githubApiUrl = "https://api.github.com/repos/7800-devtools/a7800/releases/latest"

								# Set the User-Agent header required by GitHub API
								$headers = @{ "User-Agent" = "Powershell-Script" }

								# Fetch the latest release information from GitHub
								try {
									# Write-Host "Fetching latest release information from GitHub..."
									$releaseInfo = Invoke-RestMethod -Uri $githubApiUrl -Headers $headers
									# Write-Host "Successfully fetched latest release information."
								} catch {
									Write-Error "Failed to fetch release information from GitHub: $_"
									exit 1
								}

								# Find the asset that starts with 'a7800-win-'
								$asset = $releaseInfo.assets | Where-Object { $_.name -like "a7800-win-*" }

								# Ensure we found the correct asset
								if (-not $asset) {
									Write-Error "No asset found with the name starting with 'a7800-win-'"
									exit
								}

								# Extract the download URL and asset name
								$downloadUrl = $asset.browser_download_url
								$assetName = $asset.name

								# Define the full destination file path
								$destinationPath = Join-Path -Path $downloadDir -ChildPath $assetName

								# Output the download URL and destination path for debugging
								# Write-Host "Download URL: $downloadUrl"
								# Write-Host "Destination Path: $destinationPath"

								# Use BITS to download the file
								# Write-Host "Downloading $assetName to $destinationPath..."
								try {
									Start-BitsTransfer -Source $downloadUrl -Destination $destinationPath -Priority Foreground
									Write-Host "Download completed successfully! File saved to $destinationPath" -ForegroundColor Green
								} catch {
									Write-Error "Failed to download the file using BITS: $_"
								}
				}
				"melonDS" {
								# melonDS Download Logic for Windows
								Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
									#Write-Host "Successfully fetched latest melonDS release information." -ForegroundColor Green
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
								# Debug
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
							default {
                Write-Host "$emulatorName is not available for Windows." -ForegroundColor Red
            }
	}
	}
   
        "MacOS" {
            switch ($emulatorName) {
              "Vita3K" {
                    # Vita3K Download Logic for Mac
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

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

					$asset = $release.assets | Where-Object { $_.name -eq "macos-latest.dmg" }

					if (-not $asset) {
					Write-Error "File 'macos-latest.dmg' not found in the continuous release."
					#exit 1
				}

					$downloadUrl = $asset.browser_download_url
					$targetFilePath = Join-Path $vita3kDownloadPath "macos-latest.dmg"
					# Debugging
					# Write-Host "Downloading Vita3K from: $downloadUrl"
					# Write-Host "Saving to: $targetFilePath"

					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
						Write-Host "Vita3K download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
					Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
				}
			}
			"VisualBoyAdvance-m" {
                    # VisualBoyAdvance-m Download Logic for Mac
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow		

					# Append 'VisualBoyAdvance-m' to the download path
					$downloadPath = Join-Path -Path $emupath -ChildPath "VisualBoyAdvance-m"

					# Ensure the directory exists; if not, create it
					if (-not (Test-Path -Path $downloadPath)) {
						New-Item -ItemType Directory -Path $downloadPath -Force
					}

					# GitHub API URL for the latest release of VisualBoyAdvance-M
					$apiUrl = "https://api.github.com/repos/visualboyadvance-m/visualboyadvance-m/releases/latest"

					# Set the headers required by the GitHub API (User-Agent is mandatory)
					$headers = @{
						"User-Agent" = "PowershellScript"
					}

					# Fetch the latest release information from GitHub
					try {
						# Write-Host "Fetching latest release information from GitHub..." -ForegroundColor Cyan
						$release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
						# Write-Host "Successfully fetched release information." -ForegroundColor Green
					} catch {
						Write-Error "Failed to fetch release information from GitHub: $_"
						exit 1
					}
					# Look for the asset that matches the required file 'visualboyadvance-m-Mac-x86_64.zip'
					$asset = $release.assets | Where-Object { $_.name -eq "visualboyadvance-m-Mac-x86_64.zip" }

					# Ensure the asset is found
					if (-not $asset) {
						Write-Error "The file 'visualboyadvance-m-Mac-x86_64.zip' was not found in the latest release."
						exit 1
					}

					# Get the version from the release tag (e.g., 'v2.1.4')
					$version = $release.tag_name
					# Write-Host "Latest version: $version" -ForegroundColor Cyan

					# Define the download URL and destination path with the version appended to the filename
					$downloadUrl = $asset.browser_download_url
					$fileName = "visualboyadvance-m-Mac-x86_64-$version.zip"
					$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $fileName

					# Use BITS to download the file
					# Write-Host "Downloading $fileName from $downloadUrl to $destinationFilePath" -ForegroundColor Cyan
					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
						Write-Host "Download completed successfully. File saved to $destinationFilePath" -ForegroundColor Green
					} catch {
						Write-Error "Failed to download the file using BITS: $_"
						exit 1
					}
			}
				"a7800" {
						# a7800 Download Logic for Mac
								Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
								# Append 'a7800' to the base path
								$downloadDir = Join-Path -Path $emupath -ChildPath "a7800"
		
								# Ensure the download directory exists, if not, create it
								if (-not (Test-Path -Path $downloadDir)) {
									New-Item -Path $downloadDir -ItemType Directory -Force
								}

								# GitHub API URL for latest release of a7800
								$githubApiUrl = "https://api.github.com/repos/7800-devtools/a7800/releases/latest"

								# Set the User-Agent header required by GitHub API
								$headers = @{ "User-Agent" = "Powershell-Script" }

								# Fetch the latest release information from GitHub
								try {
									# Write-Host "Fetching latest release information from GitHub..."
									$releaseInfo = Invoke-RestMethod -Uri $githubApiUrl -Headers $headers
									# Write-Host "Successfully fetched latest release information."
								} catch {
									Write-Error "Failed to fetch release information from GitHub: $_"
									exit 1
								}

								# Find the asset that starts with 'a7800-osx-'
								$asset = $releaseInfo.assets | Where-Object { $_.name -like "a7800-osx-*" }

								# Ensure we found the correct asset
								if (-not $asset) {
									Write-Error "No asset found with the name starting with 'a7800-osx-'"
									exit
								}

								# Extract the download URL and asset name
								$downloadUrl = $asset.browser_download_url
								$assetName = $asset.name

								# Define the full destination file path
								$destinationPath = Join-Path -Path $downloadDir -ChildPath $assetName

								# Output the download URL and destination path for debugging
								# Write-Host "Download URL: $downloadUrl"
								# Write-Host "Destination Path: $destinationPath"

								# Use BITS to download the file
								# Write-Host "Downloading $assetName to $destinationPath..."
								try {
									Start-BitsTransfer -Source $downloadUrl -Destination $destinationPath -Priority Foreground
									Write-Host "Download completed successfully! File saved to $destinationPath" -ForegroundColor Green
								} catch {
									Write-Error "Failed to download the file using BITS: $_"
								}
				}
				"Dolphin" {
                    # Dolphin Download Logic for MacOS using BITS (for storage on Windows)
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
                    
                    # Define download path for Dolphin
                    $downloadPath = Join-Path -Path $downloadDir -ChildPath "Dolphin"
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

                    # Find the first Mac download link (universal dmg) on the page
                    $downloadLink = $webContent.Links | Where-Object {
                        $_.href -match "^https://dl\.dolphin-emu\.org/builds/[a-z0-9]+/[a-z0-9]+/dolphin-master-\d+-\d+-universal\.dmg$"
                    } | Select-Object -First 1

                    if (-not $downloadLink) {
                        Write-Error "No download link found for a file that matches 'dolphin-master-####-86-universal.dmg'."
                        exit 1
                    }

                    # Get the full download URL
                    $downloadUrl = $downloadLink.href

                    # Define the destination file path
                    $fileName = [System.IO.Path]::GetFileName($downloadUrl)
                    $destinationFilePath = Join-Path -Path $downloadPath -ChildPath $fileName

                    # Start the BITS transfer to download the file
                    try {
                        Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
                        Write-Host "Dolphin (Mac version) download completed successfully. File saved to $destinationFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
                    } catch {
                        Write-Error "Failed to download the file using BITS: $_" -ForegroundColor "Red" -BackgroundColor "Black"
                        exit 1
                    }
                }

				"Redream" {
                    # Redream Download Logic for Mac
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
					$redreamDownloadPath = Join-Path -Path $downloadDir -ChildPath "Redream"

					# Ensure the Redream directory exists
					if (-not (Test-Path -Path $redreamDownloadPath)) {
						New-Item -ItemType Directory -Path $redreamDownloadPath -Force | Out-Null
					}

					# URL of the Redream download page
					$redreamUrl = "https://redream.io/download"

					# Fetch the HTML content of the download page
					try {
					$webContent = Invoke-WebRequest -Uri $redreamUrl -UseBasicParsing
					} catch {
						Write-Error "Failed to fetch the Redream download page: $_"
						exit 1
					}

					# Use regular expression to find the macOS download link that matches "redream.universal-mac" pattern
					$macLinkRegex = '/download/redream\.universal-mac-[\w\.\-]+\.tar\.gz'
					$macDownloadLink = $webContent.Content -match $macLinkRegex | Out-Null

					# Check if the download link was found
					if ($Matches[0]) {
					# Construct the full download URL
					$downloadUrl = "https://redream.io$($Matches[0])"
					$fileName = [System.IO.Path]::GetFileName($downloadUrl)
					$destinationFilePath = Join-Path -Path $redreamDownloadPath -ChildPath $fileName

					# Debug output to confirm the download URL and destination path
					Write-Host "Selected download URL: $downloadUrl" -ForegroundColor Cyan
					Write-Host "Destination path: $destinationFilePath" -ForegroundColor Cyan

					# Start the BITS transfer to download the file
					try {
					Write-Host "Downloading the latest Redream development release for macOS from $downloadUrl..."
					Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
					Write-Host "Download completed successfully. File saved to $destinationFilePath" -ForegroundColor Green
					} catch {
						Write-Error "Failed to download Redream: $_"
					}
					} else {
					Write-Error "No macOS development release download link found on the Redream download page."
					}
					}
				"PCSX2" {
                    # PCSX2 Download Logic for Mac
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

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
				$asset = $preRelease.assets | Where-Object { $_.name -like "*macos-Qt.tar.xz" }

				if (-not $asset) {
					Write-Error "File ending with 'macos-Qt.tar.xz' not found in the latest pre-release."
					exit 1
				}

				$downloadUrl = $asset.browser_download_url
				$targetFilePath = Join-Path $pcsx2DownloadPath $asset.name
				# Debugging
				#Write-Host "Downloading PCSX2 from: $downloadUrl"
				#Write-Host "Saving to: $targetFilePath"

				try {
					Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
					Write-Host "PCSX2 download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
				} catch {
					Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
				}
			}

				"MAME" {
                    # MAME Download Logic for Mac
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
					# Define the emulator path
					$mameDownloadDir = Join-Path -Path $emupath -ChildPath "Mame"

					# Ensure the MAME directory exists
					if (-not (Test-Path $mameDownloadDir)) {
						New-Item -ItemType Directory -Path $mameDownloadDir -Force
					}

					# URL of the website to scrape for the latest release
					$mameUrl = "https://sdlmame.lngn.net/"

					# Define regex pattern to match the MAME release link (e.g., stable/mame0270-arm64.zip)
					# The version number will change with new releases, so we allow any digits
					$mameLinkPattern = 'href="(stable/mame\d+-arm64\.zip)"'

					try {
						# Fetch the web page content
						$webContent = Invoke-WebRequest -Uri $mameUrl
					} catch {
						Write-Error "Failed to fetch the MAME download page: $_"
						exit 1
					}

					# Debug: Display the HTML content to verify it's fetched correctly
					# Write-Host "Web Content: $($webContent.Content)"  # Uncomment for debugging if needed

					# Search for the download link in the HTML content using regex
					if ($webContent.Content -match $mameLinkPattern) {
						# Extract the matched link (group 1 from the regex)
						$mameDownloadLink = $matches[1]
					} else {
						$mameDownloadLink = $null
					}

					# Check if a valid download link was found
					if (-not $mameDownloadLink) {
						Write-Error "No MAME release download link found on the page."
						exit 1
					}

					# Construct the full download URL by appending the base URL
					$mameDownloadUrl = "https://sdlmame.lngn.net/$mameDownloadLink"

					# Extract the file name from the download URL
					$fileName = [System.IO.Path]::GetFileName($mameDownloadUrl)

					# Define the full path where the MAME file will be saved
					$destinationFilePath = Join-Path -Path $mameDownloadDir -ChildPath $fileName

					# Debug Show the download URL and destination path
					# Write-Host "Download URL: $mameDownloadUrl"
					# Write-Host "Saving to: $destinationFilePath"

					# Start the BITS transfer to download the file
					try {
						Start-BitsTransfer -Source $mameDownloadUrl -Destination $destinationFilePath -Priority Foreground
						Write-Host "MAME download completed successfully. File saved to $destinationFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
						Write-Error "Failed to download MAME: $_"
						exit 1
	}
}
			
				"Duckstation" {
						  # Duckstation Download Logic for Mac
						  Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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

						$asset = $release.assets | Where-Object { $_.name -eq "duckstation-mac-release.zip" }

						if (-not $asset) {
							Write-Error "File 'duckstation-mac-release.zip' not found in the latest release."
							exit 1
						}

						$downloadUrl = $asset.browser_download_url
						$targetFilePath = Join-Path $duckstationDownloadPath "duckstation-mac-release.zip"
						# Debug
						 Write-Host "Downloading Duckstation from: $downloadUrl"
						 Write-Host "Saving to: $targetFilePath"

						try {
							Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
							Write-Host "Duckstation download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
						} catch {
							Write-Error "Failed to download 'duckstation-mac-release.zip': $_" -ForegroundColor "Red" -BackgroundColor "Black"
							}
						}

				"CEMU" {
						# CEMU Download Logic for Mac
						Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
  
						# Find the asset that ends with "macos-12-x64.dmg"
					$asset = $release.assets | Where-Object { $_.name -like "*macos-12-x64.dmg" }

					if (-not $asset) {
						Write-Error "File 'macos-12-x64.dmg' not found in the latest release."
						exit 1
				}

						# Define the download URL and the target file path
					$downloadUrl = $asset.browser_download_url
					$targetFilePath = Join-Path $cemuDownloadPath $asset.name

					# Debug: Check if $downloadUrl and $targetFilePath are correctly set
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
			"Lime3DS" {
					# Lime3DS Download Logic for Mac
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
						# Filter for assets that end with -macos-universal.zip'
					$assetsToDownload = $release.assets | Where-Object { $_.name -match "(-macos-universal.zip)" }

					if (-not $assetsToDownload) {
						Write-Error "No files ending with '-macos-universal.zip' found in the latest release."
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
			"RPCS3" {
					# RPCS3 Download Logic for Mac
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
					$rpcs3DownloadPath = Join-Path $emupath "RPCS3"
					if (-not (Test-Path -Path $rpcs3DownloadPath)) {
						#Write-Host "Creating directory: $rpcs3DownloadPath"
						New-Item -Path $rpcs3DownloadPath -ItemType Directory -Force
					}

					$apiUrl = "https://api.github.com/repos/RPCS3/rpcs3-binaries-mac/releases/latest"
					$headers = @{ "User-Agent" = "Mozilla/5.0" }

					try {
						$release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
						#Write-Host "Successfully fetched latest RPCS3 release information."
					} catch {
						Write-Error "Failed to retrieve latest release info from GitHub: $_"
						exit 1
					}

					$asset = $release.assets | Where-Object { $_.name -like "*macos.7z" }

					if (-not $asset) {
						Write-Error "File ending with 'macos.7z' not found in the latest release."
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
			
			"shadPS4" {
					# shadPS4 Download Logic for Mac
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

					# Append 'shadps4' to the path
					$downloadPath = Join-Path -Path $emupath -ChildPath "shadps4"

					# Ensure the directory exists
					if (-not (Test-Path -Path $downloadPath)) {
						New-Item -ItemType Directory -Path $downloadPath -Force
					}

					# GitHub API URL for the latest release of shadPS4
					$githubApiUrl = "https://api.github.com/repos/shadps4-emu/shadPS4/releases/latest"

					# Use Invoke-RestMethod to get the latest release information
					try {
						$releaseInfo = Invoke-RestMethod -Uri $githubApiUrl -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
					} catch {
						Write-Error "Failed to fetch release information from GitHub. $_"
						exit 1
					}

					# Find the asset URL for the file that starts with "shadps4-macos-qt-"
					$asset = $releaseInfo.assets | Where-Object { $_.name -like "shadps4-macos-qt-*" }

					if (-not $asset) {
						Write-Error "No asset found with a name starting with 'shadps4-macos-qt-'."
						exit 1
					}

					# Get the download URL
					$downloadUrl = $asset.browser_download_url

					# Define the destination file path
					$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $asset.name

					# Start the BITS transfer to download the file
					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
						Write-Host "shadps4 downloaded successfully. File saved to $destinationFilePath" -ForegroundColor Green -BackgroundColor Black
					} catch {
						Write-Error "Failed to download the file. $_" -ForegroundColor Red -BackgroundColor Black
						exit 1
					}
				
                default {
                    Write-Host "$emulatorName is not available for MacOS." -ForegroundColor Red
                }
            }
        }
		}
        "Linux" {
            switch ($emulatorName) {
			"Vita3K" {
                    # Vita3K Download Logic for Linux
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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

					$asset = $release.assets | Where-Object { $_.name -eq "ubuntu-latest.zip" }

					if (-not $asset) {
					Write-Error "File 'ubuntu-latest.zip' not found in the continuous release."
					#exit 1
				}

					$downloadUrl = $asset.browser_download_url
					$targetFilePath = Join-Path $vita3kDownloadPath "ubuntu-latest.zip"
					# Debugging
					# Write-Host "Downloading Vita3K from: $downloadUrl"
					# Write-Host "Saving to: $targetFilePath"

					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
						Write-Host "Vita3K download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
					Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
				}
				}
			"a7800" {
					# a7800 Download Logic for Linux
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
					# Append 'a7800' to the base path
					$downloadDir = Join-Path -Path $emupath -ChildPath "a7800"
		
					# Ensure the download directory exists, if not, create it
					if (-not (Test-Path -Path $downloadDir)) {
						New-Item -Path $downloadDir -ItemType Directory -Force
					}
					# GitHub API URL for latest release of a7800
					$githubApiUrl = "https://api.github.com/repos/7800-devtools/a7800/releases/latest"

					# Set the User-Agent header required by GitHub API
					$headers = @{ "User-Agent" = "Powershell-Script" }

					# Fetch the latest release information from GitHub
					try {
						# Write-Host "Fetching latest release information from GitHub..."
						$releaseInfo = Invoke-RestMethod -Uri $githubApiUrl -Headers $headers
						# Write-Host "Successfully fetched latest release information."
					} catch {
						Write-Error "Failed to fetch release information from GitHub: $_"
						exit 1
					}
					# Find the asset that starts with 'a7800-linux-'
					$asset = $releaseInfo.assets | Where-Object { $_.name -like "a7800-linux-*" }
					# Ensure we found the correct asset
					if (-not $asset) {
						Write-Error "No asset found with the name starting with 'a7800-linux-'"
						exit
					}
					# Extract the download URL and asset name
					$downloadUrl = $asset.browser_download_url
					$assetName = $asset.name
					# Define the full destination file path
					$destinationPath = Join-Path -Path $downloadDir -ChildPath $assetName

					# Output the download URL and destination path for debugging
					# Write-Host "Download URL: $downloadUrl"
					# Write-Host "Destination Path: $destinationPath"

					# Use BITS to download the file
					# Write-Host "Downloading $assetName to $destinationPath..."
					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $destinationPath -Priority Foreground
						Write-Host "Download completed successfully! File saved to $destinationPath" -ForegroundColor Green
					} catch {
							Write-Error "Failed to download the file using BITS: $_"
						}
				}
			"Redream" {
                    # Redream Download Logic for Linux
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
					# Define the download directory
					if (-not (Test-Path $downloadDir)) { New-Item -ItemType Directory -Path $downloadDir -Force }

					# URL for the Redream download page
					$downloadPageUrl = "https://redream.io/download"

					try {
					# Fetch the web page content
					$webContent = Invoke-WebRequest -Uri $downloadPageUrl -UseBasicParsing

					# Define the refined regex for the latest macOS development release link in the Development Releases section
					$macLinkRegex = '/download/redream\.universal-mac-v[\d\.]+-[\d]+-g[0-9a-f]+\.tar\.gz'

					# Search for "Development Releases" section
					$devReleasesSection = $webContent.Content -split '<div class="my-5">' | Where-Object { $_ -match 'Development Releases' }

					# Extract the macOS download link from the Development Releases section
					if ($devReleasesSection -match $macLinkRegex) {
					$macDownloadLink = $matches[0]

					# Complete the download URL by adding the base URL
					$fullDownloadUrl = "https://redream.io$macDownloadLink"
					Write-Host "Download link found: $fullDownloadUrl"

					# Define the destination file path
					$fileName = [System.IO.Path]::GetFileName($fullDownloadUrl)
					$destinationFilePath = Join-Path -Path $downloadDir -ChildPath $fileName

					# Download using BITS
					Start-BitsTransfer -Source $fullDownloadUrl -Destination $destinationFilePath -Priority Foreground
					Write-Host "Download completed successfully. File saved to $destinationFilePath" -ForegroundColor Green
					} else {
					Write-Error "No macOS development release download link found on the Redream download page."
				}
					} catch {
					Write-Error "Failed to retrieve or download the Redream macOS release: $_"
			}

				}
			"PCSX2" {
                    # PCSX2 Download Logic for Linux
                    Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

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
				$asset = $preRelease.assets | Where-Object { $_.name -like "*linux-appimage-x64-Qt.AppImage" }

				if (-not $asset) {
					Write-Error "File ending with 'linux-appimage-x64-Qt.AppImage' not found in the latest pre-release."
					exit 1
				}

				$downloadUrl = $asset.browser_download_url
				$targetFilePath = Join-Path $pcsx2DownloadPath $asset.name
				# Debugging
				#Write-Host "Downloading PCSX2 from: $downloadUrl"
				#Write-Host "Saving to: $targetFilePath"

				try {
					Start-BitsTransfer -Source $downloadUrl -Destination $targetFilePath
					Write-Host "PCSX2 download completed successfully. File saved to $targetFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
				} catch {
					Write-Error "Failed to download $($asset.name): $_" -ForegroundColor "Red" -BackgroundColor "Black"
				}
			}
			"BigPEmu" {
					# BigPEmu Download Logic for Linux
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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

					$tarLinks = Select-String -InputObject $htmlContent.Content -Pattern 'href="([^"]+\.tar.gz)"' -AllMatches

					if (-not $tarLinks.Matches) {
						Write-Error "No .tar.gz files found on the page."
						return
					}

					$firsttarUrl = $tarLinks.Matches[0].Groups[1].Value

					if ($firsttarUrl -notmatch "^https?:\/\/") {
						$uri = New-Object System.Uri($downloadPageUrl)
						$firsttarUrl = [System.IO.Path]::Combine($uri.GetLeftPart("Scheme"), $firsttarUrl)
					}

					#Write-Host "Found .zip file URL: $firsttarUrl"
					$fileName = [System.IO.Path]::GetFileName($firsttarUrl)
					$outputFilePath = Join-Path -Path $bigPemuDownloadPath -ChildPath $fileName
					# Debug
					# Write-Host "Downloading BigPEmu from: $firsttarUrl"
					# Write-Host "Saving to: $outputFilePath"

					try {
						Start-BitsTransfer -Source $firsttarUrl -Destination $outputFilePath
						Write-Host "BigPEmu download completed successfully. File saved as $outputFilePath" -ForegroundColor "Green" -BackgroundColor "Black"
					} catch {
						Write-Error "Failed to download BigPEmu" -ForegroundColor "Red" -BackgroundColor "Black"
					}
				}
			"CEMU" {
						# CEMU Download Logic for Linux
						Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
  
						# Find the asset that ends with "ubuntu-22.04-x64.zip"
					$asset = $release.assets | Where-Object { $_.name -like "*ubuntu-*-x64.zip" }

					if (-not $asset) {
						Write-Error "File 'ubuntu-22.04-x64.zip ' not found in the latest release."
						exit 1
				}

						# Define the download URL and the target file path
					$downloadUrl = $asset.browser_download_url
					$targetFilePath = Join-Path $cemuDownloadPath $asset.name

					# Debug: Check if $downloadUrl and $targetFilePath are correctly set
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
			"Lime3DS" {
					# Lime3DS Download Logic for Linux
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
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
						# Filter for assets that end with -linux-appimage.tar.gz'
					$assetsToDownload = $release.assets | Where-Object { $_.name -match "(-linux-appimage.tar.gz)" }

					if (-not $assetsToDownload) {
						Write-Error "No files ending with '-linux-appimage.tar.gz' found in the latest release."
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
			"Sudachi" {
					# Sudachi Download Logic for Linux
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
					$downloadPath = Join-Path -Path $emupath -ChildPath "melonDS"
							
					# Append 'Sudachi' to the base path
					$downloadDir = Join-Path -Path $emupath -ChildPath "Sudachi"
					# Ensure the download directory exists, if not, create it
					if (-not (Test-Path -Path $downloadDir)) {
						New-Item -Path $downloadDir -ItemType Directory -Force
					}

					# GitHub API URL to get the latest release info for the repository
					$apiUrl = "https://api.github.com/repos/emuplace/sudachi.emuplace.app/releases/latest"

					# Set a User-Agent header (required by GitHub API)
					$headers = @{ "User-Agent" = "Mozilla/5.0" }

					# Fetch the latest release information from GitHub
					try {
						$response = Invoke-RestMethod -Uri $apiUrl -Headers $headers
						Write-Host "Successfully fetched latest release information from GitHub." -ForegroundColor Green
					} catch {
						Write-Error "Failed to retrieve latest release info from GitHub: $_"
						exit 1
					}

					asset = $response.assets | Where-Object { $_.name -like "sudachi-linux-*" }

					# Ensure we found a matching asset
					if (-not $asset) {
						Write-Error "No asset found that starts with 'sudachi-linux-'"
						exit 1
					}

					# Get the download URL and asset name
					$downloadUrl = $asset.browser_download_url
					$assetName = $asset.name

					# Define the full path where the file will be downloaded
					$destinationPath = Join-Path -Path $downloadDir -ChildPath $assetName

					# Debugging: Output the download URL and destination path
					# Write-Host "Download URL: $downloadUrl"
					# Write-Host "Destination Path: $destinationPath"

					# Use BITS to download the file
					# Write-Host "Downloading $assetName to $destinationPath..."
					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $destinationPath -Priority Foreground
						Write-Host "Sudachi download completed successfully! File saved to $destinationPath" -ForegroundColor Green
					} catch {
						Write-Error "Failed to download the file using BITS: $_"
					}
			}
				"Mednafen" {
						# Mednafen Download Logic for Linux
						Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow
						$downloadDir = Join-Path -Path $emupath -ChildPath "Mednafen"
						# Ensure the download directory exists, if not, create it
						if (-not (Test-Path -Path $downloadDir)) {
							New-Item -Path $downloadDir -ItemType Directory -Force
						}

						# URL for Mednafen downloads page
						$mednafenUrl = "https://mednafen.github.io/releases/"

						# Fetch the HTML content from the Mednafen releases page
						try {
						# Write-Host "Fetching Mednafen releases page..."
						$response = Invoke-WebRequest -Uri $mednafenUrl -UseBasicParsing
						# Write-Host "Successfully fetched the releases page."
						} catch {
							Write-Error "Failed to fetch the Mednafen releases page: $_"
							exit 1
						}

						# Find the download link for the latest version that ends with ".tar.xz"
						$downloadLink = $response.Links | Where-Object { $_.href -match ".tar.xz$" } | Select-Object -First 1

						# Ensure we found a valid download link
						if (-not $downloadLink) {
							Write-Error "No download link found for a file that ends with '-win64.zip'."
							exit 1
						}

						# Construct the full download URL (if necessary)
						$downloadUrl = $downloadLink.href
						if ($downloadUrl -notmatch "^https?://") {
							$uri = [System.Uri]::new($mednafenUrl)
							$downloadUrl = [System.Uri]::new($uri, $downloadUrl).AbsoluteUri
						}

						# Extract the filename from the download URL
						$fileName = [System.IO.Path]::GetFileName($downloadUrl)

						# Define the full path where the file will be downloaded
						$destinationPath = Join-Path -Path $downloadDir -ChildPath $fileName

						# Debug Output the download URL and destination path for debugging
						# Write-Host "Download URL: $downloadUrl"
						# Write-Host "Destination Path: $destinationPath"

						# Use BITS to download the file
						# Write-Host "Downloading $fileName to $destinationPath..."
						try {
							Start-BitsTransfer -Source $downloadUrl -Destination $destinationPath -Priority Foreground
							Write-Host "Mednafen download completed successfully! File saved to $destinationPath" -ForegroundColor Green
						} catch {
							Write-Error "Failed to download the file using BITS: $_"
						}
		}			
			"shadPS4" {
					# shadPS4 Download Logic for Linux
					Write-Host "$emulatorName selected, proceeding with download." -ForegroundColor Yellow

					# Append 'shadps4' to the path
					$downloadPath = Join-Path -Path $emupath -ChildPath "shadps4"

					# Ensure the directory exists
					if (-not (Test-Path -Path $downloadPath)) {
						New-Item -ItemType Directory -Path $downloadPath -Force
					}

					# GitHub API URL for the latest release of shadPS4
					$githubApiUrl = "https://api.github.com/repos/shadps4-emu/shadPS4/releases/latest"

					# Use Invoke-RestMethod to get the latest release information
					try {
						$releaseInfo = Invoke-RestMethod -Uri $githubApiUrl -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
					} catch {
						Write-Error "Failed to fetch release information from GitHub. $_"
						exit 1
					}

					# Find the asset URL for the file that starts with "shadps4-linux-qt-"
					$asset = $releaseInfo.assets | Where-Object { $_.name -like "shadps4-linux-qt-*" }

					if (-not $asset) {
						Write-Error "No asset found with a name starting with 'shadps4-linux-qt-'."
						exit 1
					}

					# Get the download URL
					$downloadUrl = $asset.browser_download_url

					# Define the destination file path
					$destinationFilePath = Join-Path -Path $downloadPath -ChildPath $asset.name

					# Start the BITS transfer to download the file
					try {
						Start-BitsTransfer -Source $downloadUrl -Destination $destinationFilePath -Priority Foreground
						Write-Host "shadps4 downloaded successfully. File saved to $destinationFilePath" -ForegroundColor Green -BackgroundColor Black
					} catch {
						Write-Error "Failed to download the file. $_" -ForegroundColor Red -BackgroundColor Black
						exit 1
					}
					
			default {
                    Write-Host "$emulatorName is not available for Linux." -ForegroundColor Red
                }
			
			
			default {
					Write-Host "Unknown OS selection: $global:SelectedOS. Please select a valid OS." -ForegroundColor Red
			}
			}
			}
		}
	}
}

# Main script loop
$exit = $false

while (-not $exit) {
    # Step 1: Select the OS if not already set
    if (-not $global:SelectedOS) {
        Select-OS
    }

    # Step 2: Display emulator menu and get user input
    $emuChoice, $emulatorsForOS = Show-EmulatorMenu

    if ($emuChoice -eq "OS") {
        Select-OS
        continue
    }
    elseif ($emuChoice -eq "all") {
        # Download all emulators for the selected OS
        	foreach ($emulatorName in $emulatorsForOS) {
            Download-Emulator -emulatorName $emulatorName
        }
    }
    elseif ($emuChoice -eq "exit") {
        Write-Host "Thanks for trying out Emulator Auto-Downdloads. Goodbye!" -ForegroundColor Green
        $exit = $true
    }
    elseif ($emuChoice -match '^\d+$') {
        $emuIndex = [int]$emuChoice - 1
        if ($emuIndex -ge 0 -and $emuIndex -lt $emulatorsForOS.Count) {
            # Correctly pick the emulator from the selected list
            $emulatorName = $emulatorsForOS[$emuIndex]
            Download-Emulator -emulatorName $emulatorName
        } else {
            Write-Host "Invalid emulator choice. Please enter a valid number between 1 and $($emulatorsForOS.Count)." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Invalid emulator choice. Please enter a valid number between 1 and $($emulatorsForOS.Count), type 'all', or 'exit'." -ForegroundColor Yellow
    }

    # Start-Sleep -Seconds 2  # Optional: small delay before returning to menu
		}
