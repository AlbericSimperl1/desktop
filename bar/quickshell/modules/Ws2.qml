import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

ColumnLayout {
    id: wsColumn
    spacing: 6
    Layout.alignment: Qt.AlignHCenter

    // 10 workspaces (1 t/m 9 en 0) zoals op de afbeelding
    property int persistentCount: 6

    Repeater {
        model: wsColumn.persistentCount
        delegate: Rectangle {
            id: pill
            required property int index
            property int wsId: index + 1

            // Nummering weergeven: 1 t/m 9, en '0' voor de 10e workspace
            property string displayText: wsId === 10 ? "0" : wsId.toString()

            // 1. Is dit de actieve workspace?
            property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId

            // 2. Staan er geopende vensters op dit werkblad?
            property bool hasWindows: {
                if (!Hyprland.toplevels)
                    return false;
                return Hyprland.toplevels.values.some(t => t.workspace && t.workspace.id === wsId);
            }

            property bool hovered: false

            // Vierkante afgeronde knopjes
            implicitWidth: 18
            implicitHeight: 22
            radius: 6

            Layout.alignment: Qt.AlignHCenter

            color: {
                if (isActive) {
                    return Qt.rgba(0, 0, 0, 0.50); // Actieve achtergrond
                } else if (hovered) {
                    return Qt.rgba(0, 0, 0, 0.35);
                } else if (hasWindows) {
                    return Qt.rgba(0, 0, 0, 0.20); // Achtergrond voor geopende vensters
                } else {
                    return "transparent"; // Geen box voor lege workspaces
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }

            // Het nummer in de workspace
            Text {
                anchors.centerIn: parent
                text: pill.displayText
                font.pixelSize: 13
                // font.bold: true

                color: {
                    if (pill.isActive) {
                        return "#fff7e5";
                    } else {
                        return "#d8dee9";
                    }
                }

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
