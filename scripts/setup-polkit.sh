#!/bin/sh
# Root helper for zapret2: a polkit rule for this one unit and the hostlist symlink.
# Modes: install (default), remove (the rule only), check.
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "This helper must run as root (pkexec/sudo)." >&2
    exit 1
fi

MODE=install
ROOT_DIR=/opt/zapret2
UNIT_NAME=zapret2.service
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT_DIR=$2; shift 2 ;;
        --unit) UNIT_NAME=$2; shift 2 ;;
        install|remove|check) MODE=$1; shift ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done
CALLER="${PKEXEC_UID:-${SUDO_UID:-}}"
if [ -n "$CALLER" ]; then
    USER_NAME="$(id -nu "$CALLER" 2>/dev/null || true)"
fi
if [ -z "${USER_NAME:-}" ]; then
    USER_NAME="${SUDO_USER:-}"
fi
if [ -z "${USER_NAME:-}" ] || [ "$USER_NAME" = "root" ]; then
    echo "Cannot determine the desktop user (PKEXEC_UID/SUDO_USER)." >&2
    exit 1
fi

USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
USER_GROUP="$(id -gn "$USER_NAME")"
[ -n "$USER_HOME" ] && [ -d "$USER_HOME" ] || { echo "No home for $USER_NAME" >&2; exit 1; }

ACTIVE="$USER_HOME/.config/zapret2/active.txt"
HOSTLIST="$ROOT_DIR/ipset/zapret-hosts-user.txt"
RULE=/etc/polkit-1/rules.d/49-zapret2.rules

check() {
    printf 'user: %s\n' "$USER_NAME"
    printf 'root: %s\n' "$ROOT_DIR"
    printf 'unit: %s\n' "$UNIT_NAME"
    printf 'active: %s\n' "$ACTIVE"
    if [ -f "$RULE" ]; then printf 'rule: yes\n'; else printf 'rule: no\n'; fi
    if [ -L "$HOSTLIST" ]; then
        printf 'hostlist: symlink -> %s\n' "$(readlink -f "$HOSTLIST" 2>/dev/null || true)"
    elif [ -f "$HOSTLIST" ]; then
        printf 'hostlist: regular file\n'
    else
        printf 'hostlist: missing\n'
    fi
    if systemctl is-active --quiet "$UNIT_NAME" 2>/dev/null; then
        printf 'service: active\n'
    else
        printf 'service: inactive\n'
    fi
}

if [ "$MODE" = "check" ]; then
    check
    exit 0
fi

if [ "$MODE" = "remove" ]; then
    rm -f "$RULE"
    systemctl try-restart polkit.service >/dev/null 2>&1 || true
    echo "polkit rule removed"
    exit 0
fi

if [ "$MODE" != "install" ]; then
    echo "Unknown mode: $MODE (use install, remove, check)" >&2
    exit 2
fi

[ -d "$ROOT_DIR/ipset" ] || { echo "No $ROOT_DIR/ipset — install zapret2 first." >&2; exit 1; }
mkdir -p "$USER_HOME/.config/zapret2/profiles"
chown "$USER_NAME:$USER_GROUP" "$USER_HOME/.config/zapret2" "$USER_HOME/.config/zapret2/profiles" 2>/dev/null || true
chmod 0755 "$USER_HOME/.config/zapret2" "$USER_HOME/.config/zapret2/profiles" 2>/dev/null || true
if [ ! -f "$ACTIVE" ]; then
    if [ -f "$HOSTLIST" ] && [ ! -L "$HOSTLIST" ]; then
        cp -f "$HOSTLIST" "$ACTIVE"
    else
        : >"$ACTIVE"
    fi
fi
chown "$USER_NAME:$USER_GROUP" "$ACTIVE"
chmod 0644 "$ACTIVE"

cat >"$RULE" <<RULE_EOF
// zapret2: this user may manage only $UNIT_NAME without a password.
polkit.addRule(function(action, subject) {
    if (subject.user != "$USER_NAME") {
        return polkit.Result.NOT_HANDLED;
    }
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "$UNIT_NAME") {
        var verb = action.lookup("verb");
        if (verb == "start" || verb == "stop" || verb == "restart" ||
            verb == "try-restart" || verb == "reload-or-restart")
            return polkit.Result.YES;
    }
    if (action.id == "org.freedesktop.systemd1.manage-unit-files" &&
        action.lookup("unit") == "$UNIT_NAME")
        return polkit.Result.YES;
    return polkit.Result.NOT_HANDLED;
});
RULE_EOF
chmod 0644 "$RULE"

if [ -L "$HOSTLIST" ]; then
    if [ "$(readlink -f "$HOSTLIST")" != "$(readlink -f "$ACTIVE")" ]; then
        [ -e "$HOSTLIST.zapret2-backup" ] || cp -a "$(readlink -f "$HOSTLIST")" "$HOSTLIST.zapret2-backup" 2>/dev/null || true
        rm -f "$HOSTLIST"
        ln -s "$ACTIVE" "$HOSTLIST"
    fi
else
    if [ -f "$HOSTLIST" ] && [ ! -e "$HOSTLIST.zapret2-backup" ]; then
        cp -a "$HOSTLIST" "$HOSTLIST.zapret2-backup" || true
    fi
    rm -f "$HOSTLIST"
    ln -s "$ACTIVE" "$HOSTLIST"
fi

systemctl try-restart polkit.service >/dev/null 2>&1 || true
if systemctl is-active --quiet "$UNIT_NAME" 2>/dev/null; then
    systemctl restart "$UNIT_NAME" || true
fi

echo "polkit rule: $RULE"
echo "hostlist: $HOSTLIST -> $ACTIVE"
echo "service: $(systemctl is-active "$UNIT_NAME" 2>/dev/null || true)"
