# Shared helpers for AUR package apply.sh scripts.
# Source from a package directory; assumes PKGBUILD lives in cwd.
#
# Contract: apply.sh writes file changes only (no git commit).
# The caller (update-all.sh or CI) commits to the monorepo.

aur_pkgbuild_var() {
    sed -nE "s/^$1=([^ #]+).*/\1/p" PKGBUILD | head -1
}

# Apply a list of KEY=VAL bumps to PKGBUILD if any differ from current.
# On change: reset pkgrel=1, run updpkgsums, regen .SRCINFO. No git ops.
aur_bump_if_changed() {
    local changed=0 kv key val cur
    for kv in "$@"; do
        key=${kv%%=*}; val=${kv#*=}
        cur=$(aur_pkgbuild_var "$key")
        if [[ "$cur" != "$val" ]]; then
            changed=1
            printf '  %-12s %s -> %s\n' "$key" "$cur" "$val"
            sed -i -E "s|^${key}=.*|${kv}|" PKGBUILD
        fi
    done
    if (( !changed )); then
        echo "up-to-date: $(aur_pkgbuild_var pkgver)"
        return 0
    fi
    sed -i -E "s/^pkgrel=.*/pkgrel=1/" PKGBUILD
    updpkgsums
    makepkg --printsrcinfo > .SRCINFO
    echo "applied bump for $(basename "$PWD") -> $(aur_pkgbuild_var pkgver)"
}
