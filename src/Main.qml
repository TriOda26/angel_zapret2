import QtQuick
import Quickshell
import Quickshell.Io
import "."

// Background service: keeps the systemd state fresh while the plugin is enabled, and gives the
// shell a small IPC surface for scripts and key bindings.
Item {
    id: root
    property var plugin

    onPluginChanged: if (plugin)
        Zapret.attach(plugin)

    Component.onCompleted: {
        if (plugin)
            Zapret.attach(plugin);
        Zapret.start();
    }
    Component.onDestruction: Zapret.stop()

    IpcHandler {
        target: "zapret"

        function status(): string {
            return Zapret.statusJson();
        }
        function toggle() {
            Zapret.toggle();
        }
        function restart() {
            Zapret.restart();
        }
        function refresh() {
            Zapret.refresh();
        }
        function profile(name: string) {
            Zapret.setProfile(name);
        }
        function log(): string {
            return Zapret.logText;
        }
    }

    SetupDialog {
    }
}
