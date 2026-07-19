// Pegasus Frontend
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


import QtQuick 2.8
import Pegasus.FolderListModel 1.0


FocusScope {
    id: root

    signal cancel
    signal pick(string file_path)

    anchors.fill: parent

    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            root.cancel();
        }
    }


    FolderListModel {
        id: folderModel
        files: []
        extensions: [
            ".png",
            ".jpg",
            ".jpeg",
            ".bmp",
            ".gif",
            ".svg",
            ".webp",
        ]
    }


    Rectangle {
        id: shade
        anchors.fill: parent
        color: "#000"

        opacity: 0.3

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.cancel()
        }
    }


    Rectangle {
        height: parent.height * 0.9
        width: height * 1.5
        color: "#444"
        radius: vpx(8)

        anchors.centerIn: parent


        MouseArea {
            anchors.fill: parent
        }

        Text {
            id: info
            text: qsTr("Select an image file for the startup splash logo.") + api.tr
            color: "#ee4"
            font.family: globalFonts.sans
            font.pixelSize: vpx(18)
            lineHeight: 1.15

            anchors.top: parent.top
            width: parent.width
            padding: font.pixelSize

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        Item {
            anchors.top: info.bottom
            anchors.bottom: resetBtn.top
            anchors.bottomMargin: vpx(8)
            width: parent.width - vpx(30)
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                id: path
                width: parent.width
                height: pathText.height
                color: "#222"

                Text {
                    id: pathText
                    text: folderModel.folder
                    width: parent.width

                    color: "#bbb"
                    font.family: globalFonts.sans
                    font.pixelSize: vpx(18)

                    lineHeight: 2.5
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: font.pixelSize; rightPadding: leftPadding
                    elide: Text.ElideMiddle
                }
            }
            Rectangle {
                width: parent.width
                anchors.top: path.bottom
                anchors.bottom: parent.bottom
                color: "#333"

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true

                    model: folderModel
                    delegate: fileDelegate

                    focus: true
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: height * 0.5 - vpx(18) * 1.25
                    preferredHighlightEnd: height * 0.5 + vpx(18) * 1.25
                    highlightMoveDuration: 0

                    KeyNavigation.down: resetBtn
                }
            }
        }

        FocusScope {
            id: resetBtn
            width: parent.width - vpx(30)
            height: resetText.height * 2.5
            anchors.bottom: parent.bottom
            anchors.bottomMargin: vpx(15)
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                color: resetMouse.containsMouse || resetBtn.activeFocus ? "#566" : "#333"
                radius: vpx(4)
            }

            Text {
                id: resetText
                text: qsTr("Reset to default logo") + api.tr
                color: "#eee"
                font.family: globalFonts.sans
                font.pixelSize: vpx(18)
                anchors.centerIn: parent
            }

            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.pick("");
                    root.cancel();
                }
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    root.pick("");
                    root.cancel();
                }
            }

            KeyNavigation.up: list
        }
    }

    Component {
        id: fileDelegate

        Rectangle {
            readonly property bool highlighted: ListView.isCurrentItem || mouseArea.containsMouse

            color: highlighted ? "#566" : "transparent"
            width: ListView.view.width
            height: label.height

            function pickItem() {
                if (!isDir) {
                    root.pick(folderModel.folder + "/" + name);
                    root.cancel();
                    return;
                }

                folderModel.cd(name);
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    pickItem();
                }
            }


            Image {
                id: icon
                source: isDir ? "qrc:/frontend/assets/dir-icon.png" : "";

                fillMode: Image.PreserveAspectFit
                height: parent.height * 0.75
                width: height

                anchors.left: parent.left
                anchors.leftMargin: parent.height * 0.5
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.08
            }

            Text {
                id: label
                text: name
                verticalAlignment: Text.AlignVCenter
                lineHeight: 2.5

                color: "#eee"
                font.bold: !isDir
                font.family: globalFonts.sans
                font.pixelSize: vpx(18)

                anchors.left: icon.right
                anchors.right: parent.right
                leftPadding: parent.height * 0.25
                rightPadding: parent.height * 0.5
                elide: Text.ElideRight
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: pickItem()
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
