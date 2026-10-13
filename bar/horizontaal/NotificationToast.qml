// bar/horizontaal/NotificationToast.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: toastWindow
    visible: Notifications.toasts.count > 0
    implicitWidth: 340
    implicitHeight: 700
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.namespace: "quickshell:toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 16
    }

    // only the toasts themselves catch input
    mask: Region {
        item: toastCol
    }

    Column {
        id: toastCol
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifications.toasts

            delegate: Rectangle {
                id: toast
                required property string tid
                required property string appName
                required property string icon
                required property string title
                required property string body
                required property int timeout
                required property int token

                width: toastCol.width
                height: toastRow.implicitHeight + 24
                radius: 6
                color: "#f2121210"
                border.width: 1
                border.color: "#2effffff"

                onTokenChanged: life.restart()

                Timer {
                    id: life
                    interval: toast.timeout > 0 ? toast.timeout : 5000
                    running: true
                    onTriggered: Notifications.dismissToast(toast.tid)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Notifications.dismissToast(toast.tid)
                }

                RowLayout {
                    id: toastRow
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignTop
                        radius: 6
                        color: "#40000000"
                        clip: true

                        Image {
                            id: toastImg
                            anchors.fill: parent
                            anchors.margins: 3
                            source: toast.icon
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            sourceSize.width: 72
                            sourceSize.height: 72
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: toastImg.status !== Image.Ready
                            text: "\udb80\udc9a"
                            color: "#fff7e5"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 20
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            visible: toast.appName !== ""
                            width: parent.width
                            text: toast.appName
                            color: "#b3fff7e5"
                            font.family: "mononoki"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: toast.title !== ""
                            width: parent.width
                            text: toast.title
                            color: "#fff7e5"
                            font.family: "mononoki"
                            font.pixelSize: 13
                            font.bold: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: toast.body !== ""
                            width: parent.width
                            text: toast.body
                            color: "#b3fff7e5"
                            font.family: "mononoki"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
