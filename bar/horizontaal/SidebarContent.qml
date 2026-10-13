// bar/horizontaal/SidebarContent.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Item {
    id: barRoot

    property string rustCmd: "noctalia"
    property var activePlayer: null
    property string fontFamily: "JetBrainsMono Nerd Font Mono"
    property color fgColor: "#fff7e5"
    property bool isMediaOpen: false

    signal mediaClicked(real clickX)
    signal bluetoothClicked(real clickX)
    signal wifiClicked(real clickX)
    signal notificationsClicked(real clickX)
    signal powerClicked(real clickX)
    signal brightnessClicked(real clickX)

    height: 24
    implicitHeight: barRoot.height
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 18
    anchors.rightMargin: 18

    Ws {
        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
    }

    Clock {
        id: clock
        anchors.left: parent.left
        fontFamily: barRoot.fontFamily
        fgColor: barRoot.fgColor
        anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18

        // --- BRIGHTNESS WIDGET ---
        Brightness {
            id: brightnessWidget
            Layout.alignment: Qt.AlignVCenter

            fontFamily: barRoot.fontFamily
            fgColor: barRoot.fgColor

            onClicked: {
                let mapped = brightnessWidget.mapToItem(barRoot.parent, 0, 0);
                barRoot.brightnessClicked(mapped.x + brightnessWidget.width / 2);
            }
        }

        Item {
            id: mediaWidget
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 22
            implicitHeight: 22

            readonly property string artUrl: barRoot.activePlayer && barRoot.activePlayer.trackArtUrl ? barRoot.activePlayer.trackArtUrl : ""

            Item {
                anchors.fill: parent
                opacity: barRoot.isMediaOpen ? 0 : 1

                Image {
                    id: mediaArt
                    anchors.fill: parent
                    source: mediaWidget.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 6
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: mediaArt
                    maskSource: maskRect
                    visible: mediaArt.status === Image.Ready && mediaWidget.artUrl !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: mediaArt.status !== Image.Ready || mediaWidget.artUrl === ""
                    text: "󰎈"
                    color: barRoot.fgColor
                    font.family: barRoot.fontFamily
                    font.pixelSize: 26
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let mapped = mediaWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.mediaClicked(mapped.x + mediaWidget.width / 2);
                }
            }
        }

        Text {
            id: bluetoothWidget
            text: ""
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 24
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let mapped = bluetoothWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.bluetoothClicked(mapped.x + bluetoothWidget.width / 2);
                }
            }
        }

        Text {
            id: wifiWidget
            text: "󰤨"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 29
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let mapped = wifiWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.wifiClicked(mapped.x + wifiWidget.width / 2);
                }
            }
        }

        // --- NOTIFICATIONS (left click: panel, right click: DND) ---
        Item {
            id: notifWidget
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 26
            implicitHeight: 24

            Text {
                anchors.centerIn: parent
                text: Notifications.dndEnabled ? "\udb80\udc9b" : "\udb80\udc9a"
                color: barRoot.fgColor
                font.family: barRoot.fontFamily
                font.pixelSize: 25
            }

            Rectangle {
                visible: Notifications.count > 0 && !Notifications.dndEnabled
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 1
                anchors.rightMargin: 2
                width: 7
                height: 7
                radius: 4
                color: "#f0b840"
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        Notifications.toggleDnd();
                    } else {
                        let mapped = notifWidget.mapToItem(barRoot.parent, 0, 0);
                        barRoot.notificationsClicked(mapped.x + notifWidget.width / 2);
                    }
                }
            }
        }

        Text {
            id: powerWidget
            text: "⏻"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 25
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let mapped = powerWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.powerClicked(mapped.x + powerWidget.width / 2);
                }
            }
        }
    }
}
