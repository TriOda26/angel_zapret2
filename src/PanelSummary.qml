import QtQuick
import qs.config
import qs.services
import qs.widgets
import "."

// The compact body of the popup and of the first Settings group: status, the one primary
// action, the profile, and (outside Settings) the few destinations. Everything else sits
// behind "Ещё" so the popup stays small.
Column {
    id: root

    property bool settingsMode: false
    property bool showStatus: false
    property bool moreOpen: false

    signal navigate(string name)

    function resetMore() {
        moreOpen = false;
    }

    width: parent ? parent.width : 0
    spacing: Skin.px(8)

    Row {
        visible: root.showStatus
        width: parent.width
        spacing: Skin.px(8)

        AppleIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: Skin.px(30)
            on: Zapret.active
            bad: Zapret.failed
            bitten: Zapret.active
            growTick: Zapret.growTick
        }
        PxText {
            width: parent.width - Skin.px(38)
            anchors.verticalCenter: parent.verticalCenter
            text: Zapret.statusLine
            kind: "title"
            color: Zapret.failed ? Skin.danger : Zapret.active ? Skin.accent : Skin.text
            elide: Text.ElideRight
        }
    }

    PxBox {
        visible: !Zapret.installed
        width: parent.width
        height: missingColumn.implicitHeight + Skin.px(16)
        color: Skin.surfaceAlt
        hell: Skin.hell

        Column {
            id: missingColumn
            anchors.centerIn: parent
            width: parent.width - Skin.px(16)
            spacing: Skin.px(4)

            PxText {
                width: parent.width
                text: I18n.t("Сервис zapret2 не найден", "zapret2 service not found")
                color: Skin.warn
                kind: "title"
                elide: Text.ElideRight
            }
            PxText {
                width: parent.width
                text: Zapret.setupHint
                kind: "tiny"
                dim: true
                wrapMode: Text.Wrap
            }
            Row {
                spacing: Skin.px(6)

                PxButton {
                    compact: true
                    icon: Zapret.folderFound ? "gear" : "folder"
                    text: Zapret.folderFound ? I18n.t("Настроить", "Set up") : I18n.t("Указать папку…", "Choose folder…")
                    onClicked: Zapret.folderFound ? Zapret.openSetup(false) : Zapret.pickFolder()
                }
                PxButton {
                    compact: true
                    icon: "info"
                    text: I18n.t("Как установить", "How to install")
                    onClicked: Zapret.openSetup(true)
                }
            }
            PxText {
                width: parent.width
                visible: Zapret.pickError !== "" || Zapret.folderError !== "" || Zapret.unitError !== ""
                text: Zapret.pickError || Zapret.folderError || Zapret.unitError
                color: Skin.danger
                kind: "tiny"
                wrapMode: Text.Wrap
            }
        }
    }

    PxButton {
        visible: Zapret.installed
        width: parent.width
        compact: true
        icon: Zapret.busy ? "" : Zapret.active ? "pause" : "play"
        text: Zapret.busy ? "…" : Zapret.active ? I18n.t("Остановить", "Stop") : I18n.t("Запустить", "Start")
        accent: !Zapret.active
        hell: Skin.hell
        enabled: Zapret.installed && !Zapret.busy
        onClicked: Zapret.toggle()
    }

    PxText {
        width: parent.width
        visible: Zapret.lastError !== "" && !Zapret.failed
        text: Zapret.lastError
        color: Skin.danger
        kind: "tiny"
        wrapMode: Text.Wrap
    }
    PxText {
        width: parent.width
        visible: Zapret.lastNotice !== ""
        text: Zapret.lastNotice
        kind: "tiny"
        dim: true
        wrapMode: Text.Wrap
    }

    Column {
        visible: Zapret.installed
        width: parent.width
        spacing: Skin.px(4)

        PxText {
            text: I18n.t("Профиль", "Profile")
            kind: "tiny"
            dim: true
        }
        PxSegmented {
            visible: Zapret.profileOptions.length > 0 && Zapret.profileOptions.length <= 3
            width: parent.width
            model: Zapret.profileOptions
            currentValue: Zapret.profile
            enabled: Zapret.installed && !Zapret.busy
            onActivated: value => Zapret.setProfile(value)
        }
        PxCombo {
            visible: Zapret.profileOptions.length > 3
            width: parent.width
            model: Zapret.profileOptions
            currentValue: Zapret.profile
            enabled: Zapret.installed && !Zapret.busy
            onActivated: value => Zapret.setProfile(value)
        }
        PxText {
            visible: Zapret.profileOptions.length === 0
            width: parent.width
            text: I18n.t("Профилей нет — добавьте свой в настройках.", "No profiles yet — add one in Settings.")
            kind: "tiny"
            dim: true
            wrapMode: Text.Wrap
        }
        PxButton {
            visible: !root.settingsMode && Zapret.profileOptions.length === 0
            compact: true
            icon: "gear"
            text: I18n.t("Профили…", "Profiles…")
            onClicked: Shell.openSettings("plugin:zapret2")
        }
    }

    PxBox {
        visible: Zapret.installed && Zapret.setupState === "no-hostlist"
        width: parent.width
        height: setupColumn.implicitHeight + Skin.px(16)
        color: Skin.surfaceAlt
        hell: Skin.hell

        Column {
            id: setupColumn
            anchors.centerIn: parent
            width: parent.width - Skin.px(16)
            spacing: Skin.px(4)

            PxText {
                width: parent.width
                text: I18n.t("Профили не применяются", "Profiles are not applied")
                color: Skin.warn
                kind: "tiny"
            }
            PxText {
                width: parent.width
                text: Zapret.setupHint
                kind: "tiny"
                dim: true
                wrapMode: Text.Wrap
            }
            PxButton {
                text: I18n.t("Исправить", "Fix")
                compact: true
                onClicked: Zapret.setupHelper("install")
            }
        }
    }

    Row {
        visible: !root.settingsMode
        width: parent.width
        spacing: Skin.px(6)

        PxButton {
            width: (parent.width - Skin.px(12)) / 3
            maxWidth: width
            compact: true
            icon: "document"
            text: I18n.t("Журнал", "Journal")
            onClicked: root.navigate("log")
        }
        PxButton {
            width: (parent.width - Skin.px(12)) / 3
            maxWidth: width
            compact: true
            icon: "wifi"
            text: I18n.t("Домены", "Domains")
            onClicked: root.navigate("domains")
        }
        PxButton {
            width: (parent.width - Skin.px(12)) / 3
            maxWidth: width
            compact: true
            icon: root.moreOpen ? "arrowUp" : "arrowDown"
            text: root.moreOpen ? I18n.t("Меньше", "Less") : I18n.t("Ещё", "More")
            checked: root.moreOpen
            onClicked: root.moreOpen = !root.moreOpen
        }
    }

    Grid {
        visible: !root.settingsMode && root.moreOpen
        width: parent.width
        columns: 2
        columnSpacing: Skin.px(6)
        rowSpacing: Skin.px(6)

        PxButton {
            width: (root.width - Skin.px(6)) / 2
            maxWidth: width
            compact: true
            icon: "refresh"
            text: I18n.t("Рестарт", "Restart")
            enabled: Zapret.installed && !Zapret.busy
            onClicked: Zapret.restart()
        }
        PxButton {
            width: (root.width - Skin.px(6)) / 2
            maxWidth: width
            compact: true
            icon: "gauge"
            text: I18n.t("Стратегии", "Strategies")
            onClicked: root.navigate("strategies")
        }
        PxButton {
            width: (root.width - Skin.px(6)) / 2
            maxWidth: width
            compact: true
            icon: "terminal"
            text: I18n.t("Конфиг", "Config")
            onClicked: root.navigate("config")
        }
        PxButton {
            width: (root.width - Skin.px(6)) / 2
            maxWidth: width
            compact: true
            icon: "gear"
            text: I18n.t("Настройки", "Settings")
            onClicked: Shell.openSettings("plugin:zapret2")
        }
    }
}
