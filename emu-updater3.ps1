# Define the URLs and download paths
$emulators = @{
    "Vita3K" = @{
        "url" = "https://github.com/Vita3K/Vita3K/releases/download/continuous/windows-latest.zip"
        "path" = "N:\emulator-updates\Vita3K\Vita3K-windows-latest.zip"
        "prefix" = "Vita3K-"
    }
    "XENIA" = @{
        "url" = "https://github.com/xenia-canary/xenia-canary/releases/download/experimental/xenia_canary.zip"
        "path" = "N:\emulator-updates\XENIA\XENIA-xenia_canary.zip"
        "prefix" = "XENIA-"
    }
    "XEMU" = @{
        "baseUrl" = "https://github.com/xemu-project/xemu/releases/download/"
        "version" = "v0.7.126"  # Current known version
        "file" = "xemu-win-release.zip"
        "basePath" = "N:\emulator-updates\XEMU\"
        "prefix" = "XEMU-"
    }
    "Ryujinx" = @{
        "baseUrl" = "https://github.com/Ryujinx/release-channel-master/releases/download/"
        "version" = "1.1.1330"  # Current known version
        "filePrefix" = "ryujinx-"
        "fileSuffix" = "-win_x64.zip"
        "basePath" = "N:\emulator-updates\Ryujinx\"
        "prefix" = "Ryujinx-"
    }
    "Redream" = @{
        "baseUrl" = "https://redream.io/download/"
        "version" = "v1.5.0-1120"  # Current known version
        "filePrefix" = "redream.x86_64-windows-"
        "fileSuffix" = ".zip"
        "basePath" = "N:\emulator-updates\Redream\"
        "prefix" = "Redream-"
    }
    "RPCS3" = @{
        "baseUrl" = "https://github.com/RPCS3/rpcs3-binaries-win/releases/download/"
        "version" = "build-5b973448bf75a239f34fd9c7698c8a02b04e2ea9"  # Current known version
        "filePrefix" = "rpcs3-v0.0.32-16614-"
        "fileSuffix" = "_win64.7z"
        "basePath" = "N:\emulator-updates\RPCS3\"
        "prefix" = "RPCS3-"
    }
    "PSX2" = @{
        "baseUrl" = "https://github.com/PCSX2/pcsx2/releases/download/"
        "version" = "v1.7.5901"  # Current known version
        "fileSuffix" = "-windows-x64-Qt.7z"
        "basePath" = "N:\emulator-updates\PSX2\"
        "prefix" = "PSX2-"
    }
    "PPSSPP" = @{
        "baseUrl" = "https://builds.ppsspp.org/builds/"
        "version" = "v1.17.1-762-gcfcca0ed1"  # Current known version
        "file" = "ppsspp_win.zip"
        "basePath" = "N:\emulator-updates\PPSSPP\"
        "prefix" = "PPSSPP-"
    }
    "MAME" = @{
        "baseUrl" = "https://github.com/mamedev/mame/releases/download/"
        "version" = "mame0266"  # Current known version
        "file" = "mame0266b_64bit.exe"
        "basePath" = "N:\emulator-updates\MAME\"
        "prefix" = "MAME-"
    }
    "Duckstation" = @{
        "url" = "https://github.com/stenzek/duckstation/releases/download/latest/duckstation-windows-x64-release.zip"
        "path" = "N:\emulator-updates\Duckstation\duckstation-windows-x64-release.zip"
        "prefix" = "Duckstation-"
    }
}

# Function to download a file
function Download-Emulator {
    param (
        [string]$name
    )

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
    elseif ($name -eq "RPCS3") {
        # Get the latest version from the GitHub releases API
        $apiUrl = "https://api.github.com/repos/RPCS3/rpcs3-binaries-win/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $latestVersion = $response.assets[0].name -replace ".*-(v[\d\.]+-\d+)-.*", '$1'

        # Check if the latest version is greater than the current known version
        if ($latestVersion -gt $emulators[$name]["version"]) {
            $emulators[$name]["version"] = $latestVersion
        }

        $url = $emulators[$name]["baseUrl"] + "build-" + $response.assets[0].name.Split('-')[1] + "/" + $response.assets[0].name
        $path = $emulators[$name]["basePath"] + $emulators[$name]["prefix"] + $emulators[$name]["version"] + ".7z"
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
    elseif ($name -eq "MAME") {
        # Get the latest version from the GitHub releases API
        $apiUrl = "https://api.github.com/repos/mamedev/mame/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $latestVersion = $response.tag_name

        # Check if the latest version is greater than the current known version
        if ($latestVersion -gt $emulators[$name]["version"]) {
            $emulators[$name]["version"] = $latestVersion
        }

        $url = $emulators[$name]["baseUrl"] + $emulators[$name]["version"] + "/" + $response.assets | Where-Object { $_.name -match "\.exe" } | Select-Object -ExpandProperty browser_download_url
        $path = $emulators[$name]["basePath"] + $emulators[$name]["prefix"] + $emulators[$name]["version"] + ".exe"
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
        Write-Host "Failed to download $name $($)"
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
    Write-Host "6. Download RPCS3"
    Write-Host "7. Download PSX2"
    Write-Host "8. Download PPSSPP"
    Write-Host "9. Download MAME"
    Write-Host "10. Download Duckstation"
    Write-Host "11. Download All"
    Write-Host "12. Exit"
}

# Main script loop
$exit = $false
while (-not $exit) {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-12)"
    
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
            Download-Emulator -name "RPCS3"
        }
        7 {
            Download-Emulator -name "PSX2"
        }
        8 {
            Download-Emulator -name "PPSSPP"
        }
        9 {
            Download-Emulator -name "MAME"
        }
        10 {
            Download-Emulator -name "Duckstation"
        }
        11 {
            foreach ($emulator in $emulators.Keys) {
                Download-Emulator -name $emulator
            }
        }
        12 {
            Write-Host "Exiting..."
            $exit = $true
        }
        default {
            Write-Host "Invalid choice. Please enter a number between 1 and 12."
        }
    }
}
