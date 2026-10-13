// bar/horizontaal/BluetoothPanel.qml
// Native Quickshell.Bluetooth (BlueZ) - no Rust backend needed
import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Item {
    id: root

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color lineColor: "#20ffffff"
    property string fontFamily: "mononoki"
    property string iconFont: "JetBrainsMono Nerd Font Mono"

    // ------------------------------------------------------------------
    // State
    // ------------------------------------------------------------------
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter ? adapter.enabled : false

    property var entries: []
    property string _sig: ""

    property string connectingAddr: ""
    property string failedAddr: ""
    property bool sawConnecting: false
    property int retries: 0

    // ------------------------------------------------------------------
    // Height
    // ------------------------------------------------------------------
    readonly property real contentH: layoutRoot.anchors.margins * 2 + headerRow.implicitHeight + layoutRoot.spacing + mainColumn.implicitHeight
    readonly property real neededHeight: Math.min(600, Math.max(150, contentH))

    implicitHeight: neededHeight
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    function labelOf(d) {
        return String(d.name || d.deviceName || "").trim();
    }

    function isNamed(d) {
        const n = labelOf(d);
        if (n === "")
            return false;
        return !/^([0-9a-f]{2}[-:]){5}[0-9a-f]{2}$/i.test(n);
    }

    function iconFor(d) {
        const i = String(d.icon || "").toLowerCase();
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0 || i.indexOf("audio") >= 0)
            return "\udb80\udecb";
        if (i.indexOf("keyboard") >= 0)
            return "\udb80\udf0c";
        if (i.indexOf("mouse") >= 0)
            return "\udb80\udf7d";
        if (i.indexOf("gaming") >= 0 || i.indexOf("joystick") >= 0)
            return "\udb80\udeb4";
        if (i.indexOf("phone") >= 0)
            return "\udb80\udff2";
        if (i.indexOf("computer") >= 0 || i.indexOf("laptop") >= 0)
            return "\udb80\udf79";
        return "\udb80\udcaf";
    }

    function scheduleRebuild() {
        Qt.callLater(root.rebuild);
    }

    function rebuild() {
        const devs = adapter ? adapter.devices.values : [];
        const conn = [], known = [], avail = [];

        for (let i = 0; i < devs.length; i++) {
            const d = devs[i];
            if (!d)
                continue;
            if (d.connected) {
                conn.push(d);
            } else if (isNamed(d)) {
                if (d.paired || d.trusted)
                    known.push(d);
                else
                    avail.push(d);
            }
        }

        const byName = (a, b) => labelOf(a).toLowerCase().localeCompare(labelOf(b).toLowerCase());
        conn.sort(byName);
        known.sort(byName);
        avail.sort(byName);

        const out = [];
        if (!powered) {
            out.push({
                type: "empty",
                text: adapter ? "Bluetooth is off" : "No adapter found"
            });
        } else {
            if (conn.length) {
                out.push({
                    type: "header",
                    title: "Connected"
                });
                conn.forEach(d => out.push({
                        type: "device",
                        kind: "connected",
                        dev: d
                    }));
            }
            if (known.length) {
                out.push({
                    type: "header",
                    title: "Paired"
                });
                known.forEach(d => out.push({
                        type: "device",
                        kind: "known",
                        dev: d
                    }));
            }
            if (avail.length) {
                out.push({
                    type: "header",
                    title: "Available"
                });
                avail.forEach(d => out.push({
                        type: "device",
                        kind: "available",
                        dev: d
                    }));
            }
            if (out.length === 0)
                out.push({
                    type: "empty",
                    text: "Searching for devices..."
                });
        }

        const sig = out.map(e => e.type + (e.title || e.text || "") + (e.dev ? e.kind + e.dev.address : "")).join("|");
        if (sig !== _sig) {
            _sig = sig;
            entries = out;
        }
    }

    // ------------------------------------------------------------------
    // Scanning — altijd aan zolang het paneel zichtbaar is
    // ------------------------------------------------------------------
    function startScan() {
        if (adapter && powered)
            adapter.discovering = true;
    }

    function stopScan() {
        if (adapter && adapter.discovering)
            adapter.discovering = false;
    }

    function togglePower() {
        if (!adapter)
            return;
        adapter.enabled = !adapter.enabled;
    }

    function connectDevice(d) {
        if (!d || d.connected)
            return;
        failedAddr = "";
        retries = 0;
        sawConnecting = false;
        connectingAddr = d.address;
        connectTimeout.restart();
        if (!d.paired) {
            d.trusted = true;
            d.pair();
        } else {
            if (!d.trusted)
                d.trusted = true;
            d.connect();
        }
    }

    function disconnectDevice(d) {
        if (d)
            d.disconnect();
    }

    function forgetDevice(d) {
        if (d)
            d.forget();
    }

    function toggleAirpodsPanel() {
        airpodsProcess.running = false;
        airpodsProcess.running = true;
    }

    Process {
        id: airpodsProcess
        command: ["noctalia", "msg", "panel-toggle", "harveywuk/airpods:panel"]
    }

    // ------------------------------------------------------------------
    // Wiring
    // ------------------------------------------------------------------
    Component.onCompleted: {
        rebuild();
        startScan();
    }

    onAdapterChanged: {
        scheduleRebuild();
        startScan();
    }

    onPoweredChanged: {
        scheduleRebuild();
        if (powered)
            startScan();
    }

    onVisibleChanged: {
        if (visible)
            startScan();
        else
            stopScan();
    }

    Connections {
        target: root.adapter ? root.adapter.devices : null
        function onValuesChanged() {
            root.scheduleRebuild();
        }
    }

    Instantiator {
        model: root.adapter ? root.adapter.devices : null
        delegate: Connections {
            required property var modelData
            target: modelData

            function onConnectedChanged() {
                if (modelData.connected && root.connectingAddr === modelData.address) {
                    root.connectingAddr = "";
                    connectTimeout.stop();
                }
                root.scheduleRebuild();
            }

            function onPairedChanged() {
                if (modelData.paired && root.connectingAddr === modelData.address && !modelData.connected) {
                    modelData.trusted = true;
                    modelData.connect();
                }
                root.scheduleRebuild();
            }

            function onStateChanged() {
                if (root.connectingAddr !== modelData.address)
                    return;
                if (modelData.state === BluetoothDeviceState.Connecting) {
                    root.sawConnecting = true;
                } else if (modelData.state === BluetoothDeviceState.Disconnected && root.sawConnecting && !modelData.connected) {
                    root.sawConnecting = false;
                    if (root.retries < 1) {
                        root.retries++;
                        Qt.callLater(function () {
                            modelData.connect();
                        });
                    } else {
                        root.failedAddr = modelData.address;
                        root.connectingAddr = "";
                        connectTimeout.stop();
                        failTimer.restart();
                    }
                }
            }

            function onTrustedChanged() {
                root.scheduleRebuild();
            }
            function onNameChanged() {
                root.scheduleRebuild();
            }
            function onDeviceNameChanged() {
                root.scheduleRebuild();
            }
        }
        onObjectAdded: root.scheduleRebuild()
        onObjectRemoved: root.scheduleRebuild()
    }

    Timer {
        id: connectTimeout
        interval: 20000
        repeat: false
        onTriggered: {
            if (root.connectingAddr !== "") {
                root.failedAddr = root.connectingAddr;
                root.connectingAddr = "";
                failTimer.restart();
            }
        }
    }

    Timer {
        id: failTimer
        interval: 4000
        repeat: false
        onTriggered: root.failedAddr = ""
    }

    // ------------------------------------------------------------------
    // UI
    // ------------------------------------------------------------------
    ColumnLayout {
        id: layoutRoot
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Bluetooth"
                color: root.fgColor
                font.family: root.fontFamily
                font.pixelSize: 24
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: root.powered ? "Enabled" : "Disabled"
                color: powerMa.containsMouse ? root.fgColor : (root.powered ? root.accentColor : root.dimColor)
                font.family: root.fontFamily
                font.pixelSize: 18

                MouseArea {
                    id: powerMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.togglePower()
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: mainColumn.implicitHeight
            interactive: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: mainColumn
                width: parent.width
                spacing: 0

                Repeater {
                    model: root.entries

                    delegate: ColumnLayout {
                        id: entry
                        required property var modelData

                        readonly property bool isHeader: modelData.type === "header"
                        readonly property bool isEmpty: modelData.type === "empty"
                        readonly property bool isDevice: modelData.type === "device"
                        readonly property var d: isDevice ? modelData.dev : null
                        readonly property string kind: isDevice ? modelData.kind : ""

                        readonly property bool busy: d ? (root.connectingAddr === d.address || d.state === BluetoothDeviceState.Connecting || d.pairing === true) : false
                        readonly property bool failed: d ? root.failedAddr === d.address : false
                        readonly property bool isAirpods: d ? root.labelOf(d).toLowerCase().indexOf("airpods") >= 0 : false

                        Layout.fillWidth: true
                        spacing: 0

                        // Section header
                        Text {
                            visible: entry.isHeader
                            text: entry.isHeader ? entry.modelData.title : ""
                            color: root.dimColor
                            font.family: root.fontFamily
                            font.pixelSize: 15
                            font.capitalization: Font.AllUppercase
                            Layout.fillWidth: true
                            Layout.topMargin: 10
                            Layout.bottomMargin: 8
                        }

                        // Empty / info text
                        Text {
                            visible: entry.isEmpty
                            text: entry.isEmpty ? entry.modelData.text : ""
                            color: root.dimColor
                            font.family: root.fontFamily
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.topMargin: 10
                            Layout.bottomMargin: 10
                        }

                        // Device row
                        Item {
                            visible: entry.isDevice
                            Layout.fillWidth: true
                            implicitHeight: entry.isDevice ? devRow.implicitHeight + 18 : 0

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        if (entry.isAirpods)
                                            root.toggleAirpodsPanel();
                                    } else if (entry.d && !entry.d.connected && !entry.busy) {
                                        root.connectDevice(entry.d);
                                    }
                                }
                            }

                            RowLayout {
                                id: devRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                Text {
                                    text: entry.d ? root.iconFor(entry.d) : ""
                                    color: entry.kind === "connected" ? root.accentColor : root.fgColor
                                    font.family: root.iconFont
                                    font.pixelSize: 22
                                }

                                Text {
                                    text: entry.d ? root.labelOf(entry.d) : ""
                                    color: root.fgColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 18
                                    font.bold: entry.kind === "connected"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    visible: entry.d && entry.d.batteryAvailable === true
                                    text: entry.d && entry.d.batteryAvailable ? Math.round(entry.d.battery * 100) + "%" : ""
                                    color: root.dimColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 15
                                }

                                Text {
                                    visible: entry.busy
                                    text: "Connecting..."
                                    color: root.dimColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 16
                                }

                                Text {
                                    visible: entry.failed && !entry.busy
                                    text: "Failed"
                                    color: "#ff5555"
                                    font.family: root.fontFamily
                                    font.pixelSize: 16
                                }

                                Text {
                                    visible: entry.kind === "connected"
                                    text: "Disconnect"
                                    color: discMa.containsMouse ? root.fgColor : root.dimColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 16

                                    MouseArea {
                                        id: discMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: root.disconnectDevice(entry.d)
                                    }
                                }

                                Text {
                                    visible: entry.kind === "known"
                                    text: "Forget"
                                    color: forgetMa.containsMouse ? "#ff5555" : root.dimColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 16

                                    MouseArea {
                                        id: forgetMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: root.forgetDevice(entry.d)
                                    }
                                }

                                Text {
                                    visible: (entry.kind === "known" || entry.kind === "available") && !entry.busy
                                    text: entry.kind === "available" ? "Pair" : "Connect"
                                    color: connMa.containsMouse ? root.fgColor : root.accentColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 16

                                    MouseArea {
                                        id: connMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: root.connectDevice(entry.d)
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            visible: entry.isDevice
                            Layout.fillWidth: true
                            height: 1
                            color: root.lineColor
                        }
                    }
                }
            }
        }
    }
}
