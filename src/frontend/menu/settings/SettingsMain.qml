// Pegasus Frontend
// Copyright (C) 2017-2018  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.15
import QtQuick.Window 2.2
import Qt.labs.qmlmodels 1.0


FocusScope {
    id: root

    signal close
    signal openKeySettings
    signal openGamepadSettings
    signal openGameDirSettings
    signal openAndroidSafSettings
    signal openProviderSettings
    signal openSplashLogoSettings
    signal openNetworkEditor
    signal openBluetoothEditor
    signal openSSHEditor
    signal reloadRequested

    width: parent.width
    height: parent.height
    visible: 0 < (x + width) && x < Window.window.width

    enabled: focus

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
    }


    PegasusUtils.HorizontalSwipeArea {
        anchors.fill: parent
        onSwipeRight: root.close()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.close()
    }

    ScreenHeader {
        id: header
        text: qsTr("Settings") + api.tr
        z: 2
    }


    readonly property var tabNames: [qsTr("Pegasus") + api.tr, qsTr("Date & Time") + api.tr, qsTr("Display") + api.tr, qsTr("Network") + api.tr, qsTr("Bluetooth") + api.tr]
    property int currentTab: 0

    Row {
        id: tabBar
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: vpx(4)

        Repeater {
            model: root.tabNames

            Rectangle {
                width: tabLabel.implicitWidth + vpx(40)
                height: vpx(40)
                radius: vpx(6)
                color: index === root.currentTab ? "#3aa" : (tabMouse.containsMouse ? "#444" : "transparent")

                Text {
                    id: tabLabel
                    text: modelData
                    color: index === root.currentTab ? "#fff" : "#bbb"
                    font.pixelSize: vpx(18)
                    font.family: globalFonts.sans
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.currentTab = index
                    cursorShape: Qt.PointingHandCursor
                }

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }


    readonly property list<SettingsEntry> pegasusOptions: [
        SettingsEntry {
            label: QT_TR_NOOP("Language")
            type: SettingsEntry.Type.Select
            selectBox: localeBox
            selectValue: Internal.settings.locales.currentName
            section: "general"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Theme")
            type: SettingsEntry.Type.Select
            selectBox: themeBox
            selectValue: Internal.settings.themes.currentName
            section: "general"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Splash logo...")
            desc: QT_TR_NOOP("Choose a custom image for the startup splash screen. Leave empty for the default.")
            type: SettingsEntry.Type.Button
            buttonAction: root.openSplashLogoSettings
            section: "general"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Fullscreen mode")
            desc: QT_TR_NOOP("On some platforms this setting may have no effect.")
            type: SettingsEntry.Type.Bool
            boolValue: Internal.settings.fullscreen
            boolSetter: (val) => Internal.settings.fullscreen = val
            section: "general"
        },

        SettingsEntry {
            label: QT_TR_NOOP("Change controls...")
            type: SettingsEntry.Type.Button
            buttonAction: root.openKeySettings
            section: "controls"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Change gamepad layout...")
            type: SettingsEntry.Type.Button
            buttonAction: root.openGamepadSettings
            section: "controls"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Ignore mouse pointer")
            desc: QT_TR_NOOP("When enabled, the mouse cursor is hidden and all mouse input is ignored.")
            type: SettingsEntry.Type.Bool
            boolValue: !Internal.settings.mouseSupport
            boolSetter: (val) => Internal.settings.mouseSupport = !val
            section: "controls"
        },

        SettingsEntry {
            label: QT_TR_NOOP("Set game directories...")
            type: SettingsEntry.Type.Button
            buttonAction: root.openGameDirSettings
            section: "gaming"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Accessible Android directories...")
            type: SettingsEntry.Type.Button
            buttonAction: root.openAndroidSafSettings
            section: "gaming"
            enabled: Qt.platform.os === "android"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Validate game files")
            desc: QT_TR_NOOP("Check the game files and only show games that actually exist. You can disable this to improve loading times.")
            type: SettingsEntry.Type.Bool
            boolValue: Internal.settings.verifyFiles
            boolSetter: (val) => Internal.settings.verifyFiles = val
            section: "gaming"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Show missing games")
            desc: QT_TR_NOOP("Show all detected games, including those that may not exist.")
            type: SettingsEntry.Type.Bool
            boolValue: Internal.settings.showMissingGames
            boolSetter: (val) => Internal.settings.showMissingGames = val
            section: "gaming"
            enabled: Internal.settings.verifyFiles
        },
        SettingsEntry {
            label: QT_TR_NOOP("Enable/disable data sources...")
            type: SettingsEntry.Type.Button
            buttonAction: root.openProviderSettings
            section: "gaming"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Reload all games")
            type: SettingsEntry.Type.Button
            buttonAction: root.reloadRequested
            section: "gaming"
        }
    ]

    readonly property list<SettingsEntry> datetimeOptions: [
        SettingsEntry {
            label: QT_TR_NOOP("Time zone")
            type: SettingsEntry.Type.Select
            selectBox: timezoneBox
            selectValue: Internal.settings.timezones.currentTimezone
            section: "datetime"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Network time")
            desc: QT_TR_NOOP("Synchronize the system clock automatically using NTP.")
            type: SettingsEntry.Type.Bool
            boolValue: Internal.settings.networkTime
            boolSetter: (val) => Internal.settings.networkTime = val
            section: "datetime"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Use 24-hour clock")
            type: SettingsEntry.Type.Bool
            boolValue: Internal.settings.use24hrClock
            boolSetter: (val) => Internal.settings.use24hrClock = val
            section: "datetime"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Display seconds")
            type: SettingsEntry.Type.Bool
            boolValue: Internal.settings.showSeconds
            boolSetter: (val) => Internal.settings.showSeconds = val
            section: "datetime"
        }
    ]

    readonly property list<SettingsEntry> displayOptions: [
        SettingsEntry {
            label: QT_TR_NOOP("Resolution")
            type: SettingsEntry.Type.Select
            selectBox: resolutionBox
            selectValue: Internal.settings.displaySettings.resolutions.currentText
            section: "display"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Refresh Rate")
            type: SettingsEntry.Type.Select
            selectBox: refreshRateBox
            selectValue: Internal.settings.displaySettings.refreshRates.currentText
            section: "display"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Rotation")
            type: SettingsEntry.Type.Select
            selectBox: rotationBox
            selectValue: Internal.settings.displaySettings.rotations.currentText
            section: "display"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Scaling")
            desc: QT_TR_NOOP("System-wide display scaling.")
            type: SettingsEntry.Type.Select
            selectBox: scalingBox
            selectValue: Internal.settings.displaySettings.scaling.currentText
            section: "display"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Apply display settings")
            desc: qsTr("Output: ") + Internal.settings.displaySettings.outputName
                + qsTr("  |  Server: ") + Internal.settings.displaySettings.displayServer
            type: SettingsEntry.Type.Button
            buttonAction: function() { Internal.settings.displaySettings.applyAll() }
            section: "display"
        }
    ]

    readonly property list<SettingsEntry> networkOptions: [
        SettingsEntry {
            label: QT_TR_NOOP("WiFi")
            type: SettingsEntry.Type.Bool
            boolValue: Internal.settings.network.wifiEnabled
            boolSetter: (val) => Internal.settings.network.wifiEnabled = val
            section: "network"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Status")
            desc: Internal.settings.network.activeConnection
                ? Internal.settings.network.activeConnection
                  + (Internal.settings.network.ipAddress ? " (" + Internal.settings.network.ipAddress + ")" : "")
                : QT_TR_NOOP("Not connected")
            type: SettingsEntry.Type.Button
            buttonAction: function() {}
            section: "network"
            enabled: false
        },
        SettingsEntry {
            label: QT_TR_NOOP("Manage networks...")
            desc: QT_TR_NOOP("Scan, connect to WiFi, enter passwords with onscreen keyboard.")
            type: SettingsEntry.Type.Button
            buttonAction: root.openNetworkEditor
            section: "network"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Manage SSH server...")
            desc: Internal.settings.ssh.sshInstalled
                ? (Internal.settings.ssh.sshRunning
                    ? QT_TR_NOOP("Running") + " (" + Internal.settings.ssh.ipAddress + ":" + Internal.settings.ssh.sshPort + ")"
                    : QT_TR_NOOP("Not running"))
                : QT_TR_NOOP("Not installed")
            type: SettingsEntry.Type.Button
            buttonAction: root.openSSHEditor
            section: "ssh"
        }
    ]

    readonly property list<SettingsEntry> bluetoothOptions: [
        SettingsEntry {
            label: QT_TR_NOOP("Bluetooth")
            type: SettingsEntry.Type.Bool
            boolValue: Internal.settings.bluetooth.btEnabled
            boolSetter: (val) => Internal.settings.bluetooth.btEnabled = val
            section: "bluetooth"
        },
        SettingsEntry {
            label: QT_TR_NOOP("Manage bluetooth devices...")
            desc: QT_TR_NOOP("Scan, pair, connect to bluetooth devices.")
            type: SettingsEntry.Type.Button
            buttonAction: root.openBluetoothEditor
            section: "bluetooth"
        }
    ]

    readonly property var allTabs: [pegasusOptions, datetimeOptions, displayOptions, networkOptions, bluetoothOptions]
    property var currentOptionList: allTabs[currentTab]

    DelegateChooser {
        id: optionDelegates
        role: "type"

        DelegateChoice {
            roleValue: SettingsEntry.Type.Bool
            ToggleOption {
                label: qsTr(model.label) + api.tr
                desc: qsTr(model.desc) + api.tr
                checked: model.boolValue
                onCheckedChanged: model.boolSetter(checked)
                enabled: model.enabled
            }
        }

        DelegateChoice {
            roleValue: SettingsEntry.Type.Button
            SimpleButton {
                label: qsTr(model.label) + api.tr
                onActivate: model.buttonAction()
                enabled: model.enabled
            }
        }

        DelegateChoice {
            roleValue: SettingsEntry.Type.Select
            MultivalueOption {
                label: qsTr(model.label) + api.tr
                value: model.selectValue
                onActivate: model.selectBox.focus = true
            }
        }
    }

    Component {
        id: sectionTitle
        SectionTitle {
            required property string section

            readonly property string trText: switch (section) {
                case "general": return QT_TR_NOOP("General");
                case "controls": return QT_TR_NOOP("Controls");
                case "gaming": return QT_TR_NOOP("Gaming");
                case "datetime": return QT_TR_NOOP("Date and Time");
                case "display": return QT_TR_NOOP("Display");
                case "network": return QT_TR_NOOP("Network");
                case "bluetooth": return QT_TR_NOOP("Bluetooth");
                case "ssh": return QT_TR_NOOP("SSH");
            }

            text: qsTr(trText) + api.tr
        }
    }

    ListView {
        id: options
        model: root.currentOptionList
        delegate: optionDelegates

        width: root.width * 0.7
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: tabBar.bottom
        anchors.topMargin: vpx(10)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: header.height

        displayMarginBeginning: header.height
        displayMarginEnd: header.height

        focus: true
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 150
        preferredHighlightBegin: height * 0.3
        preferredHighlightEnd: height * 0.7

        section.property: "section"
        section.delegate: sectionTitle

        Keys.onLeftPressed: {
            if (root.currentTab > 0) {
                root.currentTab--;
                currentIndex = 0;
            }
        }
        Keys.onRightPressed: {
            if (root.currentTab < root.allTabs.length - 1) {
                root.currentTab++;
                currentIndex = 0;
            }
        }
    }


    MultivalueBox {
        id: localeBox
        z: 3

        model: Internal.settings.locales
        index: Internal.settings.locales.currentIndex

        onClose: options.focus = true
        onSelect: Internal.settings.locales.currentIndex = index
    }
    MultivalueBox {
        id: themeBox
        z: 3

        model: Internal.settings.themes
        index: Internal.settings.themes.currentIndex

        onClose: options.focus = true
        onSelect: Internal.settings.themes.currentIndex = index
    }
    MultivalueBox {
        id: timezoneBox
        z: 3

        model: Internal.settings.timezones
        index: Internal.settings.timezones.currentIndex

        onClose: options.focus = true
        onSelect: Internal.settings.timezones.currentIndex = index
    }
    MultivalueBox {
        id: resolutionBox
        z: 3

        model: Internal.settings.displaySettings.resolutions
        index: Internal.settings.displaySettings.resolutions.currentIndex

        onClose: options.focus = true
        onSelect: Internal.settings.displaySettings.resolutions.currentIndex = index
    }
    MultivalueBox {
        id: refreshRateBox
        z: 3

        model: Internal.settings.displaySettings.refreshRates
        index: Internal.settings.displaySettings.refreshRates.currentIndex

        onClose: options.focus = true
        onSelect: Internal.settings.displaySettings.refreshRates.currentIndex = index
    }
    MultivalueBox {
        id: rotationBox
        z: 3

        model: Internal.settings.displaySettings.rotations
        index: Internal.settings.displaySettings.rotations.currentIndex

        onClose: options.focus = true
        onSelect: Internal.settings.displaySettings.rotations.currentIndex = index
    }
    MultivalueBox {
        id: scalingBox
        z: 3

        model: Internal.settings.displaySettings.scaling
        index: Internal.settings.displaySettings.scaling.currentIndex

        onClose: options.focus = true
        onSelect: Internal.settings.displaySettings.scaling.currentIndex = index
    }
}
