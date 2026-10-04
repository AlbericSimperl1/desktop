import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

import ".."
import "../components"

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

    height: 34
    implicitHeight: barRoot.height
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 18
    anchors.rightMargin: 18

    Ws2 {
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
        spacing: 22

        Brightness {
            Layout.alignment: Qt.AlignVCenter
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
                    font.pixelSize: 28 + 3
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
            text: ""
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 25 + 3
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
            font.pixelSize: 24 + 10
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

        Text {
            id: powerWidget
            text: "⏻"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 25 + 3
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
