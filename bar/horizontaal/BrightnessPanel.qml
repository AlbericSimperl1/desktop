// quickshell/modules/panels/BrightnessPanel.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Io

Item {
    id: brightnessPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color lineColor: "#20ffffff"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    readonly property real neededHeight: 210

    property int currentBrightness: 50
    property bool nightlightActive: false
    property bool scheduleActive: false

    // Haalt initiële brightness percentage op via brightnessctl
    Process {
        id: brightnessProcess
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                let val = parseInt(line.trim());
                if (!isNaN(val)) {
                    brightnessPanelRoot.currentBrightness = val;
                }
            }
        }
    }

    function setBrightness(value) {
        let clamped = Math.max(0, Math.min(100, Math.round(value)));
        currentBrightness = clamped;
        Quickshell.execDetached(["noctalia", "msg", "brightness-set", clamped.toString()]);
    }

    function toggleForceNightlight() {
        nightlightActive = !nightlightActive;
        Quickshell.execDetached(["noctalia", "msg", "nightlight-force-toggle"]);
    }

    function toggleScheduleNightlight() {
        scheduleActive = !scheduleActive;
        let cmd = scheduleActive ? "nightlight-enable" : "nightlight-disable";
        Quickshell.execDetached(["noctalia", "msg", cmd]);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // --- TITLE ---
        Text {
            text: "Display & Night Light"
            color: brightnessPanelRoot.fgColor
            font.family: brightnessPanelRoot.fontFamily
            font.pixelSize: 22
            font.bold: true
            Layout.fillWidth: true
        }

        // --- BRIGHTNESS SLIDER ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰃠"
                    color: brightnessPanelRoot.accentColor
                    font.family: brightnessPanelRoot.fontFamily
                    font.pixelSize: 18
                }

                Text {
                    text: "Helderheid"
                    color: brightnessPanelRoot.fgColor
                    font.family: brightnessPanelRoot.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: brightnessPanelRoot.currentBrightness + "%"
                    color: brightnessPanelRoot.dimColor
                    font.family: brightnessPanelRoot.fontFamily
                    font.pixelSize: 14
                }
            }

            // Custom Slider Track
            Rectangle {
                id: sliderTrack
                Layout.fillWidth: true
                height: 12
                color: "#15ffffff"
                border.color: brightnessPanelRoot.lineColor
                border.width: 1

                Rectangle {
                    width: parent.width * (brightnessPanelRoot.currentBrightness / 100.0)
                    height: parent.height
                    color: brightnessPanelRoot.accentColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    function updateFromMouse(mouse) {
                        let pct = Math.max(0, Math.min(1, mouse.x / width));
                        brightnessPanelRoot.setBrightness(pct * 100);
                    }

                    onPressed: mouse => updateFromMouse(mouse)
                    onPositionChanged: mouse => {
                        if (pressed)
                            updateFromMouse(mouse);
                    }
                    onWheel: wheel => {
                        let step = wheel.angleDelta.y > 0 ? 5 : -5;
                        brightnessPanelRoot.setBrightness(brightnessPanelRoot.currentBrightness + step);
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: brightnessPanelRoot.lineColor
            Layout.topMargin: 4
            Layout.bottomMargin: 4
        }

        // --- NIGHT LIGHT CONTROLS ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Night Light"
                color: brightnessPanelRoot.dimColor
                font.family: brightnessPanelRoot.fontFamily
                font.pixelSize: 12
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // 1. FORCE TOGGLE (Handmatige override)
                Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    radius: 0
                    color: brightnessPanelRoot.nightlightActive ? "#33ffffff" : "transparent"
                    border.color: brightnessPanelRoot.nightlightActive ? brightnessPanelRoot.accentColor : brightnessPanelRoot.lineColor
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: brightnessPanelRoot.nightlightActive ? "󰽥" : "󰃞"
                            color: brightnessPanelRoot.nightlightActive ? brightnessPanelRoot.accentColor : brightnessPanelRoot.fgColor
                            font.family: brightnessPanelRoot.fontFamily
                            font.pixelSize: 20
                        }

                        Text {
                            text: brightnessPanelRoot.nightlightActive ? "Forced On" : "Forced Off"
                            color: brightnessPanelRoot.nightlightActive ? brightnessPanelRoot.accentColor : brightnessPanelRoot.fgColor
                            font.family: brightnessPanelRoot.fontFamily
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: brightnessPanelRoot.toggleForceNightlight()
                    }
                }

                // 2. SCHEDULE TOGGLE (nightlight-enable vs nightlight-disable)
                Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    radius: 0
                    color: brightnessPanelRoot.scheduleActive ? "#33ffffff" : "transparent"
                    border.color: brightnessPanelRoot.scheduleActive ? brightnessPanelRoot.accentColor : brightnessPanelRoot.lineColor
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰔚"
                            color: brightnessPanelRoot.scheduleActive ? brightnessPanelRoot.accentColor : brightnessPanelRoot.fgColor
                            font.family: brightnessPanelRoot.fontFamily
                            font.pixelSize: 20
                        }

                        Text {
                            text: brightnessPanelRoot.scheduleActive ? "Schedule On" : "Schedule Off"
                            color: brightnessPanelRoot.scheduleActive ? brightnessPanelRoot.accentColor : brightnessPanelRoot.fgColor
                            font.family: brightnessPanelRoot.fontFamily
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: brightnessPanelRoot.toggleScheduleNightlight()
                    }
                }
            }
        }
    }
}
