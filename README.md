# Herdr config

Personal [Herdr](https://herdr.dev) 0.9.3 setup. Tokyo Night, matched to WezTerm, Starship, and SketchyBar. Sidebar width 40. Two-line project rows (name, then branch and ahead/behind) and three-line agent rows.

The repo is the `~/.config/herdr` directory. Logs, sockets, session snapshots, `plugins.json`, and third-party checkouts are gitignored.

## Layout

| Path | What it is |
| --- | --- |
| `config.toml` | Theme, sidebar, toasts, keybindings |
| `recent-projects.sh` | Popup of git repos edited in the last 30 days |
| `plugins/config/herdr-plugin-agent-quota/sidebar.toml` | Quota display settings |

`recent-projects.sh` looks under `~/dev`, `~/Documents`, `~/Desktop`, `~/scan-and-connect-ios-neu`, and `~/SF`. It uses `/opt/homebrew/bin/fzf`. An existing workspace is focused when a pane's git root matches. Otherwise it creates one.

## Keys

Prefix is Herdr's default, Ctrl-b.

| Key | Action |
| --- | --- |
| prefix+ctrl+p | Recent projects popup |
| prefix+f | File viewer in a split |
| prefix+shift+f | File viewer in a tab |
| prefix+u | Agent usage pane. Press again to close it. `q` or Esc closes it from inside |

## Plugins

Third-party, installed by Herdr:

```bash
herdr plugin install smarzban/herdr-file-viewer
herdr plugin install kwanwooi25/herdr-plugin-agent-quota
```

Pinned when this config was published:

| Plugin | Version | Commit |
| --- | --- | --- |
| `smarzban/herdr-file-viewer` | 1.18.0 | `11de5a123d0efd718e7237de0796de634842b768` |
| `kwanwooi25/herdr-plugin-agent-quota` | 0.1.0 | `6d1149887deb24ad250f13633465dfc1a2e49363` |

The file viewer uses `glow` and `git-delta`. The quota plugin's sidebar reporter stays off. `prefix+u` opens its bottom usage pane for Claude Code, Codex, and Grok.

Local plugins are separate repositories, linked from this config directory:

```bash
git clone https://github.com/varvand/herdr-plugin-agent-spinner.git ~/.config/herdr/plugins/agent-spinner
git clone https://github.com/varvand/herdr-plugin-mac-notify.git ~/.config/herdr/plugins/mac-notify
herdr plugin link ~/.config/herdr/plugins/agent-spinner --enabled
herdr plugin link ~/.config/herdr/plugins/mac-notify --enabled
```

| Repo | Plugin id | Role |
| --- | --- | --- |
| [herdr-plugin-agent-spinner](https://github.com/varvand/herdr-plugin-agent-spinner) | `local.agent-spinner` | `$spin` on working agent rows |
| [herdr-plugin-mac-notify](https://github.com/varvand/herdr-plugin-mac-notify) | `local.mac-notify` | Notification Center when an agent finishes or needs input |
| [herdr-plugin-quota-sidebar](https://github.com/varvand/herdr-plugin-quota-sidebar) | `local.quota-sidebar` | Optional. Quota lines on the last agent card. Not linked here |

In-app toasts stay on (`ui.toast.delivery = "herdr"`). The Mac banners are the notify plugin, not `delivery = "system"`.

## Restore

```bash
git clone https://github.com/varvand/herdr-config.git ~/.config/herdr
chmod +x ~/.config/herdr/recent-projects.sh
herdr server reload-config
```

Then install the plugins above. Reload reports `applied` when the file parses.
