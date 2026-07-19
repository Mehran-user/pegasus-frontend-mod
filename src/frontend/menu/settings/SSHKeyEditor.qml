import "common"
import QtQuick 2.15
import QtQuick.Window 2.2


FocusScope {
    id: root

    signal close

    anchors.fill: parent

    onVisibleChanged: {
        if (visible) {
            Internal.settings.ssh.reloadKeys();
            keyList.forceActiveFocus();
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.close();
        }
    }

    ScreenHeader {
        id: header
        text: qsTr("SSH Keys") + api.tr
        z: 2
    }

    // Action buttons
    FocusScope {
        id: actionRow
        anchors.top: header.bottom
        anchors.topMargin: vpx(20)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: vpx(20)
        anchors.rightMargin: vpx(20)
        height: vpx(36)

        property int actionCount: 3
        property int actionIndex: 0

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: vpx(12)

            Rectangle {
                width: addKeyBtn.implicitWidth + vpx(40)
                height: vpx(36)
                radius: vpx(6)
                color: actionRow.activeFocus && actionRow.actionIndex === 0 ? "#3aa" : (addMA.containsMouse ? "#4aa" : "#333")
                border.color: actionRow.activeFocus && actionRow.actionIndex === 0 ? "#5ee" : "transparent"
                border.width: vpx(2)

                Text {
                    id: addKeyBtn
                    text: qsTr("Add Key") + api.tr
                    color: "#ccc"
                    font.pixelSize: vpx(14)
                    font.family: globalFonts.sans
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: addMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: addKeyDialog.visible = true
                }
            }

            Rectangle {
                id: removeKeyBtn
                width: removeKeyLabel.implicitWidth + vpx(40)
                height: vpx(36)
                radius: vpx(6)
                color: actionRow.activeFocus && actionRow.actionIndex === 1 ? "#a44" : (removeMA.containsMouse ? "#a44" : "#333")
                border.color: actionRow.activeFocus && actionRow.actionIndex === 1 ? "#f66" : "transparent"
                border.width: vpx(2)
                visible: keyList.count > 0

                Text {
                    id: removeKeyLabel
                    text: qsTr("Remove Key") + api.tr
                    color: "#ccc"
                    font.pixelSize: vpx(14)
                    font.family: globalFonts.sans
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: removeMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (keyList.currentIndex >= 0) {
                            Internal.settings.ssh.removeKey(keyList.currentIndex);
                            keyList.currentIndex = Math.min(keyList.currentIndex, keyList.count - 1);
                        }
                    }
                }
            }

            Rectangle {
                id: refreshBtn
                width: refreshKeyLabel.implicitWidth + vpx(40)
                height: vpx(36)
                radius: vpx(6)
                color: actionRow.activeFocus && actionRow.actionIndex === 2 ? "#3aa" : (refreshMA.containsMouse ? "#4aa" : "#333")
                border.color: actionRow.activeFocus && actionRow.actionIndex === 2 ? "#5ee" : "transparent"
                border.width: vpx(2)

                Text {
                    id: refreshKeyLabel
                    text: qsTr("Refresh") + api.tr
                    color: "#ccc"
                    font.pixelSize: vpx(14)
                    font.family: globalFonts.sans
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: refreshMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Internal.settings.ssh.reloadKeys()
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
                if (actionRow.actionIndex === 0) addKeyDialog.visible = true;
                else if (actionRow.actionIndex === 1 && keyList.count > 0) {
                    Internal.settings.ssh.removeKey(keyList.currentIndex);
                    keyList.currentIndex = Math.min(keyList.currentIndex, keyList.count - 1);
                }
                else if (actionRow.actionIndex === 2) Internal.settings.ssh.reloadKeys();
            } else if (api.keys.isDown(event)) {
                event.accepted = true;
                keyList.forceActiveFocus();
            }
        }
    }

    // Key list
    ListView {
        id: keyList
        anchors.top: actionRow.bottom
        anchors.topMargin: vpx(12)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: header.height
        clip: true
        focus: true

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

        header: Rectangle {
            width: keyList.width
            height: keyList.count === 0 ? vpx(120) : vpx(36)

            Text {
                anchors.centerIn: parent
                text: keyList.count === 0 ? qsTr("No SSH keys found") + api.tr : ""
                color: "#666"
                font.pixelSize: vpx(16)
                font.family: globalFonts.sans
            }

            Text {
                visible: keyList.count > 0
                anchors.left: parent.left
                anchors.leftMargin: vpx(20)
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Keys") + api.tr
                color: "#3aa"
                font.pixelSize: vpx(14)
                font.family: globalFonts.sans
                font.bold: true
            }
        }

        delegate: Rectangle {
            width: keyList.width
            height: vpx(64)
            color: ListView.isCurrentItem ? "#2a4a4a" : (keyMouse.containsMouse ? "#2a2a3e" : "transparent")

            Column {
                anchors.fill: parent
                anchors.leftMargin: vpx(20)
                anchors.rightMargin: vpx(20)
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(4)

                Text {
                    text: Internal.settings.ssh.keyComment(index)
                    color: "#eee"
                    font.pixelSize: vpx(15)
                    font.family: globalFonts.sans
                    elide: Text.ElideRight
                    width: keyList.width - vpx(40)
                }

                Row {
                    spacing: vpx(12)

                    Text {
                        text: Internal.settings.ssh.keyType(index)
                        color: "#3aa"
                        font.pixelSize: vpx(12)
                        font.family: globalFonts.sans
                    }

                    Text {
                        text: Internal.settings.ssh.keyFingerprint(index)
                        color: "#666"
                        font.pixelSize: vpx(11)
                        font.family: globalFonts.sans
                        elide: Text.ElideRight
                        width: keyList.width - vpx(200)
                    }
                }
            }

            MouseArea {
                id: keyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: keyList.currentIndex = index
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

    // Add key dialog
    Rectangle {
        id: addKeyDialog
        visible: false
        anchors.fill: parent
        z: 40

        Rectangle {
            anchors.fill: parent
            color: "#000"
            opacity: 0.6
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.7, vpx(450))
            height: addKeyCol.height + vpx(40)
            color: "#1a1a2e"
            radius: vpx(10)
            border.color: "#3aa"
            border.width: vpx(2)

            Column {
                id: addKeyCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: vpx(20)
                spacing: vpx(12)

                Text {
                    text: qsTr("Generate SSH Key") + api.tr
                    color: "#eee"
                    font.pixelSize: vpx(18)
                    font.family: globalFonts.sans
                    font.bold: true
                }

                Text {
                    text: qsTr("Key type:") + api.tr
                    color: "#aaa"
                    font.pixelSize: vpx(14)
                    font.family: globalFonts.sans
                }

                // Key type selector
                Row {
                    spacing: vpx(8)

                    Repeater {
                        model: ["id_ed25519", "id_rsa", "id_ecdsa"]

                        Rectangle {
                            width: typeLabel.implicitWidth + vpx(20)
                            height: vpx(32)
                            radius: vpx(6)
                            color: addKeyCol.keyTypeIdx === index ? "#3aa" : "#333"
                            border.color: addKeyCol.keyTypeIdx === index ? "#5ee" : "#555"
                            border.width: vpx(1)

                            Text {
                                id: typeLabel
                                text: modelData
                                color: "#eee"
                                font.pixelSize: vpx(13)
                                font.family: globalFonts.sans
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: addKeyCol.keyTypeIdx = index
                            }
                        }
                    }
                }

                property int keyTypeIdx: 0

                Text {
                    text: qsTr("Comment (optional):") + api.tr
                    color: "#aaa"
                    font.pixelSize: vpx(14)
                    font.family: globalFonts.sans
                }

                Rectangle {
                    width: parent.width
                    height: vpx(40)
                    color: "#0d0d1a"
                    radius: vpx(6)
                    border.color: "#3aa"
                    border.width: vpx(1)

                    TextInput {
                        id: commentInput
                        anchors.fill: parent
                        anchors.margins: vpx(10)
                        color: "#fff"
                        font.pixelSize: vpx(14)
                        font.family: globalFonts.sans
                        clip: true
                        focus: false

                        Text {
                            anchors.centerIn: parent
                            text: commentInput.text.length === 0 ? qsTr("e.g. my-device") + api.tr : ""
                            color: "#666"
                            font.pixelSize: vpx(14)
                            font.family: globalFonts.sans
                            visible: !commentInput.activeFocus
                        }
                    }
                }

                Row {
                    spacing: vpx(12)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: generateLabel.implicitWidth + vpx(30)
                        height: vpx(36)
                        radius: vpx(6)
                        color: "#3aa"

                        Text {
                            id: generateLabel
                            text: qsTr("Generate") + api.tr
                            color: "#fff"
                            font.pixelSize: vpx(14)
                            font.family: globalFonts.sans
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var types = ["id_ed25519", "id_rsa", "id_ecdsa"];
                                var comment = commentInput.text.trim();
                                Internal.settings.ssh.addKey(types[addKeyCol.keyTypeIdx], comment);
                                commentInput.text = "";
                                addKeyDialog.visible = false;
                            }
                        }

                        Keys.onPressed: {
                            if (event.isAutoRepeat) return;
                            if (api.keys.isAccept(event)) {
                                event.accepted = true;
                                var types = ["id_ed25519", "id_rsa", "id_ecdsa"];
                                var comment = commentInput.text.trim();
                                Internal.settings.ssh.addKey(types[addKeyCol.keyTypeIdx], comment);
                                commentInput.text = "";
                                addKeyDialog.visible = false;
                            }
                        }
                    }

                    Rectangle {
                        width: cancelKeyLabel.implicitWidth + vpx(30)
                        height: vpx(36)
                        radius: vpx(6)
                        color: "#555"

                        Text {
                            id: cancelKeyLabel
                            text: qsTr("Cancel") + api.tr
                            color: "#ccc"
                            font.pixelSize: vpx(14)
                            font.family: globalFonts.sans
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addKeyDialog.visible = false
                        }
                    }
                }
            }
        }

        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            if (api.keys.isCancel(event)) {
                event.accepted = true;
                addKeyDialog.visible = false;
            }
        }
    }
}
