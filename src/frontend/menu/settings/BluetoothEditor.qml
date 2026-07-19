import "common"
import QtQuick 2.15
import QtQuick.Window 2.2


FocusScope {
    id: root

    signal close

    anchors.fill: parent

    onVisibleChanged: {
        if (visible) deviceList.forceActiveFocus();
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
    }

    ScreenHeader {
        id: header
        text: qsTr("Bluetooth") + api.tr
        z: 2
    }

    // Bluetooth toggle row
    FocusScope {
        id: btToggleRow
        anchors.top: header.bottom
        anchors.topMargin: vpx(50)
        anchors.horizontalCenter: parent.horizontalCenter
        width: btLabel.implicitWidth + vpx(52) + vpx(12)
        height: vpx(28)

        property bool toggled: Internal.settings.bluetooth.btEnabled

        Row {
            anchors.centerIn: parent
            spacing: vpx(12)

            Text {
                id: btLabel
                text: qsTr("Bluetooth") + api.tr
                color: "#eee"
                font.pixelSize: vpx(18)
                font.family: globalFonts.sans
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: vpx(52)
                height: vpx(28)
                radius: vpx(14)
                color: btToggleRow.toggled ? "#3aa" : "#555"
                border.color: btToggleRow.activeFocus ? "#5ee" : (btToggleRow.toggled ? "#5ee" : "#777")
                border.width: vpx(1)

                Rectangle {
                    x: btToggleRow.toggled ? parent.width - width - vpx(2) : vpx(2)
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(22)
                    height: vpx(22)
                    radius: vpx(11)
                    color: "#fff"

                    Behavior on x { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Internal.settings.bluetooth.btEnabled = !Internal.settings.bluetooth.btEnabled
                }
            }
        }

        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            if (api.keys.isAccept(event)) {
                event.accepted = true;
                Internal.settings.bluetooth.btEnabled = !Internal.settings.bluetooth.btEnabled;
            } else if (api.keys.isDown(event)) {
                event.accepted = true;
                actionRow.forceActiveFocus();
            }
        }
    }

    // Action buttons
    FocusScope {
        id: actionRow
        anchors.top: btToggleRow.bottom
        anchors.topMargin: vpx(12)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: vpx(20)
        anchors.rightMargin: vpx(20)
        height: vpx(36)
        visible: Internal.settings.bluetooth.btEnabled

        property int actionIndex: 0

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: vpx(12)

            Rectangle {
                width: scanLabel.implicitWidth + vpx(40)
                height: vpx(36)
                radius: vpx(6)
                color: actionRow.activeFocus && actionRow.actionIndex === 0 ? "#3aa" : (scanMA.containsMouse ? "#4aa" : "#333")
                border.color: actionRow.activeFocus && actionRow.actionIndex === 0 ? "#5ee" : "transparent"
                border.width: vpx(2)

                Text {
                    id: scanLabel
                    text: qsTr("Scan") + api.tr
                    color: "#ccc"
                    font.pixelSize: vpx(14)
                    font.family: globalFonts.sans
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: scanMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Internal.settings.bluetooth.scan()
                }
            }
        }

        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            if (api.keys.isAccept(event)) {
                event.accepted = true;
                Internal.settings.bluetooth.scan();
            } else if (api.keys.isDown(event)) {
                event.accepted = true;
                deviceList.forceActiveFocus();
            } else if (api.keys.isUp(event)) {
                event.accepted = true;
                btToggleRow.forceActiveFocus();
            }
        }
    }

    // Status
    Text {
        id: statusText
        anchors.top: actionRow.visible ? actionRow.bottom : btToggleRow.bottom
        anchors.topMargin: vpx(10)
        anchors.horizontalCenter: parent.horizontalCenter
        text: Internal.settings.bluetooth.btEnabled
            ? qsTr("%1 devices found").arg(Internal.settings.bluetooth.deviceCount()) + api.tr
            : qsTr("Bluetooth is off") + api.tr
        color: "#888"
        font.pixelSize: vpx(13)
        font.family: globalFonts.sans
        visible: true
    }

    // Device list
    ListView {
        id: deviceList
        anchors.top: statusText.bottom
        anchors.topMargin: vpx(8)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: header.height
        clip: true
        focus: true
        visible: Internal.settings.bluetooth.btEnabled

        model: Internal.settings.bluetooth.deviceCount()

        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: height * 0.2
        preferredHighlightEnd: height * 0.8
        highlightMoveDuration: 150

        KeyNavigation.up: actionRow
        KeyNavigation.down: actionRow

        highlight: Rectangle {
            color: "transparent"
            border.color: "#3aa"
            border.width: vpx(2)
            radius: vpx(4)
        }

        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            var idx = deviceList.currentIndex;
            if (idx < 0) return;
            var mac = Internal.settings.bluetooth.deviceMac(idx);
            var paired = Internal.settings.bluetooth.devicePaired(idx);
            var connected = Internal.settings.bluetooth.deviceConnected(idx);

            if (api.keys.isAccept(event)) {
                event.accepted = true;
                if (connected) {
                    Internal.settings.bluetooth.disconnectDevice(mac);
                } else if (paired) {
                    Internal.settings.bluetooth.connectDevice(mac);
                } else {
                    Internal.settings.bluetooth.pair(mac);
                }
            }
        }

        delegate: Rectangle {
            width: deviceList.width
            height: vpx(56)
            color: ListView.isCurrentItem ? "#2a4a4a" : (deviceMouse.containsMouse ? "#2a2a3e" : "transparent")

            property bool isCurrent: ListView.isCurrentItem

            Row {
                anchors.fill: parent
                anchors.leftMargin: vpx(20)
                anchors.rightMargin: vpx(20)
                spacing: vpx(12)

                // BT icon
                Text {
                    text: {
                        var conn = Internal.settings.bluetooth.deviceConnected(index);
                        var par = Internal.settings.bluetooth.devicePaired(index);
                        if (conn) return "\u25C9"; // connected circle
                        if (par) return "\u25CB"; // paired circle
                        return "\u25CB"; // available
                    }
                    color: {
                        if (Internal.settings.bluetooth.deviceConnected(index)) return "#3aa";
                        if (Internal.settings.bluetooth.devicePaired(index)) return "#888";
                        return "#555";
                    }
                    font.pixelSize: vpx(22)
                    font.family: globalFonts.sans
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(2)

                    Text {
                        text: Internal.settings.bluetooth.deviceName(index)
                        color: "#eee"
                        font.pixelSize: vpx(16)
                        font.family: globalFonts.sans
                        elide: Text.ElideRight
                        width: deviceList.width - vpx(120)
                    }

                    Row {
                        spacing: vpx(8)
                        Text {
                            text: Internal.settings.bluetooth.deviceMac(index)
                            color: "#666"
                            font.pixelSize: vpx(11)
                            font.family: globalFonts.sans
                        }
                        Text {
                            text: {
                                var conn = Internal.settings.bluetooth.deviceConnected(index);
                                var par = Internal.settings.bluetooth.devicePaired(index);
                                if (conn) return qsTr("Connected") + api.tr;
                                if (par) return qsTr("Paired") + api.tr;
                                return qsTr("Available") + api.tr;
                            }
                            color: {
                                if (Internal.settings.bluetooth.deviceConnected(index)) return "#3aa";
                                if (Internal.settings.bluetooth.devicePaired(index)) return "#888";
                                return "#555";
                            }
                            font.pixelSize: vpx(11)
                            font.family: globalFonts.sans
                        }
                    }
                }

                // Action hint
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (Internal.settings.bluetooth.deviceConnected(index)) return qsTr("A: Disconnect") + api.tr;
                        if (Internal.settings.bluetooth.devicePaired(index)) return qsTr("A: Connect") + api.tr;
                        return qsTr("A: Pair") + api.tr;
                    }
                    color: isCurrent ? "#3aa" : "#555"
                    font.pixelSize: vpx(12)
                    font.family: globalFonts.sans
                }
            }

            MouseArea {
                id: deviceMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    deviceList.currentIndex = index;
                    var mac = Internal.settings.bluetooth.deviceMac(index);
                    var paired = Internal.settings.bluetooth.devicePaired(index);
                    var connected = Internal.settings.bluetooth.deviceConnected(index);
                    if (connected) {
                        Internal.settings.bluetooth.disconnectDevice(mac);
                    } else if (paired) {
                        Internal.settings.bluetooth.connectDevice(mac);
                    } else {
                        Internal.settings.bluetooth.pair(mac);
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#333"
            }
        }
    }

    // Connection result feedback
    Connections {
        target: Internal.settings.bluetooth
        function onDeviceAction(message) {
            feedbackText.text = message;
            feedback.visible = true;
            feedbackTimer.restart();
        }
    }

    Rectangle {
        id: feedback
        visible: false
        anchors.bottom: header.bottom
        anchors.bottomMargin: vpx(60)
        anchors.horizontalCenter: parent.horizontalCenter
        width: feedbackText.implicitWidth + vpx(40)
        height: vpx(36)
        radius: vpx(6)
        color: "#333"
        z: 15

        Text {
            id: feedbackText
            text: ""
            color: "#eee"
            font.pixelSize: vpx(14)
            font.family: globalFonts.sans
            anchors.centerIn: parent
        }

        Timer {
            id: feedbackTimer
            interval: 3000
            onTriggered: feedback.visible = false
        }
    }
}
