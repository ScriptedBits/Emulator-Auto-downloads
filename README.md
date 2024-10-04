![GitHub release (latest by date)](https://img.shields.io/github/v/release/dbalcar/Emulator-Auto-downloads)
![GitHub All Releases](https://img.shields.io/github/downloads/dbalcar/Emulator-Auto-downloads/total)


# Welcome to the Emulator Auto-Download Project! #

This project is designed to help retro gamers easily download the latest Windows versions of the top emulators in one convenient place.

## Supported Emulators: ##

| **Emulator**   | **System**          |     |      **Emulator**               | **System**   |
|----------------|---------------------|-----|---------------------------------|--------------|
| **AppleWin**       | Apple ][             |     | **PPSSPP**                 | PSP          |
| **BigPEmu**        | Atari Jaguar         |     | **Redream**                | Dreamcast    |
| **CEMU**           | Wii U                |     | **RetroArch**              | Frontend     |
| **Dolphin**        | Wii / GameCube       |     | **Rosalie's Mupen GUI**    | N64          |
| **Duckstation**    | PS!                  |     | **RPCS3**                  | PS3          |
| **Lime3DS**        | DS                   |     | **shadps4**                | PS4          |
| **MAME**           | Arcade               |     | **VICE**                   | C64          |
| **melonDS**        | DS                   |     | **Vita3K**                 | Vita         |
| **mupen64plus**    | N64                  |     | **WinUAE**                 | Amiga        |
| **PCSX2**          | PS2                  |     | **XEMU**                   | Xbox         |
|                    |                      |     | **XENIA**                  | Xbox360      |
|                    |                      |     |                            |              |



If your favorite emulator isn’t listed, you can request it by leaving a comment.

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
- Support for more emulators, including **RetroArch**, **Supermodel**, **Cxbx**, **ShadPS4**, **fpPS4**, **Project64**, and more!
- Improvements to the user interface.
- Digital signatures for the script to enhance security.

---

**Disclaimer**: All emulator names, trademarks and software are the property of their respective owners. This script is provided as-is without any warranty or guarantee of functionality.

    The author of this script is not affiliated with any the emulator
    projects or any emulator developers. This script is for personal 
    use only to automate the process of downloading files from public 
    sources.
---

<img width="513" alt="ead main screen" src="https://github.com/user-attachments/assets/fd163bb6-2302-43fb-81ba-f07227a7aae2">


