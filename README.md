![GitHub release (latest by date)](https://img.shields.io/github/v/release/dbalcar/Emulator-Auto-downloads)
![GitHub All Releases](https://img.shields.io/github/downloads/dbalcar/Emulator-Auto-downloads/total)
![GitHub issues](https://img.shields.io/github/issues/dbalcar/Emulator-Auto-downloads)


# Welcome to the Emulator Auto-Download Project! #

Emulator Auto-Downloads is a passion project designed to save time by automating the download of the latest versions of popular gaming emulators. Powered by PowerShell, this script eliminates the hassle of manually finding and updating emulators, letting users focus on their favorite retro and modern games. Whether you're setting up a new system or maintaining an existing one, this tool makes managing a wide range of emulators—from retro classics to modern consoles—effortless.

## Currently Supported Emulators: ##

| **Emulator**           | **System**          | --- | **Emulator**            | **System**   |
|------------------------|---------------------|-----|-------------------------|--------------|
| **a7800**               | Atari 7800          |     | **Redream**              | Dreamcast    |
| **AppleWin**            | Apple ][            |     | **RetroArch**            | Frontend     |
| **BigPEmu**             | Atari Jaguar        |     | **Rosalie's Mupen GUI**  | Nintendo 64  |
| **CEMU**                | Wii U               |     | **RPCS3**                | PS3          |
| **Dolphin**             | Wii / GameCube      |     | **Snes9x**               | SNES         |
| **Duckstation**         | PS1                 |     | **Stella**               | Atari 2600   |
| **Lime3DS**             | DS                  |     | **Sudachi**              | Multi-system |
| **MAME**                | Arcade              |     | **Supermodel**           | Sega Model 3 |
| **Mednafen**            | Multi-system        |     | **TeknoParrot**          | Arcade       |
| **melonDS**             | DS                  |     | **VisualBoyAdvance-m**   | Game Boy Advance |
| **mGBA**                | Game Boy Advance    |     | **VICE**                 | Commodore 64 |
| **PCSX2**               | PS2                 |     | **Vita3K**               | Vita         |
| **PPSSPP**              | PSP                 |     | **WinUAE**               | Amiga        |
| **Project64**           | Nintendo 64         |     | **XEMU**                 | Xbox         |
| **shadPS4**             | PS4                 |     | **XENIA**                | Xbox360      |
|                        |                     |     | **Xenia Manager**        | Xbox360      |


If your favorite emulator isn’t listed, you can request it by posting in [Discussions](https://github.com/dbalcar/Emulator-Auto-downloads/discussions)


# Announcement 🚀 #

We’re thrilled to announce the release of **Emulator Auto-Download v3.0!** This major update adds support for downloading Windows, Mac, and Linux versions of over 30 emulators, along with a completely rewritten menu system and extensive backend improvements.

For easy execution on Windows 10/11 systems, a compiled EXE using PS2EXE is now included.

## Requirements:

- A Windows 10 or 11 PC
- PowerShell version 5 or higher (PowerShell is already installed on most Windows PCs)

## Easy Installation Steps:

1. **Download the Latest Version**
   - Visit the project’s release page and download the latest version.

2. **Run the EAD-3.exe file**

   - On the first run, you will be asked you where you’d like to download the emulators. Choose a folder on your computer where you want to keep them.

3. **Select which OS versions of the Emulators to download**

      <img width="347" alt="OS selection page" src="https://github.com/user-attachments/assets/c3366c66-e311-4692-9cec-8a2196d02631">

4. **Select Emulators**
   - After that, you will be shown a list of emulators. You can pick the ones you want or download all of them at once.

      <img width="374" alt="Emulator selection page" src="https://github.com/user-attachments/assets/7cef2bc7-559b-4e6b-bc1b-3018c3bb2f9e">
     



> [!NOTE]
> If you want to change the download folder later, you can edit the `emd.ini` file in any text editor. Just update the `emupath` setting with the new location.

## *Optional: If you you would like to run the PowerShell script instead of the exe*

1. **Run the batch file**
   - In a cmd window, type the following command and press **Enter**:
     ```bash
     EAD-3.bat
     ```
     **The emu-updater.bat need to be in the same directory as the script.**
     
   - On the first run, the script will ask you where you’d like to download the emulators. Choose a folder on your computer where you want to keep them.

4. **Select Emulators**
   - After that, the script will show you a list of emulators. You can pick the ones you want or download all of them at once.

> [!NOTE]
> If you want to change the download folder later, you can edit the `emd.ini` file in any text editor. Just update the `emupath` setting with the new location.

 
 




## Future Features (Coming Soon):

- Support for more emulators, including **Cxbx**, **fpPS4** and more!
- Improvements to the user interface.
- Digital signatures for the script to enhance security.

---



---
**Disclaimer**: All emulator names, trademarks and software are the property of their respective owners. This script is provided as-is without any warranty or guarantee of functionality.

    The author of this script is not affiliated with any the emulator projects or any emulator developers. This script is for personal 
    use only to automate the process of downloading files from public sources.
---




