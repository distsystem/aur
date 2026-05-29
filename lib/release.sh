#!/usr/bin/env bash
# Build (if missing) + publish .pkg.tar.zst to distsystem/aur via GitHub Releases.
# Maintains a pacman repo metadata so end users can yay -Syu from:
#   Server = https://github.com/distsystem/aur/releases/latest/download
#
# Usage:
#   release.sh <pkgname> [<pkgname>...]              # publish named package(s); no default
set -euo pipefail

REPO=distsystem/aur
TAG=latest
REPO_NAME=distsystem-aur
AUR_DIR="$HOME/distsystem/aur"

if (( $# > 0 )); then
    pkgs=("$@")
else
    echo "no default packages to publish (binary repo idle); pass package names explicitly" >&2
    exit 0
fi

for pkg in "${pkgs[@]}"; do
    if [[ $pkg == asus-proart-px13-quirks ]]; then
        echo "Refusing to publish $pkg as a binary package: it extracts ASUS firmware during makepkg." >&2
        echo "Install it from AUR/PKGBUILD so the firmware is downloaded and packaged on the user's machine." >&2
        exit 1
    fi
done

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

echo "==> Collecting binaries from ${pkgs[*]}"
for pkg in "${pkgs[@]}"; do
    pkg_dir="$AUR_DIR/$pkg"
    if [[ ! -d $pkg_dir ]]; then
        echo "  !! $pkg dir not found, skip" >&2
        continue
    fi
    cd "$pkg_dir"
    if ! compgen -G '*.pkg.tar.zst' >/dev/null; then
        echo "  building $pkg ..."
        makepkg --noconfirm
    fi
    for f in ./*.pkg.tar.zst; do
        echo "  + $f"
        cp "$f" "$stage/"
    done
done

# Build the pacman repo metadata
cd "$stage"
echo "==> Running repo-add"
repo-add "$REPO_NAME.db.tar.zst" ./*.pkg.tar.zst | tail -n +1
# repo-add creates <repo>.db / <repo>.files as symlinks; replace with real files
# so GitHub Releases serves them as-is (releases don't preserve symlinks)
for ext in db files; do
    if [[ -L $REPO_NAME.$ext ]]; then
        target=$(readlink -f "$REPO_NAME.$ext")
        rm "$REPO_NAME.$ext"
        cp "$target" "$REPO_NAME.$ext"
    fi
done

# Push to GH Releases (single floating tag = "latest")
echo "==> Uploading to $REPO @ tag=$TAG"
if ! gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    gh release create "$TAG" -R "$REPO" \
        --title "Pacman binary repo (latest builds)" \
        --notes "Latest builds of distsystem/aur AUR packages. See README for /etc/pacman.conf setup."
fi
gh release upload "$TAG" -R "$REPO" --clobber \
    ./*.pkg.tar.zst \
    "$REPO_NAME.db" \
    "$REPO_NAME.db.tar.zst" \
    "$REPO_NAME.files" \
    "$REPO_NAME.files.tar.zst"

echo "==> Done"
echo "  Release URL: https://github.com/$REPO/releases/tag/$TAG"
echo "  Base URL:    https://github.com/$REPO/releases/latest/download/"
