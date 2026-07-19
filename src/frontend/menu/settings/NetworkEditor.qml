import "common"
import "qrc:/qmlutils" as PegasusUtils
import QtQuick 2.15
import QtQuick.Window 2.2


FocusScope {
    id: root

    signal close

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

    Component.onCompleted: networkList.forceActiveFocus()

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
        text: qsTr("Network") + api.tr
        z: 2
    }

    // Status bar
    Rectangle {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: vpx(40)
        color: "#1a1a2e"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: vpx(20)
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!Internal.settings.network.wifiEnabled) return qsTr("WiFi is turned off") + api.tr;
                if (Internal.settings.network.activeConnection)
                    return qsTr("Connected: ") + Internal.settings.network.activeConnection
                         + (Internal.settings.network.ipAddress ? " (" + Internal.settings.network.ipAddress + ")" : "");
                return qsTr("Not connected") + api.tr;
            }
            color: "#ccc"
            font.pixelSize: vpx(15)
            font.family: globalFonts.sans
        }

        // Signal indicator
        Row {
            anchors.right: parent.right
            anchors.rightMargin: vpx(20)
            anchors.verticalCenter: parent.verticalCenter
            spacing: vpx(3)
            visible: Internal.settings.network.wifiEnabled

            Repeater {
                model: 4
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: vpx(6)
                    height: vpx(8 + index * 5)
                    radius: vpx(2)
                    color: index < 3 ? "#3aa" : "#444"
                }
            }
        }
    }

    // WiFi toggle row
    FocusScope {
        id: wifiToggleRow
        anchors.top: header.bottom
        anchors.topMargin: vpx(50)
        anchors.horizontalCenter: parent.horizontalCenter
        width: wifiLabel.implicitWidth + vpx(52) + vpx(12)
        height: vpx(28)
        visible: true

        property bool toggled: Internal.settings.network.wifiEnabled

        Row {
            anchors.centerIn: parent
            spacing: vpx(12)

            Text {
                id: wifiLabel
                text: qsTr("WiFi") + api.tr
                color: "#eee"
                font.pixelSize: vpx(18)
                font.family: globalFonts.sans
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: vpx(52)
                height: vpx(28)
                radius: vpx(14)
                color: wifiToggleRow.toggled ? "#3aa" : "#555"
                border.color: wifiToggleRow.activeFocus ? "#5ee" : (wifiToggleRow.toggled ? "#5ee" : "#777")
                border.width: vpx(1)

                Rectangle {
                    x: wifiToggleRow.toggled ? parent.width - width - vpx(2) : vpx(2)
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
                    onClicked: Internal.settings.network.wifiEnabled = !Internal.settings.network.wifiEnabled
                }
            }
        }

        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            if (api.keys.isAccept(event)) {
                event.accepted = true;
                Internal.settings.network.wifiEnabled = !Internal.settings.network.wifiEnabled;
            } else if (api.keys.isDown(event)) {
                event.accepted = true;
                if (actionRow.visible) actionRow.forceActiveFocus();
                else networkList.forceActiveFocus();
            }
        }
    }

    // Scan button
    FocusScope {
        id: actionRow
        anchors.top: wifiToggleRow.bottom
        anchors.topMargin: vpx(12)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: vpx(20)
        anchors.rightMargin: vpx(20)
        height: vpx(36)
        visible: Internal.settings.network.wifiEnabled

        property int actionCount: (scanBtnAction.visible ? 1 : 0) + (disconnectBtnAction.visible ? 1 : 0)
        property int actionIndex: 0

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: vpx(12)

            Rectangle {
                id: scanBtnAction
                width: scanLabel.implicitWidth + vpx(40)
                height: vpx(36)
                radius: vpx(6)
                color: actionRow.activeFocus && actionRow.actionIndex === 0 ? "#3aa" : (scanMA.containsMouse ? "#4aa" : "#333")
                border.color: actionRow.activeFocus && actionRow.actionIndex === 0 ? "#5ee" : "transparent"
                border.width: vpx(2)
                visible: true

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
                    onClicked: Internal.settings.network.scan()
                }
            }

            Rectangle {
                id: disconnectBtnAction
                width: disconnectLabel.implicitWidth + vpx(40)
                height: vpx(36)
                radius: vpx(6)
                color: actionRow.activeFocus && actionRow.actionIndex === 1 ? "#a44" : (disconnectMA.containsMouse ? "#a44" : "#333")
                border.color: actionRow.activeFocus && actionRow.actionIndex === 1 ? "#f66" : "transparent"
                border.width: vpx(2)
                visible: Internal.settings.network.activeConnection !== ""

                Text {
                    id: disconnectLabel
                    text: qsTr("Disconnect") + api.tr
                    color: "#ccc"
                    font.pixelSize: vpx(14)
                    font.family: globalFonts.sans
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: disconnectMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Internal.settings.network.disconnectCurrent()
                }
            }
        }

        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            if (api.keys.isLeft(event)) {
                event.accepted = true;
                if (actionRow.actionIndex > 0) actionRow.actionIndex--;
            } else if (api.keys.isRight(event)) {
                event.accepted = true;
                if (actionRow.actionIndex < actionRow.actionCount - 1) actionRow.actionIndex++;
            } else if (api.keys.isAccept(event)) {
                event.accepted = true;
                if (actionRow.actionIndex === 0) Internal.settings.network.scan();
                else if (actionRow.actionIndex === 1) Internal.settings.network.disconnectCurrent();
            } else if (api.keys.isDown(event)) {
                event.accepted = true;
                networkList.forceActiveFocus();
            } else if (api.keys.isUp(event)) {
                event.accepted = true;
                Internal.settings.network.wifiEnabled = !Internal.settings.network.wifiEnabled;
            }
        }
    }

    // Network list
    ListView {
        id: networkList
        anchors.top: actionRow.visible ? actionRow.bottom : wifiToggleRow.bottom
        anchors.topMargin: vpx(16)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: header.height
        clip: true
        focus: true
        visible: Internal.settings.network.wifiEnabled

        model: Internal.settings.network.networkCount()

        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: height * 0.2
        preferredHighlightEnd: height * 0.8
        highlightMoveDuration: 150

        KeyNavigation.up: actionRow.visible ? actionRow : wifiToggleRow
        KeyNavigation.down: wifiToggleRow

        Keys.onPressed: {
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                var idx = networkList.currentIndex;
                if (idx < 0) return;
                var ssid = Internal.settings.network.networkSsid(idx);
                if (!ssid) return;
                if (Internal.settings.network.networkSecured(idx)) {
                    pendingSsid = ssid;
                    keyboard.title = ssid;
                    keyboard.open("");
                    keyboard.passwordMode = true;
                    keyboard.visible = true;
                } else {
                    Internal.settings.network.connectToNetwork(ssid, "");
                }
            }
        }

        delegate: Rectangle {
            width: networkList.width
            height: vpx(56)
            color: ListView.isCurrentItem ? "#2a4a4a" : (networkMouse.containsMouse ? "#2a2a3e" : (isConnected ? "#1a2a2a" : "transparent"))
            border.color: ListView.isCurrentItem ? "#3aa" : "transparent"
            border.width: ListView.isCurrentItem ? vpx(1) : 0

            property bool isConnected: Internal.settings.network.activeConnection === Internal.settings.network.networkSsid(index)
            property int sig: Internal.settings.network.networkSignal(index)
            property bool secured: Internal.settings.network.networkSecured(index)

            Row {
                anchors.fill: parent
                anchors.leftMargin: vpx(30)
                anchors.rightMargin: vpx(30)
                spacing: vpx(12)

                // Lock icon
                Text {
                    text: secured ? "\uD83D\uDD12" : ""
                    font.pixelSize: vpx(16)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // SSID
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - sigBar.width - vpx(30)

                    Text {
                        text: Internal.settings.network.networkSsid(index)
                        color: isConnected ? "#5ee" : "#eee"
                        font.pixelSize: vpx(16)
                        font.family: globalFonts.sans
                        font.bold: isConnected
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: Internal.settings.network.networkSecurity(index)
                        color: "#888"
                        font.pixelSize: vpx(11)
                        font.family: globalFonts.sans
                        visible: Internal.settings.network.networkSecurity(index) !== ""
                    }
                }

                // Signal bars
                Row {
                    id: sigBar
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(2)

                    Repeater {
                        model: 4
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: vpx(5)
                            height: vpx(6 + index * 4)
                            radius: vpx(1)
                            color: (sig > (index + 1) * 25) ? "#3aa" : "#444"
                        }
                    }
                }
            }

            MouseArea {
                id: networkMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (isConnected) return;
                    if (secured) {
                        var name = Internal.settings.network.networkSsid(index);
                        pendingSsid = name;
                        keyboard.title = name;
                        keyboard.open("");
                        keyboard.passwordMode = true;
                        keyboard.visible = true;
                    } else {
                        Internal.settings.network.connectToNetwork(
                            Internal.settings.network.networkSsid(index), "");
                    }
                }
            }

            // Separator
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#333"
            }
        }
    }

    // Onscreen keyboard
    property string pendingSsid: ""

    OnScreenKeyboard {
        id: keyboard
        anchors.fill: parent
        z: 20
        visible: false

        onAccepted: {
            keyboard.visible = false;
            Internal.settings.network.connectToNetwork(pendingSsid, text);
            pendingSsid = "";
            keyboard.title = "";
            networkList.forceActiveFocus();
        }
        onCancelled: {
            keyboard.visible = false;
            pendingSsid = "";
            keyboard.title = "";
            networkList.forceActiveFocus();
        }
    }

    // Connection result feedback
    Connections {
        target: Internal.settings.network
        function onConnectionResult(success, message) {
            if (!success) {
                connFeedback.text = message;
                connFeedback.visible = true;
                feedbackTimer.restart();
            }
        }
    }

    Rectangle {
        id: connFeedback
        visible: false
        anchors.bottom: header.bottom
        anchors.bottomMargin: vpx(60)
        anchors.horizontalCenter: parent.horizontalCenter
        width: feedbackText.implicitWidth + vpx(40)
        height: vpx(36)
        radius: vpx(6)
        color: "#a33"
        z: 15

        Text {
            id: feedbackText
            color: "#fff"
            font.pixelSize: vpx(14)
            font.family: globalFonts.sans
            anchors.centerIn: parent
        }

        Timer {
            id: feedbackTimer
            interval: 4000
            onTriggered: connFeedback.visible = false
        }
    }
}
