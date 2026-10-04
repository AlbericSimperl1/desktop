// MediaPanel.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Qt5Compat.GraphicalEffects

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 570

    property color fgColor: "#fff7e5"
    property color mutedColor: Qt.rgba(1, 0.95, 0.82, 0.78)
    property color accentColor: "#ebd9b9"
    property color cavaColor: "#bbbbbb"
    property string fontFamily: "mononoki"
    property var player
    property var cavaBars: []

    // -------------------------------------------------------------
    // PIPEWIRE AUDIO OUTPUT DEVICE
    // -------------------------------------------------------------
    readonly property string audioDeviceName: {
        const sink = Pipewire.defaultAudioSink;
        if (!sink)
            return "Default Output";
        return sink.description || sink.nickname || sink.name || "Default Output";
    }

    // -------------------------------------------------------------
    // MPRIS LOGICA
    // -------------------------------------------------------------
    readonly property var ignoredPlayers: ["zen-browser", "firefox", "youtube"]

    readonly property var activePlayer: {
        const players = Mpris.players.values || [];
        let fallback = null;
        for (let i = 0; i < players.length; i++) {
            const p = players[i];
            if (!p)
                continue;
            const id = ((p.identity || "") + " " + (p.desktopEntry || "") + " " + (p.dbusName || "")).toLowerCase();
            if (ignoredPlayers.some(name => id.includes(name)))
                continue;
            if (p.isPlaying)
                return p;
            if (!fallback && p.playbackState !== MprisPlaybackState.Stopped)
                fallback = p;
        }
        return fallback;
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.isPlaying
    readonly property string trackTitle: hasPlayer && activePlayer.trackTitle ? activePlayer.trackTitle : "No media playing"
    readonly property string trackArtist: hasPlayer && activePlayer.trackArtist ? activePlayer.trackArtist : "Unknown or no artist"
    readonly property string artUrl: hasPlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""
    readonly property real trackLength: hasPlayer && activePlayer.lengthSupported ? Math.max(0, activePlayer.length) : 0
    readonly property bool canSeek: hasPlayer && activePlayer.canSeek && trackLength > 0
    property real trackPosition: 0

    // -------------------------------------------------------------
    // BAR ICON COMPONENT
    // -------------------------------------------------------------
    property Component barItem: Component {
        Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 6
            color: "transparent"
            clip: true

            Image {
                id: barArt
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready && root.artUrl !== ""
            }

            Text {
                anchors.centerIn: parent
                visible: !barArt.visible
                text: "\uf001"
                color: root.fgColor
                font.family: root.fontFamily
                font.pixelSize: 14
            }
        }
    }

    function syncPosition() {
        if (!activePlayer || !activePlayer.positionSupported) {
            trackPosition = 0;
            return;
        }
        trackPosition = Math.max(0, activePlayer.position);
    }

    Timer {
        interval: 500
        repeat: true
        running: root.hasPlayer
        onTriggered: {
            if (root.isPlaying && root.trackLength > 0)
                root.trackPosition = Math.min(root.trackLength, root.trackPosition + 0.5);
            else
                root.syncPosition();
        }
    }

    Connections {
        target: root.activePlayer
        enabled: root.activePlayer !== null
        function onPositionChanged() {
            root.syncPosition();
        }
        function onTrackTitleChanged() {
            root.syncPosition();
        }
    }

    // -------------------------------------------------------------
    // CAVA PROCESS INTEGRATIE
    // -------------------------------------------------------------
    Process {
        id: cavaProc
        running: root.isPlaying
        command: ["bash", "-lc", "cfg=$(mktemp); " + "printf '%s\\n' '[general]' 'bars = 86' 'framerate = 60' 'sensitivity = 160' " + "'[input]' 'method = pipewire' '[output]' 'method = raw' 'raw_target = /dev/stdout' " + "'data_format = ascii' 'ascii_max_range = 12' 'bar_delimiter = 59' 'frame_delimiter = 10' 'channels = mono' " + "'[smoothing]' 'integral = 70' 'monstercat = 1' > \"$cfg\"; " + "cava -p \"$cfg\"; code=$?; rm -f \"$cfg\"; exit $code"]

        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(";");
                const vals = [];
                for (let i = 0; i < parts.length; i++) {
                    const v = parseInt(parts[i]);
                    vals.push(isNaN(v) ? 0 : Math.max(0, Math.min(1, v / 12)));
                }
                root.cavaBars = vals;
            }
        }
    }

    // -------------------------------------------------------------
    // HOOFDINDELING
    // -------------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 16

        // LINKER KOLOM: Media Bediening & Artwork
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            // Album Art
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 335
                Layout.preferredHeight: 335

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 5
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: albumArt
                    maskSource: maskRect
                    visible: albumArt.status === Image.Ready && root.artUrl !== ""
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: "#1a1b26"
                    visible: albumArt.status !== Image.Ready || root.artUrl === ""

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: root.mutedColor
                        font.pixelSize: 32
                    }
                }
            }

            // Track Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.trackTitle
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 22
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.trackArtist
                        color: root.mutedColor
                        font.family: root.fontFamily
                        font.pixelSize: 16
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: root.formatTime(root.trackPosition) + " / " + root.formatTime(root.trackLength)
                        color: root.mutedColor
                        font.family: root.fontFamily
                        font.pixelSize: 18
                    }
                }
            }

            // Item {
            //     Layout.fillHeight: true
            // }

            // Progress Bar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: "#22ffffff"

                Rectangle {
                    height: parent.height
                    width: root.trackLength > 0 ? parent.width * (root.trackPosition / root.trackLength) : 0
                    radius: 2
                    color: root.accentColor
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.canSeek
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (root.activePlayer && root.canSeek) {
                            root.activePlayer.position = (mouse.x / width) * root.trackLength;
                            root.syncPosition();
                        }
                    }
                }
            }

            // Knoppenbalk (Aangepast: negatieve topMargin trekt de knoppen omhoog richting de progress bar)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -32
                spacing: 0

                // Shuffle
                Text {
                    text: "\uf074"
                    color: (root.activePlayer && root.activePlayer.shuffle) ? root.accentColor : "#888888"
                    opacity: (root.activePlayer && root.activePlayer.canControl && root.activePlayer.shuffleSupported) ? 1 : 0.35
                    font.family: root.fontFamily
                    font.pixelSize: 42
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: (root.activePlayer && root.activePlayer.canControl && root.activePlayer.shuffleSupported) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (root.activePlayer && root.activePlayer.canControl && root.activePlayer.shuffleSupported)
                            root.activePlayer.shuffle = !root.activePlayer.shuffle
                    }
                }

                // Vorige nummer
                Text {
                    text: "\uf048"
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 85
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 30

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer)
                            root.activePlayer.previous()
                    }
                }

                // Play / Pause
                Text {
                    text: root.isPlaying ? "\uf04c" : "\uf04b"
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 100
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 35

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer)
                            root.activePlayer.togglePlaying()
                    }
                }

                // Volgende nummer
                Text {
                    text: "\uf051"
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 85
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 35
                    Layout.rightMargin: 30

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer)
                            root.activePlayer.next()
                    }
                }

                // Herhalen
                Text {
                    text: "\uf01e"
                    color: (root.activePlayer && root.activePlayer.loopState !== MprisLoopState.None) ? root.accentColor : "#888888"
                    opacity: (root.activePlayer && root.activePlayer.canControl && root.activePlayer.loopSupported) ? 1 : 0.35
                    font.family: root.fontFamily
                    font.pixelSize: 40
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 0

                    Text {
                        text: "1"
                        visible: root.activePlayer && root.activePlayer.loopState === MprisLoopState.Track
                        color: root.accentColor
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -7
                        anchors.bottomMargin: 8
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: (root.activePlayer && root.activePlayer.canControl && root.activePlayer.loopSupported) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (!root.activePlayer || !root.activePlayer.canControl || !root.activePlayer.loopSupported)
                                return;
                            if (root.activePlayer.loopState === MprisLoopState.None)
                                root.activePlayer.loopState = MprisLoopState.Playlist;
                            else if (root.activePlayer.loopState === MprisLoopState.Playlist)
                                root.activePlayer.loopState = MprisLoopState.Track;
                            else
                                root.activePlayer.loopState = MprisLoopState.None;
                        }
                    }
                }
            }

            // Audio Output Device Badge (Aangepast: dichter op de knoppen + grotere dimensions & font)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -27
                implicitWidth: deviceRow.implicitWidth + 30
                implicitHeight: deviceRow.implicitHeight + 12
                radius: 5
                color: "#20ffffff"
                border.color: "#30ffffff"
                border.width: 1

                RowLayout {
                    id: deviceRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "\uf028"
                        color: root.accentColor
                        font.family: root.fontFamily
                        font.pixelSize: 20
                    }

                    Text {
                        text: root.audioDeviceName
                        color: root.fgColor
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.maximumWidth: 300
                    }
                }
            }
        }

        // RECHTER KOLOM: CAVA Visualizer
        Item {
            Layout.preferredWidth: 85
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: 78

                    delegate: Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter

                        property real distFromCenter: Math.abs(index - 40.5)
                        property int mappedIdx: Math.min(81, Math.floor(distFromCenter * 2))

                        property real val: (root.cavaBars && root.cavaBars.length > mappedIdx) ? root.cavaBars[mappedIdx] : 0

                        width: Math.max(8, val * 85)
                        height: 3
                        radius: 1.5
                        color: root.cavaColor
                        opacity: 0.25 + (val * 0.75)
                    }
                }
            }
        }
    }
}
