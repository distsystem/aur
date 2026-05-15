#!/usr/bin/env bash
# Push a package's current monorepo HEAD state to its AUR remote.
# Stateless: fresh clone, overlay files, commit, push.
#
# Usage: lib/aur-push.sh <pkgname>
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."
ROOT=$PWD

pkg="${1:?usage: aur-push.sh <pkgname>}"
[[ -f "$pkg/PKGBUILD" ]] || { echo "no PKGBUILD in $pkg" >&2; exit 1; }

if ! git diff --quiet -- "$pkg"; then
    echo "uncommitted changes in $pkg/ — commit first" >&2
    exit 1
fi

msg=$(git log -1 --format=%s -- "$pkg/")
[[ -n "$msg" ]] || { echo "no monorepo commits touching $pkg/" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "==> cloning AUR remote for $pkg"
git clone --quiet "ssh://aur@aur.archlinux.org/$pkg.git" "$tmp"

# Replace AUR's tracked files with our monorepo HEAD state for this pkg
( cd "$tmp" && git ls-files -z | xargs -0 -r rm -f )
git archive HEAD "$pkg" | tar -xC "$tmp" --strip-components=1

cd "$tmp"
git add -A
if git diff --cached --quiet; then
    echo "AUR already in sync with monorepo HEAD for $pkg"
    exit 0
fi

git -c "user.name=$(git -C "$ROOT" config user.name)" \
    -c "user.email=$(git -C "$ROOT" config user.email)" \
    commit -m "$msg"
git push origin HEAD:master
echo "==> pushed $pkg -> AUR"
