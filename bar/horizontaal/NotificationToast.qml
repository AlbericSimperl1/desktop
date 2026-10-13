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

    // Midden bovenaan
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 8
        left: 0
        right: 0
    }

    // Alleen de toasts zelf vangen input
    mask: Region {
        item: toastCol
    }

    // Container die de toasts horizontaal centreert
    Item {
        id: centerBox
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: toastCol.width
        height: toastCol.height

        Column {
            id: toastCol
            width: 340
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
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.dismissToast(toast.tid)
                    }

                    RowLayout {
                        id: toastRow
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            Layout.alignment: Qt.AlignCenter
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
                                font.pixelSize: 40
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
                                font.pixelSize: 17
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: toast.title !== ""
                                width: parent.width
                                text: toast.title
                                color: "#fff7e5"
                                font.family: "mononoki"
                                font.pixelSize: 20
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
}
