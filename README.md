# VehControl 🚗

> Modern vehicle control UI for FiveM - Compatible with **ESX** & **QBCore**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![FiveM](https://img.shields.io/badge/platform-FiveM-orange.svg)](https://fivem.net)
[![ESX](https://img.shields.io/badge/ESX-compatible-green.svg)](https://github.com/esx-framework)
[![QBCore](https://img.shields.io/badge/QBCore-compatible-blue.svg)](https://github.com/qbcore-framework)

---

## Features

- 🎨 **Modern Glassmorphism UI** - Beautiful, animated interface with customizable colors
- 🎥 **Interactive Camera System** - Camera focuses on different vehicle parts when interacting
- 🚪 **Door Control** - Open/close all vehicle doors (driver, passenger, rear, hood, trunk)
- 💡 **Light Controls** - Toggle headlights, high beams, hazards, and indicators
- 🪟 **Window Controls** - Roll up/down individual windows
- 🔧 **Tire Status** - Visual tire health indicators
- ⌨️ **Keybind Support** - Default keybind `F7` (configurable)
- 🎯 **Framework Auto-Detection** - Works seamlessly with ESX, QBCore, or standalone

---

## 📦 Installation

### 1. Download & Extract

```bash
cd your-fivem-server/resources
git clone https://github.com/yourusername/sync_VehControl.git
```

Or download the ZIP and extract to your `resources` folder.

### 2. Install Dependencies

Ensure you have the following resources installed:

- [ox_lib](https://github.com/overextended/ox_lib) (Required)

### 3. Server Configuration

Add to your `server.cfg`:

```cfg
ensure ox_lib
ensure sync_VehControl
```

**Note:** The script auto-detects your framework (ESX or QBCore) - no additional configuration needed!

---

##  Configuration

Edit `configs/main.lua` to customize the UI:

```lua
Config = {
    UI = {
        MainColor = 'C9FF34',        -- Accent color (hex)
        Backdrop = 'rgba(0, 0, 0, 0.28)',  -- Background transparency
        Width = 380,                 -- UI width in pixels
        RightOffset = 70,            -- Distance from right edge
        MaxHeightVh = 46,            -- Maximum height (% of screen)
        TiltX = 10,                  -- 3D tilt effect X
        TiltY = -10,                 -- 3D tilt effect Y
        AnimInMs = 200,              -- Open animation duration
        AnimOutMs = 180,             -- Close animation duration
        SlidePx = 26,                -- Slide animation distance
    }
}
```

---

##  Usage

| Key | Action |
|-----|--------|
| `F7` | Open/Close Vehicle Control UI |

While in the UI:
- **Hover** over controls to see camera focus on that vehicle part
- **Click** to toggle doors, windows, lights, and indicators
- Click outside or press `ESC` to close

---

##  Preview
<img width="1171" height="1045" alt="image" src="https://github.com/user-attachments/assets/2d233f0d-56cf-433a-8d60-c439f4e1e899" />


---

##  Framework Compatibility

| Framework | Status | Notes |
|-----------|--------|-------|
| ESX Legacy | ✅ Supported | Auto-detected |
| ESX 1.9+ | ✅ Supported | Uses new exports |
| QBCore | ✅ Supported | Auto-detected |
| Standalone | ⚠️ Partial | Requires ox_lib |

---

##  File Structure

```
sync_VehControl/
├── client/
│   ├── main.lua         # Main client logic & NUI
│   └── functions.lua    # Utility functions
├── configs/
│   └── main.lua         # Configuration file
├── html/                # Built UI files
│   ├── index.html
│   └── assets/
├── fxmanifest.lua       # Resource manifest
├── LICENSE
└── README.md
```

---

##  Troubleshooting

### UI Not Opening?
- Ensure you're in a vehicle
- Check that `ox_lib` is started before this resource
- Verify the resource name hasn't been changed (affects NUI)

### Framework Not Detected?
- Make sure your framework (ESX/QBCore) is properly installed
- Check server console for errors during startup

---

##  License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Credits

- **Sync Scripts** - Original development
- [ox_lib](https://github.com/overextended/ox_lib) - UI notifications
- FiveM & CFX Collective - Platform support

---

<p align="center">Made with ❤️ by Sync Scripts</p>
