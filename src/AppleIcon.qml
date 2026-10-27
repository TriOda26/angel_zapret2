import QtQuick
import qs.config
import qs.services
import qs.widgets

// The plugin's mark: the approved C1 pixel apple — brown branch, green leaf, pink body.
// off is muted, on is the accent apple with a bottom-right bite, error is the danger apple.
// A profile change plays the four growth frames; switching the bypass plays a short chomp.
Item {
    id: root

    property bool on: false
    property bool bad: false
    property bool bitten: false
    property int growTick: 0
    property bool mac: Skin.mac
    property bool hellBar: false
    property bool barOpen: false
    property real size: Skin.px(16)
    property color ink: Skin.text
    property string screenName: ""

    readonly property var whole: [
        "....z.ll.",
        "....zlll.",
        ".##.#.##.",
        "#ooooooo#",
        "#owwoooo#",
        "#ooooooo#",
        "#ooooooo#",
        ".#ooooo#.",
        "..#o#o#..",
        "...###..."
    ]
    readonly property var bite: [
        "....z.ll.",
        "....zlll.",
        ".##.#.##.",
        "#ooooooo#",
        "#owwoooo#",
        "#ooooooo#",
        "#ooooo#..",
        ".#ooo#...",
        "..#o#....",
        "...##...."
    ]
    readonly property var sprout: [
        ".........",
        "....z....",
        "....z....",
        "....z....",
        "....z....",
        ".........",
        ".........",
        ".........",
        ".........",
        "........."
    ]
    readonly property var bud: [
        "....z.ll.",
        "....zlll.",
        ".........",
        ".........",
        "...###...",
        "..#ooo#..",
        "..#ooo#..",
        "...###...",
        ".........",
        "........."
    ]
    readonly property var half: [
        "....z.ll.",
        "....zlll.",
        ".##.#.##.",
        "#ooooooo#",
        "#ooooooo#",
        "#ooooooo#",
        "#ooooooo#",
        ".#ooooo#.",
        ".........",
        "........."
    ]

    property bool _biteShown: false
    property bool _chompTarget: false
    property int _frame: -1

    readonly property var frames: [sprout, bud, half, _biteShown ? bite : whole]
    readonly property var rows: _frame >= 0 ? frames[_frame] : (_biteShown ? bite : whole)

    readonly property color bodyColor: root.bad ? Skin.danger : root.on ? (root.hellBar ? Theme.hellAccent : Skin.accent) : Skin.surfaceAlt
    readonly property color branchColor: root.bad ? Skin.danger : root.on ? "#976000" : Skin.textDim
    readonly property color leafColor: root.bad ? Skin.danger : root.on ? "#57e3a2" : Skin.textDim
    readonly property color badgeColor: root.bad ? Skin.danger : root.on && root.hellBar ? Theme.hellAccent : root.ink

    readonly property string outlineHex: (root.bad || root.on) ? "#ffffff" : Theme.hex(root.hellBar ? Theme.hellBarIcon : Skin.textDim)
    readonly property string bodyHex: Theme.hex(root.bodyColor)
    readonly property string branchHex: Theme.hex(root.branchColor)
    readonly property string leafHex: Theme.hex(root.leafColor)
    readonly property string highlightHex: (root.bad || root.on) ? "#ffffff" : Theme.hex(Skin.textDim)

    readonly property var palette: ({
            "#": root.outlineHex,
            "o": root.bodyHex,
            "z": root.branchHex,
            "l": root.leafHex,
            "w": root.highlightHex
        })

    implicitWidth: root.size
    implicitHeight: root.size * 10 / 9

    function grow() {
        if (!root.on)
            return;
        root._frame = 0;
        growTimer.restart();
    }

    function _advanceGrowth() {
        if (root._frame < 3)
            root._frame++;
        else {
            growTimer.stop();
            root._frame = -1;
        }
    }

    function _applyChomp() {
        root._biteShown = root._chompTarget;
    }

    function syncBite(animate) {
        if (!animate) {
            chompTimer.stop();
            root._chompTarget = root.bitten;
            root._biteShown = root.bitten;
            return;
        }
        if (root._biteShown === root.bitten) {
            chompTimer.stop();
            root._chompTarget = root.bitten;
            return;
        }
        root._chompTarget = root.bitten;
        chompTimer.restart();
    }

    Component.onCompleted: root.syncBite(false)
    onBittenChanged: root.syncBite(true)
    onOnChanged: root.syncBite(true)
    onGrowTickChanged: root.grow()

    Timer {
        id: chompTimer
        interval: 110
        onTriggered: root._applyChomp()
    }

    Timer {
        id: growTimer
        interval: 110
        repeat: true
        onTriggered: root._advanceGrowth()
    }

    PxIcon {
        visible: !root.mac
        anchors.centerIn: parent
        bitmap: root.rows
        exactPixel: Math.max(1, root.size / 9)
        ink: root.ink
        fill: root.bodyColor
        light: root.highlightHex
        body: Skin.surfaceAlt
        bad: Skin.danger
        palette: root.palette
    }

    MacIcon {
        visible: root.mac
        anchors.centerIn: parent
        name: "shield"
        size: root.size
        stroke: 2
        color: root.ink
    }
    MacIcon {
        visible: root.mac
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -root.size * 0.12
        anchors.bottomMargin: -root.size * 0.12
        name: root.on ? "check" : "x"
        size: Math.max(7, root.size * 0.48)
        stroke: 2.6
        color: root.badgeColor
    }
}
