# Developer recipes for the distsystem/aur monorepo.
#
# Single-package primitives:
#   just                    list recipes
#   just packages           list buildable packages
#   just install PKG        build + install one package (makepkg -si in PKG/)
#   just build   PKG        build only, no install
#   just clean   PKG        rm src/ pkg/ *.pkg.tar.zst build.log in PKG/
#
# Stack recipes (install in dep order):
#   just proart-px13        asus-proart-px13-quirks (PX13 audio DKMS, rides stock kernel)
#
# Maintainer-side helpers (publish to AUR / GitHub Releases) live in lib/.

set shell := ["bash", "-cu"]

default:
    @just --list

packages:
    @find . -maxdepth 2 -name PKGBUILD -printf '%h\n' | sed 's|^\./||' | sort

_check pkg:
    @test -f {{pkg}}/PKGBUILD || { echo "no PKGBUILD in {{pkg}}/" >&2; exit 1; }

install pkg: (_check pkg)
    cd {{pkg}} && makepkg -si

build pkg: (_check pkg)
    cd {{pkg}} && makepkg -s

clean pkg: (_check pkg)
    cd {{pkg}} && rm -rf src/ pkg/ *.pkg.tar.zst *.pkg.tar.xz build.log

# Dependency chains — each stack lists packages in topo order.
# When a stack grows, append `install "..."` entries here; cross-package deps
# stay explicit so the resolution is obvious from the recipe definition.

# PX13 audio stack: CachyOS kernel + UCM/firmware quirks for ASUS ProArt PX13.
proart-px13: (install "asus-proart-px13-quirks")
