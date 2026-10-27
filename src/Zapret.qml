pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import "Voices.js" as Voices

// State and actions for the local zapret2 service. Everything here is user-level: status comes
// from systemd, profiles from ~/.config/zapret2, and starting/stopping the unit goes through the
// session's polkit agent. The optional helper only removes the password prompt for this one unit.
Singleton {
    id: root

    property var plugin
    property bool running: false
    property bool busy: false

    readonly property string home: Quickshell.env("HOME")
    property string rootDir: "/opt/zapret2"
    property string unitName: "zapret2.service"
    property string unitPath: ""
    readonly property string configPath: rootDir + "/config"
    readonly property string hostlistPath: rootDir + "/ipset/zapret-hosts-user.txt"
    readonly property string profileDir: home + "/.config/zapret2"
    readonly property string profilesDir: profileDir + "/profiles"
    readonly property string activePath: profileDir + "/active.txt"
    readonly property string helperPath: "/etc/polkit-1/rules.d/49-zapret2.rules"

    property bool folderFound: false
    property bool serviceFound: false
    property bool serviceCheckFailed: false
    readonly property bool installed: folderFound && serviceFound
    readonly property string installCommand: "sudo pacman -S zapret2 && sudo systemctl enable --now " + unitName
    property bool setupPending: false
    property bool active: false
    property bool failed: false
    property string unitState: "unknown"
    property string subState: ""
    property string unitFileState: ""
    property string result: ""
    property string sinceRaw: ""
    property double nowTick: Date.now()
    property string processText: ""
    property string activeText: ""
    property string configText: ""
    property var profiles: []
    property string profile: "custom"
    property int growTick: 0
    property bool setupOk: false
    property bool helperInstalled: false
    property string lastError: ""
    property string lastNotice: ""
    property string logText: ""
    property bool logLoading: false

    property string pendingProfile: ""
    property string pendingText: ""
    property string writeKind: "active"
    property string writeTarget: ""
    property string writeProfileName: ""
    property bool writeRestart: false
    property string actionKind: ""
    property bool actionWanted: false
    property string helperKind: "install"
    property string actionErrorText: ""
    property string writeErrorText: ""
    property string logErrorText: ""
    property string helperOutText: ""
    property string helperErrText: ""

    // service setup: a chosen folder/unit, detection, and the one-time missing-service dialog
    property string pendingRoot: ""
    property string pendingUnit: ""
    property bool pickingFolder: false
    property string pickError: ""
    property string folderError: ""
    property string unitError: ""
    readonly property bool unitMismatch: {
        if (!root.serviceFound || root.execStartText === "")
            return false;
        const r = root.rootDir;
        let i = root.execStartText.indexOf(r);
        while (i >= 0) {
            const before = i === 0 ? "" : root.execStartText[i - 1];
            const after = root.execStartText[i + r.length] || "";
            const okBefore = before === "" || before === "=" || before === " " || before === "/";
            const okAfter = after === "" || after === "/" || after === " " || after === ";";
            if (okBefore && okAfter)
                return false;
            i = root.execStartText.indexOf(r, i + 1);
        }
        return true;
    }
    property string execStartText: ""
    property var detectedFolders: []
    property var detectedUnits: []
    property bool setupDialogOpen: false
    property bool setupInstall: false
    property bool setupSeen: false
    property bool setupDismissed: false
    property bool _detected: false
    property bool _folderChecked: false
    property bool _serviceChecked: false
    property bool _setupChecked: false
    property bool _wasFailed: false
    readonly property bool checksDone: _folderChecked && _serviceChecked

    readonly property var domains: activeText.split("\n").map(line => line.trim()).filter(line => line !== "" && line.charAt(0) !== "#")
    readonly property int domainsCount: domains.length
    readonly property string strategyText: {
        const m = String(configText).match(/NFQWS2_OPT\s*=\s*"([\s\S]*?)"/);
        return m ? m[1].trim() : "";
    }
    readonly property var strategies: strategyText.split(/^\s*--new\s*$/m).map(s => s.trim()).filter(s => s !== "")
    readonly property var profileOptions: profiles.map(name => ({
                "label": profileLabel(name),
                "value": name
            }))
    readonly property var sinceDate: parseDate(sinceRaw)
    readonly property string sinceText: {
        const d = root.sinceDate;
        if (!d)
            return "";
        const today = new Date();
        return Qt.formatDateTime(d, d.toDateString() === today.toDateString() ? "HH:mm" : "dd.MM HH:mm");
    }
    readonly property string uptimeText: {
        const d = root.sinceDate;
        if (!root.active || !d)
            return "";
        const mins = Math.max(0, Math.floor((root.nowTick - d.getTime()) / 60000));
        const h = Math.floor(mins / 60);
        return h > 0 ? h + ":" + String(mins % 60).padStart(2, "0") : mins + I18n.t(" мин", " min");
    }
    readonly property string statusText: {
        if (!root.checksDone)
            return I18n.t("Проверяю…", "Checking…");
        if (root.serviceCheckFailed)
            return I18n.t("Не удалось проверить", "Check failed");
        if (!root.installed)
            return I18n.t("Не найден", "Not found");
        if (root.unitState === "activating")
            return I18n.t("Запускается…", "Starting…");
        if (root.unitState === "deactivating")
            return I18n.t("Останавливается…", "Stopping…");
        if (root.active)
            return I18n.t("Обход включён", "Bypass on");
        if (root.failed)
            return I18n.t("Ошибка", "Failed");
        return I18n.t("Обход выключен", "Bypass off");
    }
    readonly property string statusHint: {
        if (!root.checksDone)
            return I18n.t("проверяю…", "checking…");
        if (!root.installed || root.serviceCheckFailed)
            return root.setupHint;
        if (root.active)
            return (root.sinceText ? I18n.t("с ", "since ") + root.sinceText + (root.uptimeText ? " · " + root.uptimeText : "") + " · " : "") + root.domainsCount + I18n.t(" доменов", " domains");
        return root.unitFileState === "enabled" ? I18n.t("автозапуск включён", "starts at boot") : I18n.t("автозапуск выключен", "no autostart");
    }
    readonly property string statusLine: {
        if (!root.checksDone)
            return I18n.t("Проверяю…", "Checking…");
        if (root.serviceCheckFailed)
            return I18n.t("Не удалось проверить", "Check failed");
        if (!root.installed)
            return I18n.t("Не найден", "Not found");
        if (root.failed)
            return I18n.t("Ошибка", "Failed");
        return root.active ? I18n.t("Работает", "Running") + " · " + root.domainsCount + I18n.t(" доменов", " domains") : I18n.t("Остановлен", "Stopped");
    }
    readonly property string profileLabelText: root.profile === "custom" ? I18n.t("свой список", "custom") : root.profileLabel(root.profile)
    readonly property string setupState: (!root.checksDone || root.serviceCheckFailed) ? "unknown" : !root.folderFound ? "no-folder" : !root.serviceFound ? "no-unit" : !root.setupOk ? "no-hostlist" : "ok"
    readonly property string setupHint: {
        if (!root.checksDone)
            return I18n.t("проверяю…", "checking…");
        if (root.serviceCheckFailed)
            return I18n.t("systemctl недоступен", "systemctl is unavailable");
        if (!root.folderFound)
            return I18n.t("папка ", "folder ") + root.rootDir + I18n.t(" не найдена", " not found");
        if (!root.serviceFound)
            return I18n.t("юнит ", "unit ") + root.unitName + I18n.t(" не найден", " not found");
        if (!root.setupOk)
            return I18n.t("hostlist не связан с активным профилем", "hostlist is not linked to the active profile");
        return I18n.t("hostlist указывает на активный профиль", "hostlist points at the active profile");
    }

    signal changed

    function attach(p) {
        if (!p)
            return;
        plugin = p;
        const r = String(p.get("rootDir", "") || "").replace(/\/+$/, "");
        const u = String(p.get("unitName", "") || "");
        if (r)
            rootDir = r;
        if (u)
            unitName = u;
        setupSeen = p.get("setupSeen", false) === true;
        setupDismissed = p.get("setupDismissed", false) === true;
    }

    function start() {
        if (running)
            return;
        running = true;
        if (!_detected)
            detectService();
        refresh();
    }

    function stop() {
        running = false;
        poll.stop();
    }

    function refresh() {
        nowTick = Date.now();
        configFile.reload();
        activeFile.reload();
        helperFile.reload();
        if (!showProc.running)
            showProc.running = true;
        if (!folderProc.running)
            folderProc.running = true;
        if (!profilesProc.running)
            profilesProc.running = true;
        if (!procProc.running)
            procProc.running = true;
        if (!linkProc.running)
            linkProc.running = true;
        changed();
    }

    function detectService() {
        if (_detected || detectProc.running)
            return;
        _detected = true;
        detectProc.running = true;
    }

    function updateSetupState() {
        if (checksDone && !_setupChecked) {
            _setupChecked = true;
            maybeShowSetup();
        }
        changed();
    }

    function maybeShowSetup() {
        if (installed || setupDismissed || setupSeen) {
            setupPending = false;
            return;
        }
        if (!checksDone || serviceCheckFailed)
            return;
        if (typeof Shell !== "undefined" && (Shell.setupLocked || Shell.gaming || Shell.fullscreenOn(Shell.focusedScreen ? Shell.focusedScreen.name : ""))) {
            setupPending = true;
            return;
        }
        setupPending = false;
        setupSeen = true;
        if (plugin)
            plugin.set("setupSeen", true);
        root.voice("missing");
        openSetup(false);
    }

    function openSetup(install) {
        setupInstall = !!install;
        setupDialogOpen = true;
    }

    function closeSetup() {
        setupDialogOpen = false;
    }

    function dismissSetup() {
        setupDismissed = true;
        setupPending = false;
        if (plugin)
            plugin.set("setupDismissed", true);
        closeSetup();
    }

    function applyRootDir(path, save) {
        rootDir = String(path || "").replace(/\/+$/, "");
        folderError = "";
        if (save && plugin)
            plugin.set("rootDir", rootDir);
        _folderChecked = false;
        refresh();
    }

    function applyUnitName(name, save) {
        unitName = String(name || "").trim();
        unitError = "";
        if (save && plugin)
            plugin.set("unitName", unitName);
        _serviceChecked = false;
        refresh();
    }

    function setRootDir(path) {
        const p = String(path || "").trim();
        if (!p || validateFolderProc.running)
            return;
        pendingRoot = p.replace(/\/+$/, "");
        folderError = "";
        validateFolderProc.command = ["sh", "-c", 'test -f "$1/config" && test -d "$1/ipset" && test -x "$1/init.d/sysv/zapret2"', "sh", pendingRoot];
        validateFolderProc.running = true;
    }

    function setUnitName(name) {
        const u = String(name || "").trim();
        if (!u || unitCheckProc.running)
            return;
        pendingUnit = u;
        unitError = "";
        unitCheckProc.command = ["systemctl", "show", pendingUnit, "-p", "LoadState"];
        unitCheckProc.running = true;
    }

    function pickFolder() {
        if (pickerProc.running)
            return;
        pickingFolder = true;
        pickError = "";
        pickerProc.command = ["python3", Quickshell.shellDir + "/scripts/pick-file.py", "--dir", "--start", rootDir, "--remember", "zapret2", I18n.t("zapret2 — папка", "zapret2 — folder")];
        pickerProc.running = true;
    }

    function parseDate(raw) {
        const m = String(raw || "").match(/\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/);
        if (!m)
            return null;
        const d = new Date(m[0].replace(" ", "T"));
        return isNaN(d.getTime()) ? null : d;
    }

    function profileLabel(name) {
        if (!name || name === "custom")
            return I18n.t("свой список", "custom");
        if (name === "youtube")
            return "YouTube";
        if (name === "discord")
            return "Discord";
        if (name === "all")
            return I18n.t("Всё", "All");
        return String(name).replace(/[-_]/g, " ");
    }

    function detectProfile() {
        if (profileProc.running)
            return;
        profileProc.running = true;
    }

    function notify(title, body) {
        if (!plugin || plugin.get("notify", true) === false)
            return;
        Quickshell.execDetached(["notify-send", "-a", "zapret2", title, body]);
    }

    // A short themed line from the angel or the demon. The first time each event happens it is
    // guaranteed (Angel.say); after that it appears at random and Angel.react keeps its own
    // cooldown. Older shells without these hooks simply get no line.
    function voice(kind, name) {
        if (!plugin || plugin.get("voices", true) === false)
            return;
        if (typeof Angel === "undefined" || !Angel.shown)
            return;
        const seenRaw = plugin.get("voiceSeen", []);
        const seen = Array.isArray(seenRaw) ? seenRaw : [];
        const key = kind === "profile" && name ? "profile-" + name : kind;
        const first = seen.indexOf(key) < 0;
        if (!first && Math.random() > 0.35)
            return;
        const v = Voices.pick(kind, Angel.demon, name || "");
        if (!v)
            return;
        const text = I18n.t(v[0], v[1]);
        if (first && typeof Angel.say === "function") {
            Angel.say(text, null, 0, true);
            plugin.set("voiceSeen", seen.concat([key]));
        } else if (typeof Angel.react === "function") {
            Angel.react(text, null, true);
            if (first)
                plugin.set("voiceSeen", seen.concat([key]));
        }
    }

    function toggle() {
        if (busy || !installed)
            return;
        actionKind = "toggle";
        actionWanted = !active;
        busy = true;
        actionErrorText = "";
        actionProc.command = ["systemctl", active ? "stop" : "start", root.unitName];
        actionProc.running = true;
    }

    function restart() {
        if (busy || !installed)
            return;
        actionKind = "restart";
        busy = true;
        actionErrorText = "";
        actionProc.command = ["systemctl", "restart", root.unitName];
        actionProc.running = true;
    }

    function enableBoot(on) {
        if (busy || !installed)
            return;
        actionKind = "boot";
        actionWanted = !!on;
        busy = true;
        actionErrorText = "";
        actionProc.command = ["systemctl", on ? "enable" : "disable", root.unitName];
        actionProc.running = true;
    }

    function setProfile(name) {
        if (busy || !installed || !name)
            return;
        if (!/^[A-Za-z0-9._-]+$/.test(name)) {
            lastError = I18n.t("Недопустимое имя профиля", "Invalid profile name");
            return;
        }
        pendingProfile = name;
        busy = true;
        lastError = "";
        readProfileProc.command = ["cat", profilesDir + "/" + name + ".txt"];
        readProfileProc.running = true;
    }

    function saveDomains(text, restartAfter) {
        if (busy)
            return;
        writeKind = "active";
        writeTarget = activePath;
        writeProfileName = "";
        writeRestart = restartAfter !== false;
        pendingText = String(text || "");
        if (pendingText !== "" && !pendingText.endsWith("\n"))
            pendingText += "\n";
        busy = true;
        lastError = "";
        writeErrorText = "";
        writeProc.command = ["sh", "-c", "mkdir -p -- \"$1\" && cat > \"$2\"", "sh", profileDir, writeTarget];
        writeProc.running = true;
    }

    function saveProfileAs(name, text) {
        if (busy)
            return;
        const clean = String(name || "").trim().replace(/\.txt$/i, "");
        if (!/^[A-Za-z0-9._-]+$/.test(clean)) {
            lastError = I18n.t("Имя профиля: буквы, цифры, точка, дефис", "Profile name: letters, digits, dot, hyphen");
            return;
        }
        writeKind = "profile";
        writeTarget = profilesDir + "/" + clean + ".txt";
        writeProfileName = clean;
        writeRestart = false;
        pendingText = String(text || "");
        if (pendingText !== "" && !pendingText.endsWith("\n"))
            pendingText += "\n";
        busy = true;
        lastError = "";
        writeErrorText = "";
        writeProc.command = ["sh", "-c", "mkdir -p -- \"$1\" && cat > \"$2\"", "sh", profilesDir, writeTarget];
        writeProc.running = true;
    }

    function refreshLog() {
        if (logProc.running)
            return;
        logLoading = true;
        logErrorText = "";
        logProc.command = ["journalctl", "-u", root.unitName, "-n", "120", "--no-pager", "-o", "cat"];
        logProc.running = true;
    }

    function setupHelper(kind) {
        if (!plugin || busy)
            return;
        helperKind = kind || "install";
        busy = true;
        lastError = "";
        helperOutText = "";
        helperErrText = "";
        helperProc.command = ["pkexec", "sh", plugin.dir + "/scripts/setup-polkit.sh", helperKind, "--root", root.rootDir, "--unit", root.unitName];
        helperProc.running = true;
    }

    function shellQuote(s) {
        return "'" + String(s || "").replace(/'/g, "'\\''") + "'";
    }

    function openConfig() {
        Shell.terminal("sudo -e " + root.shellQuote(configPath));
    }

    function openDomains() {
        Shell.terminal("${EDITOR:-nano} " + root.shellQuote(activePath));
    }

    function openProfiles() {
        Shell.openPath(profilesDir);
    }

    function openJournal() {
        Shell.terminal("journalctl -u " + root.shellQuote(root.unitName) + " -f");
    }

    function blockcheck() {
        Shell.terminal("sudo " + root.shellQuote(rootDir + "/blockcheck2.sh"));
    }

    function statusJson() {
        return JSON.stringify({
            "installed": installed,
            "active": active,
            "failed": failed,
            "state": unitState,
            "sub": subState,
            "enabled": unitFileState,
            "profile": profile,
            "domains": domainsCount,
            "since": sinceRaw,
            "setup_ok": setupOk,
            "root": rootDir,
            "unit": unitName,
            "unit_path": unitPath,
            "folder_found": folderFound,
            "service_found": serviceFound,
            "service_check_failed": serviceCheckFailed,
            "setup_state": setupState,
            "unit_mismatch": unitMismatch,
            "process": processText,
            "exec_start": execStartText,
            "error": lastError
        });
    }

    Timer {
        id: poll
        interval: 5000
        repeat: true
        running: root.running && !root.busy
        onTriggered: root.refresh()
    }

    Timer {
        id: setupRetry
        interval: 5000
        repeat: true
        running: root.setupPending
        onTriggered: root.maybeShowSetup()
    }

    Timer {
        id: settle
        interval: 800
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: showProc
        command: ["systemctl", "show", root.unitName, "-p", "LoadState", "-p", "ActiveState", "-p", "SubState", "-p", "UnitFileState", "-p", "ActiveEnterTimestamp", "-p", "Result", "-p", "FragmentPath", "-p", "ExecStart"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        o[line.slice(0, i)] = line.slice(i + 1);
                }
                root.serviceFound = o.LoadState !== undefined && o.LoadState !== "" && o.LoadState !== "not-found";
                root.serviceCheckFailed = false;
                root.unitPath = o.FragmentPath || ("/usr/lib/systemd/system/" + root.unitName);
                root.execStartText = o.ExecStart || "";
                root.unitState = o.ActiveState || "unknown";
                root.subState = o.SubState || "";
                root.unitFileState = o.UnitFileState || "";
                root.result = o.Result || "";
                root.sinceRaw = o.ActiveEnterTimestamp || "";
                root.active = root.serviceFound && root.unitState === "active";
                root.failed = root.serviceFound && (root.unitState === "failed" || (root.result !== "" && root.result !== "success"));
                if (root.failed && !root._wasFailed)
                    root.voice("error");
                root._wasFailed = root.failed;
                root.nowTick = Date.now();
                root._serviceChecked = true;
                root.updateSetupState();
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.serviceFound = false;
                root.serviceCheckFailed = true;
                root.active = false;
                root.unitState = "unknown";
                root._serviceChecked = true;
                root.updateSetupState();
            }
        }
    }

    Process {
        id: folderProc
        command: ["sh", "-c", 'test -f "$1/config" && test -d "$1/ipset" && { echo yes; } || echo no', "sh", root.rootDir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.folderFound = text.trim() === "yes";
                root._folderChecked = true;
                root.updateSetupState();
            }
        }
        onExited: code => {
            if (code !== 0 && !root._folderChecked) {
                root.folderFound = false;
                root._folderChecked = true;
                root.updateSetupState();
            }
        }
    }

    Process {
        id: detectProc
        command: ["sh", "-c", "for d in /opt/zapret2 /usr/local/zapret2 \"$HOME/zapret2\" \"$HOME/.local/share/zapret2\"; do [ -f \"$d/config\" ] && printf 'folder=%s\\n' \"$d\"; done; if command -v pacman >/dev/null 2>&1; then pacman -Ql zapret2 2>/dev/null | awk '$2 ~ /\\/config$/ {sub(/\\/config$/, \"\", $2); print \"folder=\"$2; exit}'; fi; systemctl list-unit-files --type=service --no-legend 'zapret2*.service' 2>/dev/null | awk '{print \"unit=\"$1}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const folders = [];
                const units = [];
                for (const line of text.split("\n")) {
                    const t = line.trim();
                    if (t.startsWith("folder=")) {
                        const p = t.slice(7).trim();
                        if (p && !folders.includes(p))
                            folders.push(p);
                    } else if (t.startsWith("unit=")) {
                        const u = t.slice(5).trim();
                        if (u && !units.includes(u))
                            units.push(u);
                    }
                }
                root.detectedFolders = folders;
                root.detectedUnits = units;
                if (!root.folderFound && folders.length === 1)
                    root.applyRootDir(folders[0], true);
                if (!root.serviceFound && units.length === 1)
                    root.applyUnitName(units[0], true);
            }
        }
    }

    Process {
        id: pickerProc
        stdout: StdioCollector {
            id: pickerOut
        }
        onExited: code => {
            root.pickingFolder = false;
            const p = pickerOut.text.trim();
            if (code === 2) {
                root.pickError = I18n.t("окно выбора файла не открылось: нет XDG-портала или zenity", "no file chooser opened: no XDG portal or zenity");
                return;
            }
            if (code !== 0 || !p)
                return;
            root.setRootDir(p);
        }
    }

    Process {
        id: validateFolderProc
        stdout: StdioCollector {
        }
        onExited: code => {
            if (code === 0) {
                root.applyRootDir(root.pendingRoot, true);
            } else {
                root.folderError = I18n.t("это не папка zapret2: нет config / ipset / init.d/sysv/zapret2", "this is not a zapret2 folder: no config / ipset / init.d/sysv/zapret2");
            }
        }
    }

    Process {
        id: unitCheckProc
        stdout: StdioCollector {
            id: unitOut
        }
        onExited: code => {
            const out = unitOut.text.trim();
            if (code !== 0 || out === "" || out.indexOf("LoadState=not-found") >= 0) {
                root.unitError = I18n.t("юнит ", "unit ") + root.pendingUnit + I18n.t(" не найден", " not found");
                return;
            }
            root.applyUnitName(root.pendingUnit, true);
        }
    }

    FileView {
        id: configFile
        path: root.configPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.configText = text();
            root.changed();
        }
        onLoadFailed: {
            root.configText = "";
            root.changed();
        }
    }

    FileView {
        id: activeFile
        path: root.activePath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.activeText = text();
            root.detectProfile();
            root.changed();
        }
        onLoadFailed: {
            root.activeText = "";
            root.profile = "custom";
            root.changed();
        }
    }

    FileView {
        id: helperFile
        path: root.helperPath
        printErrors: false
        onLoaded: root.helperInstalled = true
        onLoadFailed: root.helperInstalled = false
    }

    Process {
        id: profilesProc
        command: ["sh", "-c", "for f in \"$1\"/*.txt; do [ -f \"$f\" ] || continue; n=${f##*/}; printf '%s\\n' \"${n%.txt}\"; done", "sh", root.profilesDir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.profiles = text.split("\n").map(s => s.trim()).filter(s => s !== "");
                root.detectProfile();
                root.changed();
            }
        }
    }

    Process {
        id: profileProc
        command: ["sh", "-c", "for f in \"$1\"/*.txt; do [ -f \"$f\" ] || continue; if cmp -s -- \"$f\" \"$2\"; then n=${f##*/}; printf '%s' \"${n%.txt}\"; exit 0; fi; done; printf 'custom'", "sh", root.profilesDir, root.activePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "")
                    root.profile = p;
                root.changed();
            }
        }
    }

    Process {
        id: procProc
        command: ["pgrep", "-a", "nfqws2"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.processText = text.trim().split("\n")[0] || "";
                root.changed();
            }
        }
    }

    Process {
        id: linkProc
        command: ["readlink", "-f", root.hostlistPath]
        stdout: StdioCollector {
            onStreamFinished: {
                root.setupOk = text.trim() === root.activePath;
                root.changed();
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.setupOk = false;
                root.changed();
            }
        }
    }

    Process {
        id: readProfileProc
        stdout: StdioCollector {
            id: profileOut
        }
        stderr: StdioCollector {
            id: profileErr
        }
        onExited: code => {
            const content = profileOut.text;
            const name = root.pendingProfile;
            root.pendingProfile = "";
            if (code !== 0 || content === "") {
                root.busy = false;
                root.lastError = profileErr.text.trim() || I18n.t("Не удалось прочитать профиль", "Could not read the profile");
                return;
            }
            root.busy = false;
            root.saveDomains(content, true);
            root.writeProfileName = name;
        }
    }

    Process {
        id: writeProc
        stdinEnabled: true
        stdout: StdioCollector {
        }
        stderr: StdioCollector {
            id: writeErr
            onStreamFinished: root.writeErrorText = text
        }
        onStarted: {
            write(root.pendingText);
            stdinEnabled = false;
        }
        onExited: code => {
            stdinEnabled = true;
            root.busy = false;
            const kind = root.writeKind;
            const name = root.writeProfileName;
            const wasProfile = kind === "active" && name !== "";
            root.writeProfileName = "";
            if (code !== 0) {
                root.lastError = root.writeErrorText.trim() || I18n.t("Не удалось сохранить файл", "Could not save the file");
                return;
            }
            root.lastError = "";
            if (kind === "active") {
                root.lastNotice = I18n.t("Список сохранён", "List saved");
                activeFile.reload();
                if (wasProfile)
                    root.growTick++;
                if (wasProfile)
                    root.voice("profile", name);
                if (root.writeRestart && root.active)
                    root.restart();
                else
                    root.refresh();
            } else {
                root.lastNotice = I18n.t("Профиль сохранён: ", "Profile saved: ") + name;
                profilesProc.running = true;
                root.refresh();
            }
            root.writeRestart = false;
        }
    }

    Process {
        id: actionProc
        stdout: StdioCollector {
        }
        stderr: StdioCollector {
            id: actionErr
            onStreamFinished: root.actionErrorText = text
        }
        onExited: code => {
            root.busy = false;
            const kind = root.actionKind;
            if (code !== 0) {
                root.lastError = root.actionErrorText.trim() || I18n.t("systemctl не выполнил действие (пароль отменён?)", "systemctl did not run the action (password cancelled?)");
            } else {
                root.lastError = "";
                if (kind === "toggle") {
                    root.lastNotice = root.actionWanted ? I18n.t("Обход включён", "Bypass on") : I18n.t("Обход выключен", "Bypass off");
                    root.notify("zapret2", root.lastNotice);
                    root.voice(root.actionWanted ? "on" : "off");
                } else if (kind === "restart") {
                    root.lastNotice = I18n.t("Сервис перезапущен", "Service restarted");
                    root.notify("zapret2", root.lastNotice);
                    root.voice("restart");
                } else if (kind === "boot") {
                    root.lastNotice = root.actionWanted ? I18n.t("Автозапуск включён", "Autostart on") : I18n.t("Автозапуск выключен", "Autostart off");
                }
            }
            settle.restart();
        }
    }

    Process {
        id: logProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.logText = text;
                root.changed();
            }
        }
        stderr: StdioCollector {
            id: logErr
            onStreamFinished: root.logErrorText = text
        }
        onExited: code => {
            root.logLoading = false;
            if (code !== 0)
                root.logText = root.logErrorText.trim();
            root.changed();
        }
    }

    Process {
        id: helperProc
        stdout: StdioCollector {
            id: helperOut
            onStreamFinished: root.helperOutText = text
        }
        stderr: StdioCollector {
            id: helperErr
            onStreamFinished: root.helperErrText = text
        }
        onExited: code => {
            root.busy = false;
            const out = (root.helperOutText + "\n" + root.helperErrText).trim();
            if (code !== 0) {
                root.lastError = out || I18n.t("Настройка отменена или не удалась", "Setup was cancelled or failed");
            } else {
                root.lastError = "";
                root.lastNotice = out || I18n.t("Настройка завершена", "Setup finished");
                if (root.helperKind === "install")
                    root.voice("fixed");
                root.helperFile.reload();
                root.refresh();
            }
        }
    }
}
