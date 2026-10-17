# mise-love

A [mise](https://mise.jdx.dev) tool plugin for [LÖVE](https://love2d.org), the 2D game framework for Lua.

## Install

```bash
mise plugin install love https://github.com/vhespanha/mise-love
mise use love@11.5
love --version
```

`mise ls-remote love` lists the installable versions.

## Supported versions and platforms

The plugin installs the official prebuilt binaries from [LÖVE's GitHub releases](https://github.com/love2d/love/releases), for **11.0 and newer**. Older releases do not ship binaries for every platform, so they are not listed.

| Platform | Release asset | What gets installed |
|---|---|---|
| Linux x86_64, i686 (11.0–11.3) | AppImage | Extracted into `love.AppDir/`, with `bin/love` as a launcher. FUSE is not needed. |
| macOS (Intel and Apple Silicon) | `macos.zip` | `love.app/`, with `bin/love` as a launcher |
| Windows x64, x86 | `win64.zip` / `win32.zip` | `love.exe` and `lovec.exe` |

LÖVE doesn't publish Linux ARM builds. On those machines, use your system package manager or build from source.

On Windows `love.exe` is a GUI program and prints nothing to the console. Use `lovec.exe` when you need console output, for example `lovec --version`.

## Checksums

LÖVE's releases don't publish checksums. The plugin ships its own sha256 hashes for every known release asset in `lib/checksums.lua`, and mise verifies each download against them. A release newer than the table still installs, but without verification, and a warning is printed.

To refresh the table after a new LÖVE release:

```bash
mise run update-checksums
```

## Development

```bash
mise plugin link --force love .   # use this checkout as the love plugin
mise run test                     # install love and check `love --version`
mise run lint                     # stylua, lua-language-server and actionlint
mise run ci                       # lint and test
MISE_DEBUG=1 mise install love@11.5
```

Files:

- `metadata.lua`: plugin metadata
- `lib/releases.lua`: maps a version and platform to a download URL and checksum
- `lib/checksums.lua`: generated sha256 table (`mise run update-checksums`)
- `hooks/available.lua`: lists LÖVE releases from 11.0 on
- `hooks/pre_install.lua`: returns the download URL and checksum
- `hooks/post_install.lua`: extracts the AppImage or rebuilds the macOS app bundle, and writes `bin/love`
- `hooks/env_keys.lua`: adds `bin/` (or the install root on Windows) to `PATH`

## License

MIT
