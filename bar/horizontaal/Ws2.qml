import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

RowLayout {
    id: wsRow
    spacing: 8

    Layout.alignment: Qt.AlignVCenter

    property int persistentCount: 9

    Repeater {
        model: wsRow.persistentCount
        delegate: Rectangle {
            id: pill
            required property int index
            property int wsId: index + 1

            property string displayText: wsId === 10 ? "0" : wsId.toString()

            property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId

            property bool hasWindows: {
                if (!Hyprland.toplevels)
                    return false;
                return Hyprland.toplevels.values.some(t => t.workspace && t.workspace.id === wsId);
            }

            property bool hovered: false

            implicitWidth: 20.45
            implicitHeight: 19
            radius: 4

            Layout.alignment: Qt.AlignVCenter

            color: {
                if (isActive) {
                    return Qt.rgba(255, 255, 255, 0.20);
                } else if (hovered) {
                    return Qt.rgba(255, 255, 255, 0.15);
                } else if (hasWindows) {
                    return Qt.rgba(255, 255, 255, 0.10);
                } else {
                    return "transparent";
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }

            Text {
                anchors.centerIn: parent
                text: pill.displayText
                font.pixelSize: 17

                color: pill.isActive ? "#fff7e5" : Qt.rgba(255, 255, 255, 0.40)

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: pill.hovered = true
                onExited: pill.hovered = false

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        dispatchProcess.command = ["hyprctl", "dispatch", "hl.dsp.focus({workspace = " + pill.wsId.toString() + "})"];
                        dispatchProcess.running = true;
                    } else if (mouse.button === Qt.RightButton) {
                        dispatchProcess.command = ["hyprctl", "dispatch", "hl.dsp.window.move({workspace = " + pill.wsId.toString() + "})"];
                        dispatchProcess.running = true;
                    }
                }
            }

            Process {
                id: dispatchProcess
            }
        }
    }
}
