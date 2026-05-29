# Arch package workspace

AUR orchestrator + pacman binary repo.

- `main` branch — maintainer side (nvchecker, bump, release scripts).
- Releases — end-user side (binary pacman repo over GitHub Releases).

## End users

Install `asus-proart-px13-quirks` from AUR on any recent kernel (its `-headers`
must be installed so DKMS can build):

```bash
yay -S asus-proart-px13-quirks   # or build from its AUR PKGBUILD
```

| Package                                    | Purpose                                                  |
|--------------------------------------------|----------------------------------------------------------|
| [`asus-proart-px13-quirks`][1]             | TAS2783/rt721 audio codec patches as DKMS modules + UCM/PipeWire configs + MT7925 btusb autosuspend disable |

[1]: https://aur.archlinux.org/packages/asus-proart-px13-quirks

The TAS2783 codec fixes (CachyOS issue 737) ship as DKMS modules that override
the in-tree `.ko` for whatever kernel is installed, so no forked kernel is
needed. Firmware comes from `linux-firmware-other`.

The GitHub Releases binary pacman repo (`lib/release.sh`) currently publishes
nothing; `asus-proart-px13-quirks` is distributed via AUR.

## Developers

Clone the repo and use `just` to build + install a single package locally without going through AUR. `just` recipes wrap `makepkg`; they do not coordinate releases (see Maintainers).

```bash
git clone https://github.com/fecet/aur && cd aur
just packages              # list buildable packages
just install <pkgname>     # makepkg -si in that package directory
just build   <pkgname>     # build without installing
just clean   <pkgname>     # remove src/, pkg/, *.pkg.tar.zst, build.log
```

Stack recipes install a group of related packages in dep order. Cross-package
deps inside the monorepo are not auto-resolved by `makepkg`, so chains are
written out explicitly in `justfile`:

```bash
just proart-px13           # asus-proart-px13-quirks (PX13 audio DKMS, rides stock kernel)
```

## Maintainers

All packages live inside this monorepo. Each `<pkgname>/` holds PKGBUILD + sources; AUR is a push target, not a source of truth.

```
nvchecker.toml      version sources per package
oldver.json         last-seen versions (committed)
update-all.sh       nvchecker → dispatch per-pkg apply.sh, commits to monorepo
lib/bump.sh         shared helpers for apply.sh
lib/aur-push.sh     publish a pkg to its AUR remote (stateless: clone + overlay + push)
lib/release.sh      build + publish binaries to GH Releases
.github/workflows/  bump.yml (nvchecker daily), build.yml (makepkg per PR)
<pkgname>/          PKGBUILD + sources + optional apply.sh
```

Daily flow:

```bash
# CI auto-opens a `bump/auto` PR if any package has upstream bumps,
# then build.yml runs makepkg on the changed packages as a merge gate.
# Once green, merge, then locally:
git pull
./lib/aur-push.sh <pkg>     # push PKGBUILD to AUR
./lib/release.sh            # build + push binaries to Releases
```

Manual triggers:

```bash
gh workflow run bump.yml                                  # rerun nvchecker now
gh workflow run build.yml -f packages=asus-proart-px13-quirks  # rebuild one (comma-list, empty = all)
./update-all.sh                                           # local nvchecker → apply.sh, no CI
```

Adding a package:

1. `mkdir <pkgname>` with PKGBUILD + .SRCINFO at the top level (no nested git repo).
2. Add to `nvchecker.toml` so version drift gets detected.
3. Optional: `<pkgname>/apply.sh` driving `lib/bump.sh aur_bump_if_changed` for auto-bumps; add to `lib/release.sh` defaults to ship binaries.
4. `./lib/aur-push.sh <pkgname>` to publish to AUR.
