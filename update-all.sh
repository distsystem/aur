#!/usr/bin/env bash
# Run nvchecker, then apply each package's bump via its apply.sh.
# Does NOT push — review and `git push aur main:master` from each pkg dir.
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
    if "$name/apply.sh" "$newver"; then
        nvtake -c nvchecker.toml "$name"
    else
        echo "!!! apply failed for $name; nvtake skipped" >&2
    fi
done
