// modules/components/Clock.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15

RowLayout {
    id: clockRoot

    property color fgColor: "#fff7e5"
    property color mutedColor: Qt.rgba(1, 0.95, 0.82, 0.78)
    property string fontFamily: "mononoki"
    property int fs: 20

    spacing: 8
    Layout.alignment: Qt.AlignVCenter

    // Tijd in HH:mm formaat (24-uursweergave)
    readonly property string timeStr: Qt.formatDateTime(clockTimer.currentDate, "HH:mm")

    // Datum in 'dag d maand' formaat (gebruik "dddd d MMMM" voor voluit geschreven namen)
    readonly property string dateStr: Qt.formatDateTime(clockTimer.currentDate, "  ddd d MMM").toUpperCase()

    Text {
        text: clockRoot.timeStr
        color: clockRoot.fgColor
        font.family: clockRoot.fontFamily
        font.pixelSize: fs
        font.weight: 600
        font.bold: true
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: clockRoot.dateStr
        color: clockRoot.fgColor
        font.family: clockRoot.fontFamily
        font.pixelSize: fs
        font.weight: 600
        Layout.alignment: Qt.AlignVCenter
    }

    Timer {
        id: clockTimer
        property date currentDate: new Date()
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentDate = new Date()
    }
}
