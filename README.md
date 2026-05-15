# distsystem/aur

Personal AUR orchestrator and pacman binary repo, in one repo.

```
                    ┌─────────────────────────────────────┐
                    │  distsystem/aur  (this repo)             │
                    └─────────┬───────────────────┬───────┘
                              │                   │
                       main branch          Releases/latest
                       ───────────          ──────────────
                       maintainer           end users
                       (nvchecker,           (pacman binary
                        bump.sh,              repo over
                        release.sh)           GitHub Releases)
```

## End users — install binaries without compiling

Add to `/etc/pacman.conf`:

```ini
[fecet-bin]
SigLevel = Optional TrustAll
Server = https://github.com/distsystem/aur/releases/latest/download
```

Then:

```bash
sudo pacman -Sy
sudo pacman -S proart-px13          # PX13 hardware meta package
```

Currently shipped binaries:

| Package                       | AUR                                                     | Purpose                                              |
|-------------------------------|---------------------------------------------------------|------------------------------------------------------|
| `proart-px13`                 | <https://aur.archlinux.org/packages/proart-px13>        | Meta: pulls in everything below                      |
| `linux-cachyos-px13`          | <https://aur.archlinux.org/packages/linux-cachyos-px13> | CachyOS 7.0.x kernel + 16 TAS2783 codec patches      |
| `linux-cachyos-px13-headers`  | (same)                                                  | Headers for DKMS                                     |
| `px13-audio-fix`              | <https://aur.archlinux.org/packages/px13-audio-fix>     | UCM + PipeWire/WirePlumber configs                   |

Signing is disabled (`SigLevel = Optional TrustAll`). HTTPS to GitHub
gives transport integrity; package authenticity is "trust the
maintainer". If signing matters later, the pipeline supports it
without consumer-side changes.

## Maintainers — orchestrator layout

Each AUR package is its own git repo under this directory, listed
explicitly in `.gitignore` so new packages must be opted in. The top
level holds shared orchestration:

```
~/aur/
├── nvchecker.toml          declarative version sources per package
├── oldver.json             last-seen versions (committed)
├── newver.json             nvchecker scratch (gitignored)
├── update-all.sh           nvchecker → per-pkg apply.sh dispatcher
├── lib/
│   ├── bump.sh             shared helpers for apply.sh scripts
│   └── release.sh          build + publish binaries to GH Releases
├── <pkgname>/              one per AUR package (independent git repo,
│                            git remote `aur`, NOT tracked by this repo)
└── README.md
```

### Daily flow

```bash
./update-all.sh             # nvchecker → dispatch to each <pkg>/apply.sh
                            #   which bumps + commits + does NOT push
                            # review each pkg dir, then:
cd <pkg>
git push aur main:master    # send PKGBUILD update to AUR

./lib/release.sh            # build .pkg.tar.zst + push to distsystem/aur Releases
                            # end users get them on next pacman -Sy
```

### Adding a new AUR package

1. `mkdir <pkgname> && cd <pkgname>` with PKGBUILD + .SRCINFO.
2. `git init -b main && git remote add aur ssh://aur@aur.archlinux.org/<pkgname>.git`.
3. First commit + `git push aur main:master`.
4. Add `<pkgname>` to nvchecker.toml.
5. Add `/<pkgname>/` to root `.gitignore`.
6. Optionally write `<pkgname>/apply.sh` for automated bumps.

### Adding a package to the binary repo

Add the pkgname to `lib/release.sh` defaults, then `./lib/release.sh
<pkgname>` to push its binaries.

## Deprecated

`linux-cachyos-rc-px13` (AUR) is marked DEPRECATED on AUR — 7.1-rc
kernel base has a `btmtk` regression that breaks MT7925 Bluetooth.
Use `linux-cachyos-px13` (7.0.x stable + same audio patches) instead.
Not shipped via this binary repo.
