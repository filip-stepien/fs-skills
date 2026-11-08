#!/usr/bin/env sh
set -eu
scope=${1:-project}
case "$scope" in project|user) ;; *) echo "Usage: $0 [project|user]" >&2; exit 2;; esac
repo=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
if [ "$scope" = project ]; then target="$PWD/.claude/skills"; else target="${HOME:?HOME is not set}/.claude/skills"; fi
mkdir -p "$target"
for source in "$repo"/skills/*; do
  [ -d "$source" ] || continue
  name=${source##*/}
  mkdir -p "$target/$name"
  cp -R "$source"/. "$target/$name"/
done
printf 'Installed fs-skills for Claude Code at %s\n' "$target"

