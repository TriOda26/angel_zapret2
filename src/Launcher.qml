import QtQuick
import qs.config
import qs.services
import "."

QtObject {
    id: root

    property var plugin
    property string pluginId
    readonly property string prefix: "zap"
    readonly property bool global: true
    signal changed

    Component.onCompleted: {
        Zapret.attach(plugin);
        Zapret.start();
    }
    onPluginChanged: Zapret.attach(plugin)

    function rows() {
        const out = [{
            "id": "zapret:toggle",
            "title": Zapret.active ? I18n.t("Выключить обход DPI", "Turn the DPI bypass off") : I18n.t("Включить обход DPI", "Turn the DPI bypass on"),
            "subtitle": Zapret.statusText + " · " + Zapret.statusHint,
            "icon": Zapret.active ? "pause" : "play"
        }, {
            "id": "zapret:restart",
            "title": I18n.t("Перезапустить zapret2", "Restart zapret2"),
            "subtitle": I18n.t("перечитать стратегии и домены", "re-read strategies and domains"),
            "icon": "refresh"
        }];
        for (const p of Zapret.profileOptions) {
            out.push({
                "id": "zapret:profile:" + p.value,
                "title": (Zapret.profile === p.value ? "✓ " : "") + p.label,
                "subtitle": I18n.t("профиль доменов", "domain profile"),
                "icon": "wifi"
            });
        }
        out.push({
            "id": "zapret:settings",
            "title": I18n.t("Настройки zapret2", "zapret2 settings"),
            "subtitle": I18n.t("домены, профили, стратегии, helper", "domains, profiles, strategies, helper"),
            "icon": "gear"
        }, {
            "id": "zapret:journal",
            "title": I18n.t("Журнал zapret2", "zapret2 journal"),
            "subtitle": "journalctl -u " + Zapret.unitName,
            "icon": "document"
        });
        return out;
    }

    function query(text, prefixed) {
        const q = String(text || "").trim().toLowerCase();
        if (!prefixed && q === "")
            return [];
        const out = [];
        for (const row of rows()) {
            if (!prefixed) {
                const hay = (row.title + " " + row.subtitle + " zapret zapret2 dpi").toLowerCase();
                if (q !== "" && !hay.includes(q))
                    continue;
            }
            out.push(Object.assign({}, row, {
                "score": prefixed ? 1000 : 60
            }));
        }
        if (!prefixed && out.length === 0 && q !== "" && "zapret2".includes(q)) {
            const fallback = rows().find(r => r.id === "zapret:settings");
            if (fallback)
                out.push(Object.assign({}, fallback, {
                    "score": 40
                }));
        }
        return out;
    }

    function activate(id) {
        if (id === "zapret:toggle")
            Zapret.toggle();
        else if (id === "zapret:restart")
            Zapret.restart();
        else if (id.startsWith("zapret:profile:"))
            Zapret.setProfile(id.slice("zapret:profile:".length));
        else if (id === "zapret:settings")
            Shell.openSettings("plugin:zapret2");
        else if (id === "zapret:journal")
            Zapret.openJournal();
        changed();
    }
}
