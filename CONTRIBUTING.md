# Contributing to zapret2

This plugin follows the angelOS Community Registry workflow. The ZIP itself does not need a
`CONTRIBUTING.md`; the registry pull request does.

## Project layout

```text
angel_zapret2/
├── manifest.json          entry points: src/Main.qml, src/BarWidget.qml, …
├── src/                   all QML and Voices.js, with its own qmldir singleton
├── scripts/setup-polkit.sh
├── tools/package-release.sh
├── README.md  LICENSE  CHANGELOG.md  CONTRIBUTING.md  preview.png
└── .gitignore             repo-only; it is not part of the ZIP
```

`.gitignore` contains only `*.bak`; the ZIP and registry entry are built outside the repository.
`tools/package-release.sh` copies only the runtime files, so the ZIP never contains dev files.

## Local development

```bash
mkdir -p ~/.config/angelos/plugins
cp -a . ~/.config/angelos/plugins/zapret2
angelos restart
```

Enable **Settings → Plugins → zapret2**. The default service is `/opt/zapret2` +
`zapret2.service`; both can be changed in **Settings → Service**.

## What is not part of the plugin

The plugin reads, but never ships:

- profiles from `~/.config/zapret2/profiles/`;
- the active domain list `~/.config/zapret2/active.txt`;
- strategies and blobs from `/opt/zapret2/config` and `/opt/zapret2/ipset`;
- any personal screenshots or settings.

Keep them out of the repository and the release ZIP.

## Build the release ZIP

```bash
bash tools/package-release.sh
```

The script writes `${ZAPRET2_RELEASE_DIR:-/tmp/zapret2-release}/zapret2-<version>.zip` with a
top-level `zapret2/` folder, checks the archive, and prints the SHA-256. The archive contains
exactly one `manifest.json`; the manifest `id` is `zapret2` and its `version` matches the registry
entry.

Only `*.bak` is ignored. The build directory and the ZIP live outside the repository; do not
commit them.

## Submit to the Community Registry

1. Push the plugin to its own public GitHub repository.
2. Create a GitHub Release whose asset is the ZIP from `tools/package-release.sh`.
3. Fork `futureUnd1ground/angelos-community-registry`, add an entry to `plugins.json` with
   `"status": "pending"`, and open a pull request. The entry uses:

```json
{
  "id": "zapret2",
  "name": "zapret2",
  "author": "TriOda26",
  "version": "1.1.0",
  "description": "Вкуси запретный плод: яблоко на панели, обход DPI через zapret2, свои профили, домены, журнал и стратегии.",
  "source": "https://github.com/TriOda26/angel_zapret2/releases/download/v1.1.0/angel_zapret2-1.1.0.zip",
  "sha256": "<sha256 from tools/package-release.sh>",
  "repository": "https://github.com/TriOda26/angel_zapret2",
  "license": "0BSD",
  "themes": ["pixel", "mac"],
  "category": "Network",
  "tags": ["network", "dpi", "zapret", "bypass", "systemd", "profiles"],
  "dependencies": ["zapret2 package", "systemd", "polkit", "journalctl", "pgrep", "notify-send"],
  "permissions": [
    "Manage the zapret2 systemd unit through systemctl",
    "Read the zapret2 journal",
    "Read and write the active domain list and profiles under ~/.config/zapret2",
    "Optionally install a polkit rule and a hostlist symlink through pkexec"
  ],
  "status": "pending"
}
```

The registry maintainer reviews the source, manifest, archive, license, dependencies and
permissions. Do not publish a new build under an already released version number.
