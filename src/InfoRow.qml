import QtQuick
import qs.config
import qs.services
import qs.widgets

// One "label … value" line for the panel and the settings page.
Item {
    id: root

    property string label: ""
    property string value: ""
    property bool mono: false
    property color valueColor: Skin.text
    property color labelColor: Skin.textDim
    readonly property real gap: Skin.px(8)

    width: parent ? parent.width : 0
    implicitHeight: Math.max(labelText.implicitHeight, valueText.implicitHeight)

    PxText {
        id: labelText
        text: root.label
        kind: "tiny"
        color: root.labelColor
        width: Math.min(root.width * 0.46, implicitWidth)
        elide: Text.ElideRight
    }
    PxText {
        id: valueText
        text: root.value
        kind: root.mono ? "mono" : "body"
        color: root.valueColor
        anchors.right: parent.right
        width: Math.max(0, root.width - labelText.width - root.gap)
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }
}
