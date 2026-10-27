import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// The one-time "zapret2 is not installed" window. Opened from the panel card, the Settings
// service group, or automatically once when the plugin is enabled without a service.
FloatingWindow {
    id: win

    visible: Zapret.setupDialogOpen
    color: "transparent"
    implicitWidth: Skin.px(430)
    implicitHeight: Skin.px(win.installOpen ? 470 : 330)
    minimumSize: Qt.size(Skin.px(360), Skin.px(260))
    title: Skin.title("zapret2")
    onClosed: Zapret.dismissSetup()

    property bool installOpen: false
    readonly property string heading: Zapret.setupState === "no-folder"
        ? I18n.t("Папка zapret2 не найдена", "The zapret2 folder is missing")
        : Zapret.setupState === "no-unit"
            ? I18n.t("systemd-юнит zapret2 не найден", "The zapret2 systemd unit is missing")
            : I18n.t("Сервис zapret2 не найден", "The zapret2 service is not found")
    onVisibleChanged: {
        if (visible)
            win.installOpen = Zapret.setupInstall;
    }

    Item {
        id: frame
        anchors.fill: parent
        property string settingsSkin: Skin.settingsSkin

        SkinCard {
            anchors.fill: parent
            anchors.margins: Skin.px(6)

            Column {
                anchors.fill: parent
                spacing: Skin.px(6)

                Item {
                    id: titleBar
                    width: parent.width
                    height: Skin.px(26)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        onPressed: win.startSystemMove()
                    }
                    PxText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        kind: "title"
                        text: Skin.title("zapret2")
                    }
                    PxButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "close"
                        compact: true
                        onClicked: Zapret.dismissSetup()
                    }
                }

                Flickable {
                    id: flick
                    width: parent.width
                    height: parent.height - titleBar.height - parent.spacing
                    contentWidth: width
                    contentHeight: content.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: content
                        width: flick.width
                        spacing: Skin.px(8)

                        PxText {
                            width: parent.width
                            text: win.heading
                            kind: "title"
                            color: Skin.warn
                            elide: Text.ElideRight
                        }                        PxText {
                            width: parent.width
                            text: Zapret.setupHint
                            kind: "tiny"
                            dim: true
                            wrapMode: Text.Wrap
                        }
                        PxText {
                            width: parent.width
                            text: I18n.t("папка: ", "folder: ") + Zapret.rootDir
                            kind: "mono"
                            wrapMode: Text.Wrap
                        }
                        PxText {
                            width: parent.width
                            text: I18n.t("юнит: ", "unit: ") + Zapret.unitName
                            kind: "mono"
                            wrapMode: Text.Wrap
                        }
                        PxText {
                            width: parent.width
                            visible: Zapret.pickError !== "" || Zapret.folderError !== "" || Zapret.unitError !== ""
                            text: Zapret.pickError || Zapret.folderError || Zapret.unitError
                            color: Skin.danger
                            kind: "tiny"
                            wrapMode: Text.Wrap
                        }

                        Row {
                            spacing: Skin.px(6)

                            PxButton {
                                compact: true
                                icon: "folder"
                                text: I18n.t("Указать папку…", "Choose folder…")
                                onClicked: Zapret.pickFolder()
                            }
                            PxButton {
                                compact: true
                                icon: "info"
                                text: I18n.t("Как установить", "How to install")
                                checked: win.installOpen
                                onClicked: win.installOpen = !win.installOpen
                            }
                        }

                        Column {
                            visible: win.installOpen
                            width: parent.width
                            spacing: Skin.px(4)

                            PxText {
                                width: parent.width
                                text: I18n.t("Arch / пакет zapret2:", "Arch / the zapret2 package:")
                                kind: "tiny"
                                dim: true
                            }
                            PxText {
                                width: parent.width
                                text: Zapret.installCommand
                                kind: "mono"
                                wrapMode: Text.Wrap
                            }
                            PxText {
                                width: parent.width
                                text: I18n.t("Другие системы: github.com/bol-van/zapret2", "Other systems: github.com/bol-van/zapret2")
                                kind: "tiny"
                                dim: true
                                wrapMode: Text.Wrap
                            }
                            PxText {
                                width: parent.width
                                visible: Zapret.folderFound
                                text: I18n.t("Если zapret2 уже распакован: ", "If zapret2 is already unpacked: ") + Zapret.rootDir + "/common/installer.sh"
                                kind: "tiny"
                                dim: true
                                wrapMode: Text.Wrap
                            }
                            Row {
                                spacing: Skin.px(6)

                                PxButton {
                                    compact: true
                                    icon: "document"
                                    text: I18n.t("Скопировать команду", "Copy command")
                                    onClicked: Clipboard.copy(Zapret.installCommand)
                                }
                                PxButton {
                                    compact: true
                                    icon: "external"
                                    text: "GitHub"
                                    onClicked: Qt.openUrlExternally("https://github.com/bol-van/zapret2")
                                }
                            }
                        }

                        PxButton {
                            compact: true
                            text: I18n.t("Позже", "Later")
                            onClicked: Zapret.dismissSetup()
                        }
                    }
                }
            }
        }
    }
}
