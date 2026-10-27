import QtQuick
import qs.config
import qs.services
import qs.widgets
import "."

// The popup's content: a status card, the one big Start/Stop button, the profile picker and the
// ways into the journal, the domains, the strategies and the settings. Subviews use the same
// width so the popup does not jump.
Column {
    id: root

    property var plugin
    property string view: "main"

    function resetMore() {
        summary.resetMore();
    }

    width: parent ? parent.width : 0
    spacing: Skin.px(8)

    onViewChanged: {
        if (view === "log")
            Zapret.refreshLog();
    }

    function titleOf(v) {
        if (v === "log")
            return I18n.t("Журнал", "Journal");
        if (v === "domains")
            return I18n.t("Домены", "Domains");
        if (v === "strategies")
            return I18n.t("Стратегии", "Strategies");
        if (v === "config")
            return I18n.t("Конфиг", "Config");
        return Skin.title("zapret2");
    }

    Row {
        width: parent.width
        spacing: Skin.px(8)

        PxButton {
            visible: root.view !== "main"
            icon: "arrowLeft"
            flat: true
            compact: true
            onClicked: root.view = "main"
        }
        AppleIcon {
            visible: root.view === "main"
            anchors.verticalCenter: parent.verticalCenter
            size: Skin.px(30)
            on: Zapret.active
            bad: Zapret.failed
            bitten: Zapret.active
            growTick: Zapret.growTick
            ink: Skin.text
        }
        Column {
            width: parent.width - (root.view === "main" ? Skin.px(30) : Skin.px(24)) - refreshBtn.width - Skin.px(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Skin.px(1)

            PxText {
                text: root.titleOf(root.view)
                kind: "title"
                width: parent.width
                elide: Text.ElideRight
            }
            PxText {
                text: Zapret.statusLine
                kind: "tiny"
                dim: true
                width: parent.width
                elide: Text.ElideRight
            }
        }
        PxButton {
            id: refreshBtn
            icon: "refresh"
            flat: true
            compact: true
            onClicked: {
                if (root.view === "log")
                    Zapret.refreshLog();
                else
                    Zapret.refresh();
            }
        }
    }

    PanelSummary {
        id: summary
        visible: root.view === "main"
        width: parent.width
        settingsMode: false
        onNavigate: name => root.view = name
    }

    Column {
        visible: root.view === "log"
        width: parent.width
        spacing: Skin.px(6)

        Row {
            width: parent.width
            spacing: Skin.px(6)

            PxButton {
                compact: true
                text: I18n.t("Обновить", "Refresh")
                icon: "refresh"
                onClicked: Zapret.refreshLog()
            }
            PxButton {
                compact: true
                text: I18n.t("Открыть", "Open")
                icon: "document"
                onClicked: Zapret.openJournal()
            }
        }
        PxText {
            width: parent.width
            text: Zapret.logLoading ? "…" : Zapret.logText || I18n.t("пусто", "empty")
            kind: "mono"
            dim: true
            wrapMode: Text.Wrap
        }
    }

    Column {
        visible: root.view === "domains"
        width: parent.width
        spacing: Skin.px(6)

        PxText {
            width: parent.width
            text: I18n.t("Файл: ", "File: ") + Zapret.activePath + I18n.t(" · строк: ", " · lines: ") + Zapret.domains.length
            kind: "tiny"
            dim: true
            wrapMode: Text.Wrap
        }
        PxText {
            width: parent.width
            text: Zapret.domains.length ? Zapret.domains.join("\n") : I18n.t("пусто", "empty")
            kind: "mono"
            wrapMode: Text.Wrap
        }
        Row {
            width: parent.width
            spacing: Skin.px(6)

            PxButton {
                compact: true
                icon: "gear"
                text: I18n.t("Редактировать", "Edit")
                onClicked: Shell.openSettings("plugin:zapret2")
            }
            PxButton {
                compact: true
                icon: "terminal"
                text: "nano"
                onClicked: Zapret.openDomains()
            }
        }
    }

    Column {
        visible: root.view === "strategies"
        width: parent.width
        spacing: Skin.px(6)

        PxText {
            width: parent.width
            text: Zapret.strategyText || I18n.t("нет стратегий", "no strategies")
            kind: "mono"
            wrapMode: Text.Wrap
        }
        PxButton {
            compact: true
            icon: "terminal"
            text: I18n.t("Править конфиг", "Edit config")
            onClicked: Zapret.openConfig()
        }
    }

    Column {
        visible: root.view === "config"
        width: parent.width
        spacing: Skin.px(6)

        InfoRow {
            label: I18n.t("Конфиг", "Config")
            value: Zapret.configPath
            mono: true
        }
        InfoRow {
            label: I18n.t("Профили", "Profiles")
            value: Zapret.profilesDir
            mono: true
        }
        InfoRow {
            label: I18n.t("Сервис", "Service")
            value: Zapret.unitPath
            mono: true
        }
        Row {
            width: parent.width
            spacing: Skin.px(6)

            PxButton {
                compact: true
                icon: "terminal"
                text: I18n.t("Открыть", "Open")
                onClicked: Zapret.openConfig()
            }
            PxButton {
                compact: true
                icon: "document"
                text: I18n.t("Каталог", "Folder")
                onClicked: Zapret.openProfiles()
            }
        }
    }
}
