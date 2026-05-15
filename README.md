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
sudo pacman -S proart-px13
```

| Package                                    | Purpose                                          |
|--------------------------------------------|--------------------------------------------------|
| [`proart-px13`][1]                         | Meta package — pulls in everything below         |
| [`linux-cachyos-px13`][2] (+ `-headers`)   | CachyOS 7.0.x kernel + 16 TAS2783 codec patches  |
| [`px13-audio-fix`][3]                      | UCM + PipeWire/WirePlumber configs               |

[1]: https://aur.archlinux.org/packages/proart-px13
[2]: https://aur.archlinux.org/packages/linux-cachyos-px13
[3]: https://aur.archlinux.org/packages/px13-audio-fix

`SigLevel = Optional TrustAll` — HTTPS gives transport integrity, authenticity is "trust the maintainer". The pipeline supports signing without consumer-side changes if needed later.

## Maintainers

Each AUR package is its own git repo (remote `aur`), explicitly listed in `.gitignore` so new packages must be opted in.

```
nvchecker.toml      version sources per package
oldver.json         last-seen versions (committed)
update-all.sh       nvchecker → dispatch per-pkg apply.sh
lib/bump.sh         shared helpers for apply.sh
lib/release.sh      build + publish binaries to GH Releases
<pkgname>/          one per AUR package (own git repo)
```

Daily flow:

```bash
./update-all.sh                         # bump + commit per pkg (no push)
cd <pkg> && git push aur main:master    # send PKGBUILD to AUR
./lib/release.sh                        # build + push binaries to Releases
```

Adding a package:

1. `mkdir <pkgname>` with PKGBUILD + .SRCINFO, `git init -b main`, add remote `aur`, first commit, `git push aur main:master`.
2. Add to `nvchecker.toml` and `/<pkgname>/` to `.gitignore`.
3. Optional: `<pkgname>/apply.sh` for auto-bumps; add to `lib/release.sh` defaults to ship binaries.
