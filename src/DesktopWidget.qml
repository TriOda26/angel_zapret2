import QtQuick
import qs.config
import qs.services
import qs.widgets
import "."

Item {
    id: root

    property var plugin
    property string screenName
    property var widget

    readonly property bool mac: Skin.macWidgets && !Theme.hell
    readonly property bool hell: Theme.hell
    readonly property color ink: hell ? Theme.hellText : Skin.text
    readonly property color dim: hell ? Theme.hellTextDim : Skin.textDim
    readonly property color hot: hell ? Theme.hellFlame : Skin.accent

    implicitWidth: Math.max(col.implicitWidth, Skin.px(180))
    implicitHeight: col.implicitHeight

    Component.onCompleted: {
        Zapret.attach(plugin);
        Zapret.start();
    }
    onPluginChanged: Zapret.attach(plugin)

    Column {
        id: col
        anchors.centerIn: parent
        spacing: Skin.px(6)

        PxText {
            visible: root.mac
            text: "zapret2"
            kind: "tiny"
            color: root.dim
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Skin.px(8)

            AppleIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: Skin.px(30)
                on: Zapret.active
                bad: Zapret.failed
                bitten: Zapret.active
                growTick: Zapret.growTick
                mac: root.mac
                ink: root.ink
                screenName: root.screenName
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Skin.px(1)

                PxText {
                    text: Zapret.statusText
                    kind: "title"
                    color: Zapret.failed ? Skin.danger : Zapret.active ? root.hot : root.ink
                }
                PxText {
                    text: Zapret.profileLabelText
                    kind: "tiny"
                    color: root.dim
                }
            }
        }
        PxText {
            width: Skin.px(170)
            text: Zapret.statusHint
            kind: "tiny"
            color: root.dim
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Skin.px(5)

            PxButton {
                compact: true
                icon: Zapret.busy ? "" : Zapret.active ? "pause" : "play"
                text: Zapret.busy ? "…" : Zapret.active ? I18n.t("Выключить", "Stop") : I18n.t("Включить", "Start")
                accent: !Zapret.active
                hell: root.hell
                enabled: Zapret.installed && !Zapret.busy
                onClicked: Zapret.toggle()
            }
            PxButton {
                compact: true
                icon: "refresh"
                hell: root.hell
                enabled: Zapret.installed && !Zapret.busy
                onClicked: Zapret.restart()
            }
        }
    }
}
