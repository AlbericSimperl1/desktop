// bar/horizontaal/NotificationPanel.qml
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#b3fff7e5"
    property color lineColor: "#2effffff"
    property color cardColor: "#12ffffff"
    property color highlightColor: '#7ffff6e3'
    property color dangerColor: "#ff5f5f"
    property string fontFamily: "mononoki"
    property string iconFont: "JetBrainsMono Nerd Font Mono"

    signal closeRequested

    // Nerd Font (Material Design) glyphs as surrogate pairs
    readonly property string icTrash: "\udb80\uddb4"
    readonly property string icBell: "\udb80\udc9a"
    readonly property string icBellOff: "\udb80\udc9b"
    readonly property string icClose: "\udb80\udd56"

    property string tab: "all"
    readonly property var tabs: [
        {
            key: "all",
            label: "All"
        },
        {
            key: "today",
            label: "Today"
        },
        {
            key: "yesterday",
            label: "Yesterday"
        },
        {
            key: "older",
            label: "Older"
        }
    ]

    readonly property var items: {
        const ref = Notifications.now;
        const all = Notifications.history;
        if (root.tab === "all")
            return all;
        const out = [];
        for (let i = 0; i < all.length; i++)
            if (Notifications.bucketOf(all[i].time, ref) === root.tab)
                out.push(all[i]);
        return out;
    }

    readonly property real neededHeight: Math.min(600, Math.max(230, layoutRoot.anchors.margins * 2 + headerRow.implicitHeight + tabBar.implicitHeight + layoutRoot.spacing * 2 + listColumn.height + 4))

    ColumnLayout {
        id: layoutRoot
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // ---------------- Header ----------------
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Notifications"
                color: root.fgColor
                font.family: root.fontFamily
                font.pixelSize: 17
                font.bold: true
                Layout.fillWidth: true
            }

            Repeater {
                model: ["clear", "dnd", "close"]

                delegate: Rectangle {
                    id: hb
                    required property string modelData
                    readonly property bool danger: modelData === "clear"
                    readonly property bool active: modelData === "dnd" && Notifications.dndEnabled
                    readonly property string glyph: modelData === "clear" ? root.icTrash : modelData === "dnd" ? (Notifications.dndEnabled ? root.icBellOff : root.icBell) : root.icClose

                    implicitWidth: 32
                    implicitHeight: 32
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 4
                    color: hbMa.containsMouse ? (danger ? "#55ff5f5f" : "#22ffffff") : (active ? "#22f0b840" : "transparent")
                    border.width: 1
                    border.color: hbMa.containsMouse && danger ? root.dangerColor : (active ? root.highlightColor : root.lineColor)

                    Text {
                        anchors.centerIn: parent
                        text: hb.glyph
                        color: hbMa.containsMouse && hb.danger ? root.dangerColor : (hb.active ? root.highlightColor : root.fgColor)
                        font.family: root.iconFont
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: hbMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (hb.modelData === "clear")
                                Notifications.clearAll();
                            else if (hb.modelData === "dnd")
                                Notifications.toggleDnd();
                            else
                                root.closeRequested();
                        }
                    }
                }
            }
        }

        // ---------------- Tabs ----------------
        Rectangle {
            id: tabBar
            Layout.fillWidth: true
            implicitHeight: 38
            Layout.preferredHeight: 38
            color: "transparent"
            border.color: root.lineColor
            border.width: 1
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 0

                Repeater {
                    model: root.tabs

                    delegate: Item {
                        id: tabItem
                        required property var modelData
                        required property int index
                        readonly property bool sel: root.tab === modelData.key

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            color: tabItem.sel ? root.highlightColor : (tabMa.containsMouse ? "#14ffffff" : "transparent")
                        }

                        Rectangle {
                            visible: tabItem.index > 0 && !tabItem.sel && root.tab !== root.tabs[tabItem.index - 1].key
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: parent.height - 14
                            color: root.lineColor
                        }

                        Text {
                            anchors.centerIn: parent
                            text: tabItem.modelData.label
                            color: tabItem.sel ? "#14130e" : root.fgColor
                            font.family: root.fontFamily
                            font.pixelSize: 14
                            font.bold: tabItem.sel
                        }

                        MouseArea {
                            id: tabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tab = tabItem.modelData.key
                        }
                    }
                }
            }
        }

        // ---------------- List ----------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.rightMargin: 8
                clip: true
                contentWidth: width
                contentHeight: listColumn.height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: listColumn
                    width: flick.width
                    spacing: 10

                    Repeater {
                        model: root.items

                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            readonly property var n: modelData
                            readonly property bool expanded: Notifications.expandedKey === n.key
                            readonly property bool hasActions: n.actions !== undefined && n.actions.length > 0

                            width: listColumn.width
                            implicitHeight: cardCol.implicitHeight + 24
                            height: implicitHeight
                            radius: 6
                            color: cardMa.containsMouse ? "#1affffff" : root.cardColor
                            border.width: 1
                            border.color: n.urgency === 2 ? root.dangerColor : root.lineColor

                            MouseArea {
                                id: cardMa
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton)
                                        Notifications.invokeDefault(card.n.key);
                                    else
                                        Notifications.toggleExpand(card.n.key);
                                }
                            }

                            Column {
                                id: cardCol
                                x: 12
                                y: 12
                                width: parent.width - 24
                                spacing: 8

                                // header row: icon, app • time, delete
                                RowLayout {
                                    width: parent.width
                                    height: 36
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: 6
                                        color: "#40000000"
                                        clip: true

                                        Image {
                                            id: appImg
                                            anchors.fill: parent
                                            anchors.margins: 3
                                            source: card.n.icon
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            sourceSize.width: 72
                                            sourceSize.height: 72
                                            visible: status === Image.Ready
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: appImg.status !== Image.Ready
                                            text: root.icBell
                                            color: root.fgColor
                                            font.family: root.iconFont
                                            font.pixelSize: 20
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        text: (card.n.appName !== "" ? card.n.appName + " • " : "• ") + Notifications.timeAgo(card.n.time, Notifications.now)
                                        color: root.dimColor
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Item {
                                        Layout.preferredWidth: 26
                                        Layout.preferredHeight: 26
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.icTrash
                                            color: delMa.containsMouse ? root.dangerColor : root.dimColor
                                            font.family: root.iconFont
                                            font.pixelSize: 16
                                        }

                                        MouseArea {
                                            id: delMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Notifications.remove(card.n.key)
                                        }
                                    }
                                }

                                // title
                                Text {
                                    visible: card.n.summary !== ""
                                    width: parent.width
                                    text: card.n.summary
                                    color: root.fgColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 14
                                    font.bold: true
                                    wrapMode: Text.Wrap
                                    maximumLineCount: card.expanded ? 20 : 2
                                    elide: Text.ElideRight
                                }

                                // body
                                Text {
                                    visible: card.n.body !== ""
                                    width: parent.width
                                    text: card.n.body
                                    color: root.dimColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 13
                                    wrapMode: Text.Wrap
                                    maximumLineCount: card.expanded ? 1000 : 3
                                    elide: Text.ElideRight
                                }

                                // actions
                                RowLayout {
                                    visible: card.hasActions
                                    width: parent.width
                                    spacing: 8

                                    Repeater {
                                        model: card.hasActions ? card.n.actions : []

                                        delegate: Rectangle {
                                            id: actBtn
                                            required property var modelData
                                            visible: modelData.text !== ""
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 30
                                            radius: 4
                                            color: actMa.containsMouse ? "#22ffffff" : "transparent"
                                            border.width: 1
                                            border.color: actMa.containsMouse ? root.highlightColor : root.lineColor

                                            Text {
                                                anchors.centerIn: parent
                                                width: parent.width - 12
                                                horizontalAlignment: Text.AlignHCenter
                                                text: actBtn.modelData.text
                                                color: actMa.containsMouse ? root.highlightColor : root.fgColor
                                                font.family: root.fontFamily
                                                font.pixelSize: 13
                                                elide: Text.ElideRight
                                            }

                                            MouseArea {
                                                id: actMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Notifications.invoke(card.n.key, actBtn.modelData.identifier)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // empty state
                    Item {
                        visible: root.items.length === 0
                        width: listColumn.width
                        height: 170

                        Column {
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.icBell
                                color: root.dimColor
                                font.family: root.iconFont
                                font.pixelSize: 38
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No notifications"
                                color: root.dimColor
                                font.family: root.fontFamily
                                font.pixelSize: 16
                            }
                        }
                    }
                }
            }

            // scrollbar
            Rectangle {
                visible: flick.contentHeight > flick.height + 1
                x: parent.width - 4
                y: flick.visibleArea.yPosition * flick.height
                width: 3
                height: Math.max(24, flick.visibleArea.heightRatio * flick.height)
                radius: 2
                color: "#55ffffff"
            }
        }
    }
}
