import "common"
import QtQuick 2.15
import QtQuick.Window 2.2


FocusScope {
    id: root

    signal close
    signal openKeyEditor

    property string sudoPassword: ""

    anchors.fill: parent

    onVisibleChanged: {
        if (visible) statusArea.forceActiveFocus();
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
    }

    ScreenHeader {
        id: header
        text: qsTr("SSH") + api.tr
        z: 2
    }

    // Install dialog overlay
    Rectangle {
        id: installOverlay
        visible: Internal.settings.ssh.installing || installDone
        anchors.fill: parent
        z: 50
        color: "#000"
        opacity: 0.85

        property bool installDone: false
        property bool installSuccess: false

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.7, vpx(500))
            height: installCol.height + vpx(40)
            color: "#1a1a2e"
            radius: vpx(10)
            border.color: "#3aa"
            border.width: vpx(2)

            Column {
                id: installCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: vpx(20)
                spacing: vpx(12)

                Text {
                    text: installOverlay.installDone
                        ? (installOverlay.installSuccess ? qsTr("Installation Complete") + api.tr : qsTr("Installation Failed") + api.tr)
                        : qsTr("Installing OpenSSH Server...") + api.tr
                    color: "#eee"
                    font.pixelSize: vpx(18)
                    font.family: globalFonts.sans
                    font.bold: true
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: parent.width
                    height: vpx(200)
                    color: "#0d0d1a"
                    radius: vpx(6)

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: vpx(8)
                        contentHeight: installLog.implicitHeight
                        clip: true

                        Text {
                            id: installLog
                            width: parent.width
                            text: Internal.settings.ssh.installOutput
                            color: "#aaa"
                            font.pixelSize: vpx(12)
                            font.family: globalFonts.sans
                            wrapMode: Text.Wrap
                        }
                    }
                }

                // Progress bar
                Rectangle {
                    width: parent.width
                    height: vpx(4)
                    radius: vpx(2)
                    color: "#333"
                    visible: !installOverlay.installDone

                    Rectangle {
                        width: parent.width
                        height: parent.height
                        radius: vpx(2)
                        color: "#3aa"

                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            NumberAnimation { from: -parent.width; to: parent.width; duration: 1500 }
                        }
                    }
                }

                Rectangle {
                    width: dismissLabel.implicitWidth + vpx(30)
                    height: vpx(36)
                    radius: vpx(6)
                    color: "#3aa"
                    visible: installOverlay.installDone
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: dismissLabel
                        text: qsTr("OK") + api.tr
                        color: "#fff"
                        font.pixelSize: vpx(14)
                        font.family: globalFonts.sans
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            installOverlay.installDone = false;
                            Internal.settings.ssh.reloadKeys();
                        }
                    }

                    Keys.onPressed: {
                        if (event.isAutoRepeat) return;
                        if (api.keys.isAccept(event)) {
                            event.accepted = true;
                            installOverlay.installDone = false;
                            Internal.settings.ssh.reloadKeys();
                        }
                    }
                }
            }
        }

        Connections {
            target: Internal.settings.ssh
            function onInstallResult(success, message) {
                installOverlay.installSuccess = success;
                installOverlay.installDone = true;
            }
        }
    }

    // Connection info
    Rectangle {
        id: connInfo
        anchors.top: header.bottom
        anchors.topMargin: vpx(20)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width * 0.7, vpx(500))
        height: connCol.height + vpx(30)
        color: "#1a2a2a"
        radius: vpx(8)
        border.color: "#3aa"
        border.width: Internal.settings.ssh.sshRunning ? vpx(1) : 0

        Column {
            id: connCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: vpx(15)
            spacing: vpx(6)

            Text {
                text: qsTr("Connection") + api.tr
                color: "#3aa"
                font.pixelSize: vpx(14)
                font.family: globalFonts.sans
                font.bold: true
            }

            Text {
                text: Internal.settings.ssh.sshRunning
                    ? qsTr("ssh %1@%2 -p %3").arg(Internal.settings.ssh.userName).arg(Internal.settings.ssh.ipAddress).arg(Internal.settings.ssh.sshPort)
                    : qsTr("SSH server is not running")
                color: "#eee"
                font.pixelSize: vpx(14)
                font.family: globalFonts.sans
                font.bold: true
            }

            Text {
                text: Internal.settings.ssh.ipAddress
                    ? qsTr("IP: %1:%2").arg(Internal.settings.ssh.ipAddress).arg(Internal.settings.ssh.sshPort)
                    : qsTr("No network connection")
                color: "#aaa"
                font.pixelSize: vpx(12)
                font.family: globalFonts.sans
            }
        }
    }

    // Status / toggle area
    FocusScope {
        id: statusArea
        anchors.top: connInfo.bottom
        anchors.topMargin: vpx(16)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: vpx(20)
        anchors.rightMargin: vpx(20)
        height: statusCol.height
        focus: true

        Column {
            id: statusCol
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: vpx(8)

            // SSH not installed
            FocusScope {
                width: parent.width
                height: vpx(40)
                visible: !Internal.settings.ssh.sshInstalled

                Rectangle {
                    anchors.centerIn: parent
                    width: installBtnLabel.implicitWidth + vpx(40)
                    height: vpx(36)
                    radius: vpx(6)
                    color: statusArea.activeFocus ? "#3aa" : "#333"
                    border.color: statusArea.activeFocus ? "#5ee" : "transparent"
                    border.width: vpx(2)

                    Text {
                        id: installBtnLabel
                        text: qsTr("Install OpenSSH Server") + api.tr
                        color: "#eee"
                        font.pixelSize: vpx(14)
                        font.family: globalFonts.sans
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.promptSudoPassword()
                    }
                }
            }

            // Running status
            Text {
                width: parent.width
                height: vpx(30)
                visible: Internal.settings.ssh.sshInstalled
                text: Internal.settings.ssh.sshRunning
                    ? qsTr("Status: Running") + api.tr
                    : qsTr("Status: Stopped") + api.tr
                color: Internal.settings.ssh.sshRunning ? "#3aa" : "#a44"
                font.pixelSize: vpx(16)
                font.family: globalFonts.sans
                verticalAlignment: Text.AlignVCenter
            }
        }

        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            if (api.keys.isAccept(event)) {
                event.accepted = true;
                if (!Internal.settings.ssh.sshInstalled)
                    root.promptSudoPassword();
            } else if (api.keys.isDown(event)) {
                event.accepted = true;
                actionRow.forceActiveFocus();
            }
        }
    }

    // Action buttons
    FocusScope {
        id: actionRow
        anchors.top: statusArea.bottom
        anchors.topMargin: vpx(12)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: vpx(20)
        anchors.rightMargin: vpx(20)
        height: vpx(36)
        visible: Internal.settings.ssh.sshInstalled

        property int actionIndex: 0

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: vpx(12)

            Rectangle {
                width: keysBtnLabel.implicitWidth + vpx(40)
                height: vpx(36)
                radius: vpx(6)
                color: actionRow.activeFocus && actionRow.actionIndex === 0 ? "#3aa" : (keysBtnMA.containsMouse ? "#4aa" : "#333")
                border.color: actionRow.activeFocus && actionRow.actionIndex === 0 ? "#5ee" : "transparent"
                border.width: vpx(2)

                Text {
                    id: keysBtnLabel
                    text: qsTr("Manage Keys...") + api.tr
                    color: "#ccc"
                    font.pixelSize: vpx(14)
                    font.family: globalFonts.sans
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: keysBtnMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openKeyEditor()
                }
            }
        }

        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            if (api.keys.isAccept(event)) {
                event.accepted = true;
                root.openKeyEditor();
            } else if (api.keys.isUp(event)) {
                event.accepted = true;
                statusArea.forceActiveFocus();
            } else if (api.keys.isDown(event)) {
                event.accepted = true;
                keyList.forceActiveFocus();
            }
        }
    }

    // Key list
    ListView {
        id: keyList
        anchors.top: actionRow.visible ? actionRow.bottom : statusArea.bottom
        anchors.topMargin: vpx(12)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: header.height
        clip: true
        focus: false
        visible: Internal.settings.ssh.sshInstalled

        model: Internal.settings.ssh.keyCount()

        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: height * 0.2
        preferredHighlightEnd: height * 0.8
        highlightMoveDuration: 150

        highlight: Rectangle {
            color: "transparent"
            border.color: "#3aa"
            border.width: vpx(2)
            radius: vpx(4)
        }

        KeyNavigation.up: actionRow

        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            if (api.keys.isUp(event) && keyList.currentIndex === 0) {
                event.accepted = true;
                actionRow.forceActiveFocus();
            }
        }

        header: Rectangle {
            width: keyList.width
            height: vpx(36)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: vpx(20)
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("SSH Keys") + api.tr
                color: "#3aa"
                font.pixelSize: vpx(14)
                font.family: globalFonts.sans
                font.bold: true
            }
        }

        delegate: Rectangle {
            width: keyList.width
            height: vpx(56)
            color: ListView.isCurrentItem ? "#2a4a4a" : (keyMouse.containsMouse ? "#2a2a3e" : "transparent")

            Row {
                anchors.fill: parent
                anchors.leftMargin: vpx(20)
                anchors.rightMargin: vpx(20)
                spacing: vpx(12)

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(2)

                    Text {
                        text: Internal.settings.ssh.keyComment(index)
                        color: "#eee"
                        font.pixelSize: vpx(14)
                        font.family: globalFonts.sans
                        elide: Text.ElideRight
                        width: keyList.width - vpx(60)
                    }

                    Text {
                        text: Internal.settings.ssh.keyFingerprint(index)
                        color: "#666"
                        font.pixelSize: vpx(11)
                        font.family: globalFonts.sans
                        elide: Text.ElideRight
                        width: keyList.width - vpx(60)
                    }
                }
            }

            MouseArea {
                id: keyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    keyList.currentIndex = index;
                    root.openKeyEditor();
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

    // Device action feedback
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

    // Onscreen keyboard for sudo password
    OnScreenKeyboard {
        id: sudoKeyboard
        anchors.fill: parent
        z: 30
        visible: false
        passwordMode: true
        title: qsTr("Enter sudo password") + api.tr

        onAccepted: {
            sudoKeyboard.visible = false;
            Internal.settings.ssh.install(text);
        }
        onCancelled: {
            sudoKeyboard.visible = false;
        }
    }

    function promptSudoPassword() {
        sudoKeyboard.open("");
        sudoKeyboard.visible = true;
    }
}
