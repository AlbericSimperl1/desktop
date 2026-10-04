import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Wayland

// import "./modules"
// import "./modules/components"
// import "./modules/bar"
// import "./modules/panels"
// import "./modules/services"

ShellRoot {
    id: root

    property bool overviewActive: true

    IpcHandler {
        target: "overview"

        function toggle(): void {
            root.overviewActive = !root.overviewActive;
        }

        function open(): void {
            root.overviewActive = true;
        }

        function close(): void {
            root.overviewActive = false;
        }
    }

    readonly property color barBg: '#00000207'
    readonly property color fg: '#fff7e5'
    readonly property color accent: '#ebd9b9'
    readonly property color borderCol: "#2cffffff"
    readonly property string fontFamily: "mononoki"

    readonly property int barHeight: 34
    readonly property int marginSize: 0
    readonly property int barRadius: 0

    readonly property int panelMaxWidth: 480
    readonly property color panelBg: '#60000207'

    readonly property int panelMaxHeight: 650
    readonly property int panelMinHeight: 140
    readonly property int panelGap: 8
    readonly property int panelRadius: 3

    readonly property var activePlayer: {
        const players = Mpris.players.values;
        if (!players || players.length === 0)
            return null;
        for (let p of players) {
            if (p.playbackState === MprisPlaybackState.Playing)
                return p;
        }
        return players[0];
    }

    Variants {
        model: Quickshell.screens

        NotificationToast {
            screen: modelData
        }

        PanelWindow {
            id: sidebarPanel
            visible: root.overviewActive
            required property var modelData

            property bool popoutOpen: false
            property string activePanel: "none"
            property bool hovered: false

            readonly property real openP: popoutOpen ? 1 : 0
            property real panelLeftX: 120

            onVisibleChanged: {
                if (!visible) {
                    popoutOpen = false;
                    activePanel = "none";
                }
            }

            readonly property real contentNeededHeight: activePanel === "media" ? mediaPanel.implicitHeight : activePanel === "bluetooth" ? bluetoothPanel.neededHeight : activePanel === "notifications" ? notificationPanel.neededHeight : activePanel === "wifi" ? wifiPanel.neededHeight : activePanel === "power" ? powerPanel.neededHeight : 0
            readonly property real panelH: Math.min(root.panelMaxHeight, Math.max(root.panelMinHeight, contentNeededHeight + 16))

            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            margins.top: 0
            margins.bottom: 0
            margins.left: 0
            margins.right: 0

            exclusiveZone: root.barHeight + 2
            implicitHeight: root.barHeight + root.panelGap + root.panelMaxHeight

            anchors {
                top: true
                left: true
                right: true
            }

            mask: Region {
                Region {
                    x: 0
                    y: 0
                    width: sidebarBg.width
                    height: root.barHeight
                }

                Region {
                    x: sidebarPanel.popoutOpen ? sidebarPanel.panelLeftX : 0
                    y: sidebarPanel.popoutOpen ? (root.barHeight + root.panelGap) : 0
                    width: sidebarPanel.popoutOpen ? root.panelMaxWidth : 0
                    height: sidebarPanel.popoutOpen ? sidebarPanel.panelH : 0
                }
            }

            Timer {
                id: closeTimer
                interval: 200
                onTriggered: {
                    if (!sidebarPanel.hovered) {
                        sidebarPanel.popoutOpen = false;
                        sidebarPanel.activePanel = "none";
                    }
                }
            }

            onHoveredChanged: {
                if (hovered)
                    closeTimer.stop();
                else if (popoutOpen)
                    closeTimer.start();
            }

            function togglePanel(type, clickX) {
                if (popoutOpen && activePanel === type) {
                    popoutOpen = false;
                    activePanel = "none";
                    return;
                }

                activePanel = type;

                const inset = root.barRadius + root.panelRadius + 2;
                const maxLeft = sidebarBg.width - inset - root.panelMaxWidth;
                panelLeftX = Math.max(inset, Math.min(clickX - root.panelMaxWidth / 2, maxLeft));
                popoutOpen = true;
            }

            Item {
                id: rootItem
                anchors.fill: parent

                HoverHandler {
                    id: sidebarHover
                    onHoveredChanged: sidebarPanel.hovered = hovered
                }

                Item {
                    id: sidebarBg
                    width: parent.width
                    height: parent.height

                    Rectangle {
                        x: 0
                        y: 0
                        width: parent.width
                        height: root.barHeight
                        color: root.barBg
                        radius: root.barRadius
                        border.color: root.borderCol
                        border.width: 0
                    }

                    SidebarContent {
                        id: sidebar
                        activePlayer: root.activePlayer
                        fontFamily: root.fontFamily
                        fgColor: root.fg
                        isMediaOpen: sidebarPanel.popoutOpen && sidebarPanel.activePanel === "media"

                        onMediaClicked: clickX => sidebarPanel.togglePanel("media", clickX)
                        onBluetoothClicked: clickX => sidebarPanel.togglePanel("bluetooth", clickX)
                        onWifiClicked: clickX => sidebarPanel.togglePanel("wifi", clickX)
                        onNotificationsClicked: clickX => sidebarPanel.togglePanel("notifications", clickX)
                        onPowerClicked: clickX => sidebarPanel.togglePanel("power", clickX)
                    }

                    Rectangle {
                        x: sidebarPanel.panelLeftX
                        y: root.barHeight + root.panelGap
                        width: root.panelMaxWidth
                        height: sidebarPanel.panelH
                        color: root.panelBg
                        radius: root.panelRadius
                        border.color: root.borderCol
                        border.width: 0
                        visible: sidebarPanel.popoutOpen

                        Item {
                            anchors.fill: parent
                            anchors.margins: 8

                            MediaPanel {
                                id: mediaPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "media"
                                player: root.activePlayer
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }

                            BluetoothPanel {
                                id: bluetoothPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "bluetooth"
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }

                            WifiPanel {
                                id: wifiPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "wifi"
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }

                            NotificationPanel {
                                id: notificationPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "notifications"
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }

                            PowerPanel {
                                id: powerPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "power"
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }
                        }
                    }
                }
            }

            BackgroundEffect.blurRegion: Region {
                Region {
                    x: 0
                    y: 0
                    width: sidebarBg.width
                    height: root.barHeight
                }

                Region {
                    x: sidebarPanel.popoutOpen ? sidebarPanel.panelLeftX : 0
                    y: sidebarPanel.popoutOpen ? (root.barHeight + root.panelGap) : 0
                    width: sidebarPanel.popoutOpen ? root.panelMaxWidth : 0
                    height: sidebarPanel.popoutOpen ? sidebarPanel.panelH : 0
                }
            }
        }
    }
}
