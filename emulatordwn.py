import requests
import os

emulators = {
    "Vita3K": {
        "url": "https://github.com/Vita3K/Vita3K/releases/download/continuous/windows-latest.zip",
        "path": "N:\\emulator-updates\\Vita3K\\Vita3K-windows-latest.zip",
        "prefix": "Vita3K-"
    },
    "XENIA": {
        "url": "https://github.com/xenia-canary/xenia-canary/releases/download/experimental/xenia_canary.zip",
        "path": "N:\\emulator-updates\\XENIA\\XENIA-xenia_canary.zip",
        "prefix": "XENIA-"
    },
    "XEMU": {
        "base_url": "https://github.com/xemu-project/xemu/releases/download/",
        "version": "v0.7.126",  # Current known version
        "file": "xemu-win-release.zip",
        "base_path": "N:\\emulator-updates\\XEMU\\",
        "prefix": "XEMU-"
    },
    "Ryujinx": {
        "base_url": "https://github.com/Ryujinx/release-channel-master/releases/download/",
        "version": "1.1.1330",  # Current known version
        "file_prefix": "ryujinx-",
        "file_suffix": "-win_x64.zip",
        "base_path": "N:\\emulator-updates\\Ryujinx\\",
        "prefix": "Ryujinx-"
    },
    "Redream": {
        "base_url": "https://redream.io/download/",
        "version": "v1.5.0-1120",  # Current known version
        "file_prefix": "redream.x86_64-windows-",
        "file_suffix": ".zip",
        "base_path": "N:\\emulator-updates\\Redream\\",
        "prefix": "Redream-"
    },
    "PSX2": {
        "base_url": "https://github.com/PCSX2/pcsx2/releases/download/",
        "version": "v1.7.5901",  # Current known version
        "file_suffix": "-windows-x64-Qt.7z",
        "base_path": "N:\\emulator-updates\\PSX2\\",
        "prefix": "PSX2-"
    },
    "PPSSPP": {
        "base_url": "https://builds.ppsspp.org/builds/",
        "version": "v1.17.1-762-gcfcca0ed1",  # Current known version
        "file": "ppsspp_win.zip",
        "base_path": "N:\\emulator-updates\\PPSSPP\\",
        "prefix": "PPSSPP-"
    },
    "MAME": {
        "base_url": "https://www.mamedev.org/release.html",
        "version": "v0.253",  # Current known version
        "file": "mame0253b_64bit.exe",
        "base_path": "N:\\emulator-updates\\MAME\\",
        "prefix": "MAME-"
    },
    "Duckstation": {
        "base_url": "https://github.com/stenzek/duckstation/releases/download/",
        "version": "dev_build",
        "file": "duckstation-windows-x64-release.zip",
        "base_path": "N:\\emulator-updates\\Duckstation\\",
        "prefix": "Duckstation-"
    },
    "BigPEmu": {
        "base_url": "https://github.com/aaronsg/BigPEmu/releases/download/",
        "version": "v1.014",
        "file": "BigPEmu_1.014.zip",
        "base_path": "N:\\emulator-updates\\BigPEmu\\",
        "prefix": "BigPEmu-"
    },
    "RPCS3": {
        "base_url": "https://github.com/RPCS3/rpcs3-binaries-win/releases/download/",
        "version": "0.0.22-13633",
        "file": "rpcs3-v0.0.22-13633-c207cb3c_win64.7z",
        "base_path": "N:\\emulator-updates\\RPCS3\\",
        "prefix": "RPCS3-"
    }
}

def download_emulator(name):
    emulator = emulators.get(name)
    if not emulator:
        print(f"Emulator {name} not found.")
        return

    if "url" in emulator:
        url = emulator["url"]
    else:
        url = f"{emulator['base_url']}{emulator['version']}/{emulator['file']}"
    
    path = emulator["path"] if "path" in emulator else f"{emulator['base_path']}{emulator['prefix']}{emulator['version']}.zip"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        with open(path, 'wb') as file:
            file.write(response.content)
        print(f"{name} downloaded to {path}")
    except requests.exceptions.RequestException as e:
        print(f"Failed to download {name}: {e}")

def show_menu():
    print("Select an option:")
    print("1. Download Vita3K")
    print("2. Download XENIA")
    print("3. Download XEMU")
    print("4. Download Ryujinx")
    print("5. Download Redream")
    print("6. Download PSX2")
    print("7. Download PPSSPP")
    print("8. Download MAME")
    print("9. Download Duckstation")
    print("10. Download BigPEmu")
    print("11. Download RPCS3")
    print("12. Download All")
    print("13. Exit")

def main():
    exit_program = False
    while not exit_program:
        show_menu()
        choice = input("Enter your choice (1-13): ")
        try:
            choice = int(choice)
        except ValueError:
            print("Invalid choice. Please enter a number between 1 and 13.")
            continue

        if choice == 1:
            download_emulator("Vita3K")
        elif choice == 2:
            download_emulator("XENIA")
        elif choice == 3:
            download_emulator("XEMU")
        elif choice == 4:
            download_emulator("Ryujinx")
        elif choice == 5:
            download_emulator("Redream")
        elif choice == 6:
            download_emulator("PSX2")
        elif choice == 7:
            download_emulator("PPSSPP")
        elif choice == 8:
            download_emulator("MAME")
        elif choice == 9:
            download_emulator("Duckstation")
        elif choice == 10:
            download_emulator("BigPEmu")
        elif choice == 11:
            download_emulator("RPCS3")
        elif choice == 12:
            for emulator_name in emulators.keys():
                download_emulator(emulator_name)
        elif choice == 13:
            print("Exiting...")
            exit_program = True
        else:
            print("Invalid choice. Please enter a number between 1 and 13.")

if __name__ == "__main__":
    main()
