![screenshot](etc/promo/screenshot_alpha10.jpg)


# Pegasus Frontend (Modified)

A fork of [Pegasus Frontend](https://github.com/mmatyas/pegasus-frontend) with added settings UI and system management features. Coded by an AI assistant ([opencode](https://github.com/anomalyco/opencode)).

[![GPLv3 license](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE.md)

- [**Main website**](http://pegasus-frontend.org)
- [Documentation](https://pegasus-frontend.org/docs/)
- [Upstream project](https://github.com/mmatyas/pegasus-frontend)


## Custom Settings UI

This fork adds a built-in settings screen with the following tabs:

**Pegasus**
- Custom splash logo (file browser picker)

**Date & Time**
- Timezone selection
- Network time sync toggle
- 24-hour clock toggle
- Display seconds toggle

**Display**
- Resolution, refresh rate, rotation, and scaling dropdowns
- Apply button with resolution preview

**Network**
- WiFi toggle with scan/disconnect
- Network list with connect (password entry via onscreen keyboard)
- SSH server management (install OpenSSH, view connection info, manage keys)

**Bluetooth**
- Bluetooth toggle with scan
- Device list with pair/connect/disconnect actions

## Additional Features

- **Ignore mouse pointer** option (renamed from "Enable mouse support" with inverted logic)
- **Custom onscreen keyboard** with QWERTY and symbols modes, full gamepad navigation (D-pad, A, B, Enter, Cancel), and password dot masking
- **Gamepad navigation** throughout all settings screens
- **Disconnect Controllers** from the main menu (disconnects all Bluetooth controllers; wired controllers unaffected)
- **Kiosk mode** (`--kiosk`) and individual `--disable-menu-*` flags to hide menu entries
- **Bluetooth backend** using `bluetoothctl`
- **SSH backend** using `ssh-keygen`, `pgrep`, and `sudo -A` with askpass helper
- **Display management** supporting both X11 (`xrandr`) and Wayland (`wlr-randr`/`gnome-randr`)


## Building from source

**Build dependencies**

- C++11 compatible compiler
- Qt 5.15.0 or later, with the following modules:
    - QML and QtQuick2
    - Multimedia
    - SVG
    - SQL (SQLite v3)
- Either SDL (2.0.4 or later) or Qt Gamepad
- Additional: `qml-module-qt-labs-qmlmodels`, `libqt5gamepad5-dev`, `qttools5-dev-tools`

**Building**

```sh
mkdir build && cd build
qmake ..
make -j$(nproc)
```

Run with:
```sh
./src/app/pegasus-fe
```


## License

Pegasus Frontend is available under GPLv3 license. See [LICENSE](LICENSE.md) for details.
