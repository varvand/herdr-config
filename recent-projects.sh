#!/usr/bin/env python3
"""Open a Herdr workspace for a repo edited in the last 30 days.

Ranked by newest source file, not by how often the directory was visited.
Skips dependency, build, backup, and temp directories.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

DAYS = 30
FZF = "/opt/homebrew/bin/fzf"
SKIP_DIRS = {
    ".git",
    ".build",
    ".cache",
    ".gradle",
    ".next",
    ".venv",
    "DerivedData",
    "Pods",
    "__pycache__",
    "backups",
    "build",
    "cache",
    "coverage",
    "dist",
    "logs",
    "node_modules",
    "output",
    "target",
    "temp",
    "tmp",
    "venv",
}
SKIP_FILES = {".DS_Store", ".localized"}
ROOTS = [
    Path.home() / "dev",
    Path.home() / "Documents",
    Path.home() / "Desktop",
    Path.home() / "scan-and-connect-ios-neu",
    Path.home() / "SF",
]


def git_root(path: str) -> str | None:
    if not path or not os.path.isdir(path):
        return None
    try:
        out = subprocess.check_output(
            ["git", "-C", path, "rev-parse", "--show-toplevel"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    return os.path.realpath(out) if out else None


def age_label(seconds: float) -> str:
    hours = seconds / 3600
    if hours < 1:
        return "<1h"
    if hours < 48:
        return f"{round(hours)}h"
    return f"{round(hours / 24)}d"


def newest_edit(repo: Path, cutoff: float) -> float:
    best = 0.0
    for dirpath, dirnames, filenames in os.walk(repo):
        dirnames[:] = [name for name in dirnames if name not in SKIP_DIRS]
        for name in filenames:
            if name in SKIP_FILES or name.endswith(".pyc"):
                continue
            try:
                modified = (Path(dirpath) / name).stat().st_mtime
            except OSError:
                continue
            if modified > best:
                best = modified
    return best if best >= cutoff else 0.0


def recent_repos() -> list[tuple[float, str, str]]:
    import time

    now = time.time()
    cutoff = now - DAYS * 86400
    found: dict[str, float] = {}
    for root in ROOTS:
        if not root.is_dir():
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            base = Path(dirpath)
            if ".git" in dirnames or ".git" in filenames:
                repo = os.path.realpath(base)
                if repo not in found:
                    edited = newest_edit(base, cutoff)
                    if edited:
                        found[repo] = edited
            dirnames[:] = [name for name in dirnames if name not in SKIP_DIRS and name != ".git"]
    rows = [(modified, Path(path).name, path) for path, modified in found.items()]
    rows.sort(reverse=True)
    return rows


def herdr_bin() -> str:
    return os.environ.get("HERDR_BIN_PATH") or "herdr"


def workspace_for(path: str) -> str | None:
    wanted = os.path.realpath(path)
    raw = subprocess.check_output([herdr_bin(), "api", "snapshot"], text=True)
    panes = json.loads(raw)["result"]["snapshot"]["panes"]
    for pane in panes:
        if git_root(pane.get("cwd") or "") == wanted:
            return pane["workspace_id"]
    return None


def open_project(path: str) -> None:
    herdr = herdr_bin()
    existing = workspace_for(path)
    if existing:
        subprocess.check_call([herdr, "workspace", "focus", existing])
        return
    subprocess.check_call(
        [herdr, "workspace", "create", "--label", Path(path).name, "--cwd", path]
    )


def picker_lines(rows: list[tuple[float, str, str]]) -> str:
    import time

    now = time.time()
    lines = []
    for modified, name, path in rows:
        lines.append(f"{age_label(now - modified):>4}\t{name}\t{path}")
    return "\n".join(lines) + "\n"


def choose(rows: list[tuple[float, str, str]]) -> str | None:
    if not os.path.isfile(FZF):
        print("fzf is not installed at /opt/homebrew/bin/fzf", file=sys.stderr)
        return None
    command = [
        FZF,
        "--reverse",
        "--no-sort",
        "--cycle",
        "--delimiter=\t",
        "--with-nth=1,2",
        "--accept-nth=3",
        "--info=hidden",
        "--prompt=projects › ",
        f"--header=last {DAYS} days   ·   enter opens   ·   esc closes",
        "--preview",
        "python3 -c 'import sys,subprocess; path=sys.argv[1].split(chr(9),2)[-1]; subprocess.run([\"git\",\"-C\",path,\"-c\",\"color.ui=always\",\"status\",\"-sb\"])' {}",
        "--preview-window=down,40%,border-top",
        "--color=bg+:#24283b,fg:#c0caf5,hl:#7aa2f7,fg+:#c0caf5,hl+:#7dcfff,info:#565f89,prompt:#7aa2f7,pointer:#bb9af7,marker:#9ece6a,spinner:#bb9af7,header:#565f89,border:#33467c,preview-border:#33467c",
    ]
    completed = subprocess.run(command, input=picker_lines(rows), text=True, stdout=subprocess.PIPE)
    if completed.returncode != 0:
        return None
    selected = completed.stdout.strip()
    return selected or None


def main() -> int:
    os.environ["PATH"] = "/opt/homebrew/bin:" + os.environ.get("PATH", "")
    rows = recent_repos()
    if os.environ.get("HERDR_RECENT_LIST") == "1":
        sys.stdout.write(picker_lines(rows) if rows else "")
        return 0
    resolve = os.environ.get("HERDR_RECENT_RESOLVE")
    if resolve:
        print(workspace_for(resolve) or "CREATE")
        return 0
    if not rows:
        print(f"No git repos with edits in the last {DAYS} days.")
        if sys.stdin.isatty():
            try:
                input("press enter")
            except EOFError:
                pass
        return 0
    selected = choose(rows)
    if not selected:
        return 0
    try:
        open_project(selected)
    except subprocess.CalledProcessError as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
