import QtQuick
import qs.config
import qs.services
import qs.widgets
import "."

Column {
    id: root

    property var plugin
    property bool domainsDirty: false

    width: parent ? parent.width : 400
    spacing: Skin.px(10)

    Component.onCompleted: {
        Zapret.attach(plugin);
        Zapret.start();
    }
    onPluginChanged: Zapret.attach(plugin)

    PxGroup {
        title: "zapret2"
        icon: "lock"
        width: parent.width

        PanelSummary {
            width: parent.width
            settingsMode: true
            showStatus: true
        }
    }

    PxGroup {
        title: I18n.t("Вид", "Look")
        icon: "heart"
        width: parent.width

        SettingRow {
            label: I18n.t("Подпись на панели", "Bar label")
            hint: I18n.t("профиль рядом с яблоком", "the profile next to the apple")
            PxToggle {
                checked: plugin ? plugin.get("showLabel", false) : false
                onToggled: checked => plugin.set("showLabel", checked)
            }
        }
        SettingRow {
            label: I18n.t("ЛКМ по яблоку", "Left click on the apple")
            hint: clickOnce.checked ? I18n.t("переключает обход", "toggles bypass") : I18n.t("открывает пульт", "opens the panel")
            PxSegmented {
                id: clickOnce
                model: [
                    { label: I18n.t("Пульт", "Panel"), value: false },
                    { label: I18n.t("Вкл/выкл", "Toggle"), value: true }
                ]
                currentValue: plugin ? plugin.get("clickToggles", false) : false
                onActivated: value => plugin.set("clickToggles", value)
            }
        }
        SettingRow {
            label: I18n.t("Уведомления", "Notifications")
            hint: I18n.t("notify-send при переключении", "notify-send on toggle")
            PxToggle {
                checked: plugin ? plugin.get("notify", true) : true
                onToggled: checked => plugin.set("notify", checked)
            }
        }
        SettingRow {
            label: I18n.t("Голоса Ангелочка и Демона", "Angel and demon voices")
            hint: I18n.t("короткие реплики на действия плагина", "short lines on plugin actions")
            PxToggle {
                checked: plugin ? plugin.get("voices", true) : true
                onToggled: checked => plugin.set("voices", checked)
            }
        }
    }

    PxGroup {
        title: I18n.t("Профили", "Profiles")
        icon: "document"
        width: parent.width

        SettingRow {
            label: I18n.t("Активный профиль", "Active profile")
            hint: Zapret.profileLabelText
            PxCombo {
                width: parent.width
                model: Zapret.profileOptions
                currentValue: Zapret.profile
                enabled: Zapret.installed && !Zapret.busy
                onActivated: value => Zapret.setProfile(value)
            }
        }
        SettingRow {
            label: I18n.t("Новый профиль", "New profile")
            hint: I18n.t("сохранить текущий список как…", "save the current list as…")
            Row {
                width: parent.width
                spacing: Skin.px(6)

                PxField {
                    id: profileName
                    width: parent.width - saveProfile.width - Skin.px(6)
                    placeholder: I18n.t("имя", "name")
                }
                PxButton {
                    id: saveProfile
                    compact: true
                    text: I18n.t("Сохранить", "Save")
                    enabled: profileName.text.trim() !== "" && !Zapret.busy
                    onClicked: {
                        Zapret.saveProfileAs(profileName.text, Zapret.activeText);
                        profileName.text = "";
                    }
                }
            }
        }
        SettingRow {
            label: I18n.t("Файлы", "Files")
            hint: Zapret.profilesDir
            Row {
                spacing: Skin.px(6)
                PxButton {
                    compact: true
                    icon: "document"
                    text: I18n.t("Папка", "Folder")
                    onClicked: Zapret.openProfiles()
                }
                PxButton {
                    compact: true
                    icon: "terminal"
                    text: "active.txt"
                    onClicked: Zapret.openDomains()
                }
            }
        }
        PxText {
            width: parent.width
            text: Zapret.profiles.length ? Zapret.profiles.join(" · ") : I18n.t("профилей нет", "no profiles")
            kind: "tiny"
            dim: true
            wrapMode: Text.Wrap
        }
    }

    PxGroup {
        title: I18n.t("Домены", "Domains")
        icon: "wifi"
        width: parent.width

        PxText {
            width: parent.width
            text: I18n.t("Один домен на строку. # — комментарий. Файл: ", "One domain per line. # is a comment. File: ") + Zapret.activePath
            kind: "tiny"
            dim: true
            wrapMode: Text.Wrap
        }
        PxTextArea {
            id: domainsEditor
            width: parent.width
            height: Skin.px(190)
            monospace: true
            spell: false
            text: Zapret.activeText
            onEdited: if (domainsEditor.input.activeFocus)
                root.domainsDirty = true
        }
        Row {
            width: parent.width
            spacing: Skin.px(6)

            PxButton {
                compact: true
                icon: "check"
                text: I18n.t("Сохранить", "Save")
                enabled: !Zapret.busy
                onClicked: {
                    Zapret.saveDomains(domainsEditor.text, true);
                    root.domainsDirty = false;
                }
            }
            PxButton {
                compact: true
                icon: "refresh"
                text: I18n.t("Сбросить", "Reset")
                enabled: domainsEditor.text !== Zapret.activeText
                onClicked: {
                    domainsEditor.text = Zapret.activeText;
                    root.domainsDirty = false;
                }
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.domainsDirty
                text: I18n.t("не сохранено", "unsaved")
                kind: "tiny"
                color: Skin.warn
            }
        }
    }

    PxGroup {
        title: I18n.t("Стратегии", "Strategies")
        icon: "gauge"
        width: parent.width

        PxText {
            width: parent.width
            text: I18n.t("NFQWS2_OPT из ", "NFQWS2_OPT in ") + Zapret.configPath
            kind: "tiny"
            dim: true
            wrapMode: Text.Wrap
        }
        PxTextArea {
            width: parent.width
            height: Skin.px(170)
            monospace: true
            spell: false
            readOnly: true
            text: Zapret.strategyText || I18n.t("нет стратегий", "no strategies")
        }
        Row {
            width: parent.width
            spacing: Skin.px(6)

            PxButton {
                compact: true
                icon: "terminal"
                text: I18n.t("Править конфиг", "Edit config")
                onClicked: Zapret.openConfig()
            }
            PxButton {
                compact: true
                icon: "gauge"
                text: "blockcheck"
                onClicked: Zapret.blockcheck()
            }
        }
    }

    ServiceGroup {
    }

    PxGroup {
        title: I18n.t("О плагине", "About")
        icon: "info"
        width: parent.width

        InfoRow {
            label: I18n.t("Версия", "Version")
            value: plugin && plugin.manifest ? String(plugin.manifest.version || "1.0.0") : "1.0.0"
        }
        InfoRow {
            label: I18n.t("Автор", "Author")
            value: plugin && plugin.manifest ? String(plugin.manifest.author || "TriOda26") : "TriOda26"
        }
        InfoRow {
            label: I18n.t("Лицензия", "License")
            value: plugin && plugin.manifest ? String(plugin.manifest.license || "0BSD") : "0BSD"
        }
    }
}
