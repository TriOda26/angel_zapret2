import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar
import "."

// The apple next to the tray. Pixel: a custom bitmap in a flat PxButton; Mac: a monochrome menu
// bar extra. Left click opens the panel by default; Settings can make it toggle instead.
Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow
    property int hpad: -1
    property bool barInk: false
    property bool hellBar: false

    readonly property bool mac: Skin.mac
    readonly property bool showLabel: plugin ? plugin.get("showLabel", false) : false
    readonly property bool clickToggles: plugin ? plugin.get("clickToggles", false) : false
    readonly property bool barOpen: pop.visible
    readonly property bool hovered: !root.mac && btn.hovered || root.mac && macMouse.containsMouse
    readonly property real pads: root.hpad >= 0 ? root.hpad : Skin.px(6)

    implicitWidth: root.mac ? macRow.implicitWidth + Skin.px(4) : contentRow.implicitWidth + root.pads * 2
    implicitHeight: root.mac ? Skin.px(18) : Math.max(Skin.px(18), Theme.u * 11)

    Component.onCompleted: Zapret.attach(plugin)
    onPluginChanged: Zapret.attach(plugin)

    function firstAction() {
        if (root.clickToggles)
            Zapret.toggle();
        else
            pop.toggle();
    }

    function secondAction() {
        if (root.clickToggles)
            pop.toggle();
        else
            Zapret.toggle();
    }

    PxButton {
        id: btn
        visible: !root.mac
        anchors.fill: parent
        compact: true
        flat: true
        hpad: root.hpad
        barInk: root.barInk
        checked: root.barOpen
        middleButton: true
        Accessible.name: "zapret2"
        onClicked: root.firstAction()
        onRightClicked: root.secondAction()
        onMiddleClicked: Zapret.refresh()
    }

    Row {
        id: contentRow
        visible: !root.mac
        anchors.centerIn: parent
        spacing: Skin.px(4)

        AppleIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: Skin.px(14)
            on: Zapret.active
            bad: Zapret.failed
            bitten: Zapret.active
            growTick: Zapret.growTick
            hellBar: root.hellBar || root.barInk
            barOpen: root.barOpen
            ink: Skin.ink(root.screenName)
            screenName: root.screenName
        }
        PxText {
            visible: root.showLabel
            anchors.verticalCenter: parent.verticalCenter
            text: Zapret.active ? Zapret.profileLabelText : "zap"
            kind: "tiny"
            color: root.hellBar || root.barInk ? (root.barOpen ? Theme.hellAccent : Theme.hellText) : Skin.ink(root.screenName)
        }
    }

    Row {
        id: macRow
        visible: root.mac
        anchors.centerIn: parent
        spacing: Skin.px(4)

        AppleIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: Skin.px(16)
            on: Zapret.active
            bad: Zapret.failed
            bitten: Zapret.active
            growTick: Zapret.growTick
            mac: true
            ink: Skin.ink(root.screenName)
            screenName: root.screenName
        }
        PxText {
            visible: root.showLabel
            anchors.verticalCenter: parent.verticalCenter
            text: Zapret.active ? Zapret.profileLabelText : "zap"
            kind: "tiny"
            color: Skin.ink(root.screenName)
        }
    }

    MouseArea {
        id: macMouse
        visible: root.mac
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.secondAction();
            else
                root.firstAction();
        }
    }

    LazyPopup {
        id: pop
        panelId: "zapret2"
        anchorItem: root
        warm: root.hovered

        BarPopup {
            id: popup
            panelId: "zapret2"
            anchorItem: root
            above: BarLayout.bottom
            title: Skin.title("zapret2")
            icon: "lock"
            contentWidth: Skin.px(340)
            contentHeight: Math.max(Skin.px(190), Math.min(Skin.px(460), panel.implicitHeight + Skin.px(8)))
            onVisibleChanged: if (visible)
                panel.resetMore()

            PxScroll {
                anchors.fill: parent
                contentHeight: panel.implicitHeight

                Panel {
                    id: panel
                    width: parent.width
                    plugin: root.plugin
                }
            }
        }
    }
}
