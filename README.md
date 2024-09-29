# Welcome to the Emulator Auto-Download Project! #

This project is designed to help retro gamers easily download the latest Windows versions of the top emulators in one convenient place.

Supported Emulators:

- AppleWin
- BigPEmu
- CEMU
- Dolphin
- Duckstation
- Lime3DS
- MAME
- PCSX2
- PPSSPP
- Redream
- RPCS3
- Ryujinx
- Vita3K
- XEMU
- XENIA

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

> **Note**: If you want to change the download folder later, you can edit the `emd.ini` file in any text editor. Just update the `emupath` setting with the new location.

## Future Features (Coming Soon):

- Ability to download emulators for **Windows**, **Mac**, or **Linux**.
- Support for more emulators, including **RetroArch**, **Supermodel**, **Cxbx**, **ShadPS4**, **fpPS4**, **Project64**, and more!
- Improvements to the user interface.
- Digital signatures for the script to enhance security.

---

**Disclaimer**: All trademarks are the property of their respective owners.

---
