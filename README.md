# Arch package workspace

AUR orchestrator + pacman binary repo.

- `main` branch — maintainer side (nvchecker, bump, release scripts).
- Releases — end-user side (binary pacman repo over GitHub Releases).

## End users

Add to `/etc/pacman.conf`:

```ini
[distsystem-aur]
SigLevel = Optional TrustAll
Server = https://github.com/distsystem/aur/releases/latest/download
```

```bash
sudo pacman -Sy
sudo pacman -S linux-cachyos-px13 linux-cachyos-px13-headers
```

Build `asus-proart-px13-quirks` from its AUR `PKGBUILD`. The package downloads
the ASUS SmartAMP installer and extracts the TAS2783 firmware on the user's
machine, so this repo does not publish a binary package for it.

| Package                                    | Purpose                                                  |
|--------------------------------------------|----------------------------------------------------------|
| [`asus-proart-px13-quirks`][1]             | TAS2783 firmware/audio configs + MT7925 btusb autosuspend disable; build from AUR |
| [`linux-cachyos-px13`][2] (+ `-headers`)   | CachyOS 7.0.x kernel + 16 TAS2783 codec patches          |

[1]: https://aur.archlinux.org/packages/asus-proart-px13-quirks
[2]: https://aur.archlinux.org/packages/linux-cachyos-px13

`SigLevel = Optional TrustAll` — HTTPS gives transport integrity, authenticity is "trust the maintainer". The pipeline supports signing without consumer-side changes if needed later.

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
gh workflow run build.yml -f packages=linux-cachyos-px13  # rebuild one (comma-list, empty = all)
./update-all.sh                                           # local nvchecker → apply.sh, no CI
```

Adding a package:

1. `mkdir <pkgname>` with PKGBUILD + .SRCINFO at the top level (no nested git repo).
2. Add to `nvchecker.toml` so version drift gets detected.
3. Optional: `<pkgname>/apply.sh` driving `lib/bump.sh aur_bump_if_changed` for auto-bumps; add to `lib/release.sh` defaults to ship binaries.
4. `./lib/aur-push.sh <pkgname>` to publish to AUR.
