import QtQuick 2.15


FocusScope {
    id: root

    signal accepted(string text)
    signal cancelled

    property string inputText: ""
    property bool shift: false
    property bool symbols: false
    property bool passwordMode: false
    property string title: ""

    function open(initialText) {
        inputText = initialText || "";
        shift = false;
        symbols = false;
        root.visible = true;
        root.focus = true;
        cursorRow = 0;
        cursorCol = 0;
    }

    visible: false
    anchors.fill: parent

    Keys.onPressed: {
        if (event.isAutoRepeat) return;

        if (api.keys.isUp(event)) {
            event.accepted = true;
            moveUp();
        } else if (api.keys.isDown(event)) {
            event.accepted = true;
            moveDown();
        } else if (api.keys.isLeft(event)) {
            event.accepted = true;
            moveLeft();
        } else if (api.keys.isRight(event)) {
            event.accepted = true;
            moveRight();
        } else if (api.keys.isCancel(event)) {
            event.accepted = true;
            if (inputText.length > 0) {
                backspace();
            } else {
                root.visible = false;
                root.cancelled();
            }
        } else if (api.keys.isAccept(event)) {
            event.accepted = true;
            pressCurrentKey();
        }
    }

    property int cursorRow: 0
    property int cursorCol: 0

    readonly property var letterRows: [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"],
        ["shift","symbols","space","backspace","cancel","enter"]
    ]

    readonly property var symbolRows: [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["!","@","#","$","%","^","&","*","(",")"],
        ["-","_","=","+","[","]","{","}","|","\\"],
        [";",":","'",",",".","/","?","~","`"],
        ["shift","symbols","space","backspace","cancel","enter"]
    ]

    readonly property var rows: symbols ? symbolRows : letterRows

    function getKey(row, col) {
        if (row < 0 || row >= rows.length) return "";
        var r = rows[row];
        if (col < 0 || col >= r.length) return "";
        return r[col];
    }

    function moveUp() {
        if (cursorRow > 0) {
            cursorRow--;
            var maxCol = rows[cursorRow].length - 1;
            if (cursorCol > maxCol) cursorCol = maxCol;
        }
    }

    function moveDown() {
        if (cursorRow < rows.length - 1) {
            cursorRow++;
            var maxCol = rows[cursorRow].length - 1;
            if (cursorCol > maxCol) cursorCol = maxCol;
        }
    }

    function moveLeft() {
        if (cursorCol > 0) cursorCol--;
    }

    function moveRight() {
        var maxCol = rows[cursorRow].length - 1;
        if (cursorCol < maxCol) cursorCol++;
    }

    function pressCurrentKey() {
        var key = getKey(cursorRow, cursorCol);
        if (key === "") return;

        if (key === "shift") {
            shift = !shift;
        } else if (key === "symbols") {
            symbols = !symbols;
            shift = false;
            var maxCol = rows[cursorRow].length - 1;
            if (cursorCol > maxCol) cursorCol = maxCol;
        } else if (key === "backspace") {
            backspace();
        } else if (key === "enter") {
            root.visible = false;
            root.accepted(root.inputText);
        } else if (key === "cancel") {
            root.visible = false;
            root.cancelled();
        } else if (key === "space") {
            inputText += " ";
        } else {
            var ch = shift ? key.toUpperCase() : key;
            inputText += ch;
            if (shift && key.length === 1 && key.match(/[a-z]/i))
                shift = false;
        }
    }

    function backspace() {
        if (inputText.length > 0)
            inputText = inputText.substring(0, inputText.length - 1);
    }

    Rectangle {
        anchors.fill: parent
        color: "#000"
        opacity: 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.visible = false;
                root.cancelled();
            }
        }
    }

    Rectangle {
        id: kbd
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.95, vpx(900))
        height: contentCol.height + vpx(30)
        color: "#1a1a2e"
        radius: vpx(10)
        border.color: "#3aa"
        border.width: vpx(2)

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: vpx(15)
            spacing: vpx(8)

            Text {
                width: parent.width
                visible: root.title.length > 0
                text: root.title
                color: "#3aa"
                font.pixelSize: vpx(16)
                font.family: globalFonts.sans
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                width: parent.width
                height: vpx(44)
                color: "#0d0d1a"
                radius: vpx(6)

                TextInput {
                    id: textDisplay
                    anchors.fill: parent
                    anchors.margins: vpx(8)
                    color: "#fff"
                    font.pixelSize: vpx(18)
                    font.family: globalFonts.sans
                    text: {
                        var display = root.passwordMode ? "\u2022".repeat(root.inputText.length) : root.inputText;
                        return display + (display.length < 40 ? "_" : "");
                    }
                    clip: true
                    readOnly: true
                }
            }

            Repeater {
                model: root.rows.length

                Row {
                    property int rowIdx: index
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(4)

                    Repeater {
                        model: root.rows[index].length

                        Rectangle {
                            property int colIdx: index
                            property bool isCursor: root.cursorRow === rowIdx && root.cursorCol === colIdx
                            property string keyValue: root.rows[rowIdx][index]
                            property bool isSpecial: keyValue === "shift" || keyValue === "backspace" || keyValue === "cancel" || keyValue === "symbols" || keyValue === "enter"

                            width: isSpecial ? vpx(100) : (keyValue === "space" ? vpx(200) : vpx(60))
                            height: vpx(52)
                            radius: vpx(6)
                            color: isCursor ? "#3aa" : (keyValue === "symbols" && root.symbols ? "#443366" : (keyValue === "enter" ? "#2a6644" : "#2a2a3e"))
                            border.color: isCursor ? "#5ee" : "#444"
                            border.width: isCursor ? vpx(2) : vpx(1)

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (keyValue === "shift") return root.shift ? "SHIFT" : "Shift";
                                    if (keyValue === "backspace") return "Bksp";
                                    if (keyValue === "enter") return "Enter";
                                    if (keyValue === "cancel") return "Cancel";
                                    if (keyValue === "space") return "Space";
                                    if (keyValue === "symbols") return root.symbols ? "ABC" : "#+=";
                                    return root.shift ? keyValue.toUpperCase() : keyValue;
                                }
                                color: isCursor ? "#fff" : "#ccc"
                                font.pixelSize: vpx(isSpecial ? 14 : 20)
                                font.family: globalFonts.sans
                                font.bold: isCursor
                            }

                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                }
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: vpx(4)
            spacing: vpx(20)
            Text { text: "D-Pad: Move"; color: "#666"; font.pixelSize: vpx(11); font.family: globalFonts.sans }
            Text { text: "A: Select"; color: "#666"; font.pixelSize: vpx(11); font.family: globalFonts.sans }
            Text { text: "B: Backspace"; color: "#666"; font.pixelSize: vpx(11); font.family: globalFonts.sans }
        }
    }
}
