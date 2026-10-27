import QtQuick
import qs.config
import qs.services
import qs.widgets

// Everything about the service itself: where it is, which unit drives it, the hostlist link,
// the polkit helper and the diagnostics. Kept out of the panel so the panel stays small.
PxGroup {
    id: root

    title: I18n.t("Сервис", "Service")
    icon: "lock"
    width: parent ? parent.width : 0

    PxText {
        width: parent.width
        text: Zapret.statusLine
        kind: "title"
        color: Zapret.failed ? Skin.danger : Zapret.active ? Skin.accent : Skin.text
        elide: Text.ElideRight
    }
    PxText {
        width: parent.width
        visible: Zapret.setupState !== "ok"
        text: Zapret.setupHint
        kind: "tiny"
        dim: true
        wrapMode: Text.Wrap
    }
    PxText {
        width: parent.width
        visible: Zapret.unitMismatch
        text: I18n.t("Юнит запускает другой путь: папка и unit не совпадают", "The unit starts another path: folder and unit disagree")
        color: Skin.warn
        kind: "tiny"
        wrapMode: Text.Wrap
    }
    PxButton {
        visible: Zapret.setupState !== "ok"
        compact: true
        icon: "gear"
        text: I18n.t("Настроить", "Set up")
        onClicked: Zapret.openSetup(false)
    }

    SettingRow {
        label: I18n.t("Папка", "Folder")
        hint: Zapret.folderError !== "" ? Zapret.folderError : Zapret.rootDir
        PxButton {
            compact: true
            icon: "folder"
            text: I18n.t("Выбрать…", "Choose…")
            enabled: !Zapret.pickingFolder
            onClicked: Zapret.pickFolder()
        }
    }
    PxText {
        width: parent.width
        visible: Zapret.pickError !== ""
        text: Zapret.pickError
        color: Skin.danger
        kind: "tiny"
        wrapMode: Text.Wrap
    }

    SettingRow {
        label: I18n.t("Юнит", "Unit")
        hint: Zapret.unitError !== "" ? Zapret.unitError : (Zapret.detectedUnits.length ? Zapret.detectedUnits.join(" · ") : Zapret.unitPath)
        Row {
            width: parent.width
            spacing: Skin.px(6)

            PxField {
                id: unitField
                width: parent.width - unitCheck.width - Skin.px(6)
                text: Zapret.unitName
                onAccepted: Zapret.setUnitName(unitField.text)
            }
            PxButton {
                id: unitCheck
                compact: true
                text: I18n.t("Проверить", "Check")
                onClicked: Zapret.setUnitName(unitField.text)
            }
        }
    }

    SettingRow {
        label: I18n.t("Автозапуск", "Start at boot")
        hint: "systemctl enable " + Zapret.unitName
        PxToggle {
            checked: Zapret.unitFileState === "enabled"
            enabled: Zapret.installed && !Zapret.busy
            onToggled: checked => Zapret.enableBoot(checked)
        }
    }
    SettingRow {
        label: I18n.t("Перезапуск", "Restart")
        hint: I18n.t("перечитать стратегии и списки", "re-read the strategies and lists")
        PxButton {
            compact: true
            text: I18n.t("Перезапустить", "Restart")
            icon: "refresh"
            enabled: Zapret.installed && !Zapret.busy
            onClicked: Zapret.restart()
        }
    }
    SettingRow {
        label: I18n.t("Связь hostlist", "Hostlist link")
        hint: Zapret.setupHint
        PxButton {
            compact: true
            text: I18n.t("Исправить", "Fix")
            icon: "gear"
            onClicked: Zapret.setupHelper("install")
        }
    }
    SettingRow {
        label: "polkit helper"
        hint: Zapret.helperInstalled ? I18n.t("правило установлено", "the rule is installed") : I18n.t("правила нет: systemctl спросит пароль", "no rule: systemctl asks for a password")
        PxButton {
            compact: true
            text: Zapret.helperInstalled ? I18n.t("Удалить", "Remove") : I18n.t("Установить", "Install")
            icon: Zapret.helperInstalled ? "trash" : "lock"
            enabled: !Zapret.busy
            onClicked: Zapret.setupHelper(Zapret.helperInstalled ? "remove" : "install")
        }
    }

    PxText {
        width: parent.width
        text: I18n.t("Файл юнита: ", "Unit file: ") + (Zapret.unitPath || "—")
        kind: "tiny"
        dim: true
        wrapMode: Text.Wrap
    }
    PxText {
        width: parent.width
        text: I18n.t("Процесс: ", "Process: ") + (Zapret.processText || "—")
        kind: "tiny"
        dim: true
        wrapMode: Text.Wrap
    }
    PxText {
        width: parent.width
        text: I18n.t("С момента: ", "Since: ") + (Zapret.sinceRaw || "—")
        kind: "tiny"
        dim: true
        wrapMode: Text.Wrap
    }
    PxText {
        width: parent.width
        visible: Zapret.execStartText !== ""
        text: "ExecStart: " + Zapret.execStartText
        kind: "tiny"
        dim: true
        wrapMode: Text.Wrap
    }
    PxButton {
        compact: true
        icon: "document"
        text: I18n.t("Копировать диагностику", "Copy diagnostics")
        onClicked: Clipboard.copy(Zapret.statusJson())
    }
}
