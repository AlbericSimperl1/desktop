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

    // Actief paneel: "media" | "bluetooth" | "wifi" | "notifications" | "power" | "brightness" | "none"
    property string activePanel: "none"

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

    readonly property string chevron: "󰅃"

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

        // --- MEDIA WIDGET ---
        RowLayout {
            id: mediaWidget
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: -9
            spacing: 8

            readonly property bool isOpen: barRoot.activePanel === "media"
            readonly property bool hasPlayer: barRoot.activePlayer !== null
            readonly property string artUrl: hasPlayer && barRoot.activePlayer.trackArtUrl ? barRoot.activePlayer.trackArtUrl : ""
            readonly property string titleText: hasPlayer && barRoot.activePlayer.trackTitle ? barRoot.activePlayer.trackTitle : ""
            readonly property string artistText: hasPlayer && barRoot.activePlayer.trackArtist ? barRoot.activePlayer.trackArtist : ""

            visible: hasPlayer || isOpen

            readonly property string truncatedTitle: {
                let t = titleText;
                if (t.length > 25)
                    return t.substring(0, 25) + "…";
                return t;
            }

            readonly property string combinedText: {
                if (titleText === "" && artistText === "")
                    return "";
                if (artistText === "")
                    return truncatedTitle;
                if (titleText === "")
                    return artistText;
                return artistText + " - " + truncatedTitle;
            }

            // Album art (of fallback icoon)
            Item {
                id: artBox
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 20
                implicitHeight: 20

                Item {
                    anchors.fill: parent
                    opacity: mediaWidget.isOpen ? 0 : 1

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
            }

            // Artiest - Titel (één regel, verborgen wanneer paneel open is)
            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: !mediaWidget.isOpen && mediaWidget.combinedText !== ""
                text: mediaWidget.combinedText
                color: barRoot.fgColor
                font.family: barRoot.fontFamily
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            // Chevron wanneer paneel open is
            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: mediaWidget.isOpen
                text: barRoot.chevron
                color: barRoot.fgColor
                font.family: barRoot.fontFamily
                font.pixelSize: 22
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    let mapped = mediaWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.mediaClicked(mapped.x + mediaWidget.width / 2);
                }
            }
        }

        // --- BLUETOOTH WIDGET ---
        Text {
            id: bluetoothWidget
            readonly property bool isOpen: barRoot.activePanel === "bluetooth"
            text: isOpen ? barRoot.chevron : ""
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: isOpen ? 22 : 22
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    let mapped = bluetoothWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.bluetoothClicked(mapped.x + bluetoothWidget.width / 2);
                }
            }
        }

        // --- WIFI WIDGET ---
        Text {
            id: wifiWidget
            readonly property bool isOpen: barRoot.activePanel === "wifi"
            text: isOpen ? barRoot.chevron : "󰤨"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: isOpen ? 22 : 29
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    let mapped = wifiWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.wifiClicked(mapped.x + wifiWidget.width / 2);
                }
            }
        }

        // --- NOTIFICATIONS WIDGET ---
        Item {
            id: notifWidget
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 16
            implicitHeight: 24

            readonly property bool isOpen: barRoot.activePanel === "notifications"

            Text {
                anchors.centerIn: parent
                text: notifWidget.isOpen ? barRoot.chevron : (Notifications.dndEnabled ? "\udb80\udc9b" : "\udb80\udc9a")
                color: barRoot.fgColor
                font.family: barRoot.fontFamily
                font.pixelSize: notifWidget.isOpen ? 22 : 25
            }

            Rectangle {
                visible: Notifications.count > 0 && !Notifications.dndEnabled && !notifWidget.isOpen
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 2
                anchors.rightMargin: 1
                width: 5
                height: 5
                radius: 4
                color: "#88ff4444"
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
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

        Brightness {
            id: brightnessWidget
            Layout.alignment: Qt.AlignVCenter

            fontFamily: barRoot.fontFamily
            fgColor: barRoot.fgColor
            isOpen: barRoot.activePanel === "brightness"

            onClicked: {
                let mapped = brightnessWidget.mapToItem(barRoot.parent, 0, 0);
                barRoot.brightnessClicked(mapped.x + brightnessWidget.width / 2);
            }
        }

        // --- POWER WIDGET ---
        Text {
            id: powerWidget
            readonly property bool isOpen: barRoot.activePanel === "power"
            text: isOpen ? barRoot.chevron : "⏻"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: isOpen ? 22 : 25
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    let mapped = powerWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.powerClicked(mapped.x + powerWidget.width / 2);
                }
            }
        }
    }
}
