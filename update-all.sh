#!/usr/bin/env bash
# Run nvchecker, then apply each package's bump via its apply.sh and
# commit per-package to the monorepo. Does NOT push to AUR — run
# `lib/aur-push.sh <pkg>` for that.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

nvchecker -c nvchecker.toml >/dev/null 2>&1 || true

mapfile -t diffs < <(nvcmp -c nvchecker.toml -j | jq -r '.[] | "\(.name)\t\(.oldver)\t\(.newver)"')

if (( ${#diffs[@]} == 0 )); then
    echo "all packages up-to-date"
    exit 0
fi

for line in "${diffs[@]}"; do
    IFS=$'\t' read -r name oldver newver <<<"$line"
    if [[ ! -x "$name/apply.sh" ]]; then
        echo "no apply.sh for $name, skipping" >&2
        continue
    fi
    echo "=== $name: $oldver -> $newver ==="
    if ! "$name/apply.sh" "$newver"; then
        echo "!!! apply failed for $name; nvtake skipped" >&2
        continue
    fi

    nvtake -c nvchecker.toml "$name"

    if git diff --quiet -- "$name/" oldver.json; then
        echo "no monorepo changes for $name"
        continue
    fi
    git add "$name/" oldver.json
    git commit -m "chore($name): bump to $newver"
done
