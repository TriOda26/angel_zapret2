import QtQuick
import qs.config
import qs.services
import qs.widgets
import "."

Column {
    id: root

    property var plugin
    property var menu

    width: parent ? parent.width : 0
    spacing: 0

    Component.onCompleted: {
        Zapret.attach(plugin);
        Zapret.start();
    }
    onPluginChanged: Zapret.attach(plugin)

    PxMenuItem {
        text: Zapret.active ? I18n.t("Выключить обход", "Turn bypass off") : I18n.t("Включить обход", "Turn bypass on")
        icon: Zapret.active ? "pause" : "play"
        enabled: Zapret.installed && !Zapret.busy
        onTriggered: {
            Zapret.toggle();
            if (root.menu)
                root.menu.close();
        }
    }
    PxMenuItem {
        text: I18n.t("Перезапустить сервис", "Restart service")
        icon: "refresh"
        enabled: Zapret.installed && !Zapret.busy
        onTriggered: {
            Zapret.restart();
            if (root.menu)
                root.menu.close();
        }
    }
    PxMenuItem {
        separator: true
        visible: Zapret.profileOptions.length > 0
    }
    Repeater {
        model: Zapret.profileOptions
        delegate: PxMenuItem {
            required property var modelData
            text: modelData.label
            checkable: true
            checked: Zapret.profile === modelData.value
            enabled: Zapret.installed && !Zapret.busy
            onTriggered: {
                Zapret.setProfile(modelData.value);
                if (root.menu)
                    root.menu.close();
            }
        }
    }
    PxMenuItem {
        separator: true
    }
    PxMenuItem {
        text: I18n.t("Домены и профили…", "Domains and profiles…")
        icon: "wifi"
        onTriggered: {
            Shell.openSettings("plugin:zapret2");
            if (root.menu)
                root.menu.close();
        }
    }
    PxMenuItem {
        text: I18n.t("Журнал…", "Journal…")
        icon: "document"
        onTriggered: {
            Zapret.refreshLog();
            Zapret.openJournal();
            if (root.menu)
                root.menu.close();
        }
    }
    PxMenuItem {
        text: I18n.t("Настройки…", "Settings…")
        icon: "gear"
        onTriggered: {
            Shell.openSettings("plugin:zapret2");
            if (root.menu)
                root.menu.close();
        }
    }
}
