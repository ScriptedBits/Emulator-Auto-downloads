![GitHub release (latest by date)](https://img.shields.io/github/v/release/dbalcar/Emulator-Auto-downloads)
![GitHub All Releases](https://img.shields.io/github/downloads/dbalcar/Emulator-Auto-downloads/total)
![GitHub issues](https://img.shields.io/github/issues/dbalcar/Emulator-Auto-downloads)


# Welcome to the Emulator Auto-Download Project! #

This project is designed to help retro gamers easily download the latest Windows versions of the top emulators in one convenient place.

## Currently Supported Emulators: ##

| **Emulators**            | **Systems**            | **Emulators**               | **Systems**            |
|--------------------------|------------------------|-----------------------------|------------------------|
| AppleWin                 | Apple II               | PCSX2                       | PlayStation 2          |
| BigPEmu                  | Atari Jaguar           | Redream                     | Dreamcast              |
| CEMU                     | Wii U                  | RetroArch                   | Multi-System           |
| Dolphin                  | GameCube/Wii           | RPCS3                       | PlayStation 3          |
| Duckstation              | PlayStation 1          | shadps4                     | PlayStation 4          |
| Lime3DS                  | Nintendo 3DS           | TeknoParrot (Web installer) | Arcade                 |
| MAME                     | Multiple Arcade        | Vita3K                      | PlayStation Vita       |
| melonDS                  | Nintendo DS            | VICE                        | Commodore 64           |
| mupen64plus              | Nintendo 64            | WinUAE                      | Amiga                  |
| Rosalie's Mupen GUI      | Nintendo 64            | XEMU                        | Xbox                   |
| Stella                   | Atari 2600             | XENIA                       | Xbox 360               |
| Supermodel               | Sega Model 3           | Xenia Manager               | Xbox 360               |
| mGBA                     | Game Boy Advance       |                             |                        |


If your favorite emulator isn’t listed, you can request it by posting in [Discussions](https://github.com/dbalcar/Emulator-Auto-downloads/discussions)


## Requirements:

- A Windows 10 or 11 PC
- PowerShell version 5 or higher (PowerShell is already installed on most Windows PCs)

## Easy Installation Steps:

1. **Download the Latest Version**
   - Visit the project’s release page and download the latest version of the script.
   
2. **Locate PowerShell**
   - Right-click on the **Start Menu** (bottom-left corner of your screen).
   - Select **Windows PowerShell (Admin)** to open PowerShell with administrator rights. You’ll need this for the script to work.

3. **Run the Script**
   - In the PowerShell window, type the following command and press **Enter**:
     ```bash
     powershell -ExecutionPolicy Bypass -File .\emu-updater.ps1
     ```
   - On the first run, the script will ask you where you’d like to download the emulators. Choose a folder on your computer where you want to keep them.

4. **Select Emulators**
   - After that, the script will show you a list of emulators. You can pick the ones you want or download all of them at once.

> [!NOTE]
> If you want to change the download folder later, you can edit the `emd.ini` file in any text editor. Just update the `emupath` setting with the new location.

## Future Features (Coming Soon):

- Ability to download emulators for **Windows**, **Mac**, or **Linux**.
- Support for more emulators, including **Cxbx**, **fpPS4**, **Project64**, and more!
- Improvements to the user interface.
- Digital signatures for the script to enhance security.

---

<img width="500" alt="ead main screen" src="https://github.com/user-attachments/assets/86ef04d3-9f2b-4bb8-ba37-e677ada5fe1f">

---
**Disclaimer**: All emulator names, trademarks and software are the property of their respective owners. This script is provided as-is without any warranty or guarantee of functionality.

    The author of this script is not affiliated with any the emulator
    projects or any emulator developers. This script is for personal 
    use only to automate the process of downloading files from public 
    sources.
---




