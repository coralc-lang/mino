import QtQuick 2.15
import QtQuick.Controls 2.15
import SDDM 2.0

Rectangle {
    id: root
    width: 420
    height: 760
    color: "#0f1419"

    property int clockAnim: 0

    function dateTime() {
        return Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
    }

    Column {
        anchors.centerIn: parent
        spacing: 22

        Rectangle {
            width: 200
            height: 4
            radius: 0
            color: "#88c0d0"
            anchors.horizontalCenter
            anchors.top: title.bottom
            anchors.topMargin: -70
        }

        Text {
            id: title
            anchors.horizontalCenter
            text: "mino"
            color: "#88c0d0"
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 52
            font.weight: Font.Light
            anchors.bottom: clock.top
            anchors.bottomMargin: -10
            anchors.horizontalCenter: parent.horizontalCenter
            // position via Column: use explicit placement below
        }

        Text {
            id: clock
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -150
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
            color: "#e5e9f0"
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 20
            font.weight: Font.Medium
            z: 1
        }
    }

    // Simpler robust layout: use explicit column
    Column {
        id: content
        anchors.centerIn: parent
        spacing: 20
        width: 320

        Rectangle {
            width: 320
            height: 2
            color: "#1e2530"
            radius: 0
        }

        Text {
            anchors.horizontalCenter
            text: "mino"
            color: "#88c0d0"
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 46
            font.weight: Font.Light
        }

        Text {
            anchors.horizontalCenter
            text: Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
            color: "#8b949e"
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 16
        }

        Rectangle {
            width: 320
            height: 2
            color: "#1e2530"
            radius: 0
        }

        TextField {
            id: username
            width: 320
            height: 44
            placeholderText: "user"
            inputMethodHints: Qt.ImEnabled
            color: "#e5e9f0"
            placeholderTextColor: "#8b949e"
            background: Rectangle {
                color: "#161b22"
                border.color: username.activeFocus ? "#88c0d0" : "#2e3440"
                border.width: username.activeFocus ? 2 : 1
                radius: 0
            }
            font.family: "JetBrains Mono Nerd Font"
            Keys.onReturnPressed: password.forceActiveFocus()
        }

        TextField {
            id: password
            width: 320
            height: 44
            placeholderText: "password"
            echoMode: TextInput.Password
            color: "#e5e9f0"
            placeholderTextColor: "#8b949e"
            background: Rectangle {
                color: "#161b22"
                border.color: password.activeFocus ? "#88c0d0" : "#2e3440"
                border.width: password.activeFocus ? 2 : 1
                radius: 0
            }
            font.family: "JetBrains Mono Nerd Font"
            Keys.onReturnPressed: sddm.login(username.text, password.text, sessionCombo.currentIndex)
        }

        ComboBox {
            id: sessionCombo
            width: 320
            model: sessionModel
            textRole: "name"
            valueRole: "id"
        }

        Button {
            id: loginBtn
            width: 320
            height: 44
            text: "Login"
            onClicked: sddm.login(username.text, password.text, sessionCombo.currentIndex)
            background: Rectangle {
                color: loginBtn.hovered ? "#a8d8ea" : "#88c0d0"
                radius: 0
            }
            contentItem: Text {
                text: loginBtn.text
                color: "#0f1419"
                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 14
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            password.focus = true
        }
    }
}
