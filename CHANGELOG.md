# Changelog

## 1.1.0 — 2026-10-27

- License changed to 0BSD (Zero-Clause BSD): no attribution requirement, no warranty.
- The pixel apple: brown branch, green leaf, C1 silhouette; the bottom-right bite while the
  bypass is on, a chomp on toggle and a four-frame growth on a profile change.
- Compact popup: status, Start/Stop, the user's profiles, Journal/Domains/More; the 2×2 More
  grid holds Restart, Strategies, Config and Settings. The nfqws2, Service and Since rows are
  gone from the popup.
- Settings follow the plugin pattern: a `PanelSummary` first, then Appearance, Profiles, Domains,
  Strategies, Service and About. The Service group has a short status, folder/unit pickers,
  autostart, restart, hostlist, polkit helper and diagnostics.
- Configurable `rootDir` and `unitName`, auto-detection of common installs, a folder picker and
  a one-time “service not found” dialog with install instructions.
- The angel and the demon comment on actions in their own voices; the first occurrence of each
  event is guaranteed, later ones are random. The voices can be switched off in Settings.
- Profiles are the user's own: the popup, menu and launcher show only the profiles found in
  `~/.config/zapret2/profiles`; no profiles or strategies ship with the plugin.
- `scripts/setup-polkit.sh` accepts `--root` and `--unit` for a custom installation.
