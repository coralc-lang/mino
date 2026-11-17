import QtQuick 2.15
import QtQuick.Controls 2.15
import SDDM 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#0f1419"

    Text {
        id: title
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -80
        text: "mino"
        color: "#88c0d0"
        font.family: "JetBrains Mono Nerd Font"
        font.pixelSize: 48
        font.weight: Font.Light
    }

    Text {
        id: clock
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -140
        text: Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
        color: "#8b949e"
        font.family: "JetBrains Mono Nerd Font"
        font.pixelSize: 18
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
    }

    Column {
        anchors.centerIn: parent
        spacing: 16

        TextField {
            id: username
            width: 280
            height: 44
            placeholderText: "user"
            color: "#e5e9f0"
            placeholderTextColor: "#8b949e"
            background: Rectangle {
                color: "#161b22"
                border.color: "#2e3440"
                border.width: 1
            }
            font.family: "JetBrains Mono Nerd Font"
            Keys.onReturnPressed: password.forceActiveFocus()
        }

        TextField {
            id: password
            width: 280
            height: 44
            placeholderText: "password"
            echoMode: TextInput.Password
            color: "#e5e9f0"
            placeholderTextColor: "#8b949e"
            background: Rectangle {
                color: "#161b22"
                border.color: focused ? "#88c0d0" : "#2e3440"
                border.width: focused ? 2 : 1
                property bool focused: password.activeFocus
            }
            font.family: "JetBrains Mono Nerd Font"
            Keys.onReturnPressed: sddm.login(username.text, password.text, sessionCombo.currentIndex)
        }

        ComboBox {
            id: sessionCombo
            width: 280
            model: sessionModel
            textRole: "name"
            valueRole: "id"
        }

        Button {
            width: 280
            height: 40
            text: "Login"
            onClicked: sddm.login(username.text, password.text, sessionCombo.currentIndex)
            contentItem: Text {
                text: parent.text
                color: "#0f1419"
                font.family: "JetBrains Mono Nerd Font"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? "#a8d8ea" : "#88c0d0"
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
