# LetsMakeMoney

[简体中文](README.md)

LetsMakeMoney is a Windows desktop pet and earnings-progress widget built with Godot 4.7. An orange cat accompanies your workday while the panel estimates today's earnings from your salary and schedule.

## Project status

The latest published baseline is **v0.6 Beta**. The `main` branch is public development for **v0.7 Beta**, which has not completed Acceptance or release. Use [doc/current.md](doc/current.md) and [the v0.7 status](doc/releases/v0.7/current.md) as the current facts.

The supported product platform is Windows x86_64. iOS, macOS, and Android are roadmap research only; iOS has the highest future research priority.

## Features

- Transparent borderless desktop pet with interactive and click-through regions.
- Earnings panel based on monthly salary and working hours.
- Warm compact Settings and first-run Wizard.
- Native Windows tray, taskbar policy, pure-pet mode, and recoverable configuration.
- Local logs and a redacted diagnostic summary.

## Download and install

- **Portable Zip:** download a published Windows x86_64 archive from [GitHub Releases](https://github.com/NzyZzz1998/LetsMakeMoney/releases), extract it to its own directory, and run the executable. Exit the app and back up `%APPDATA%\LetsMakeMoney\config.json` before upgrading.
- **Installer:** under v0.7 development. It will only be attached after Authenticode signing and independent Acceptance. Unsigned test installers are not publicly distributed.

Installed and portable builds share `%APPDATA%\LetsMakeMoney`; do not run them at the same time. Beta updates are never silent: checking, downloading, and installing require user control.

## Run from source

Requirements: Windows x86_64, Godot 4.7 stable, and PowerShell. Native development additionally needs Python 3.12, SCons 4.10.1, and MSYS2 UCRT64 GCC.

```powershell
$env:LMM_GODOT_EXE = "<Godot 4.7 console executable>"
& $env:LMM_GODOT_EXE --path (Resolve-Path .).Path
```

The application stores configuration at `%APPDATA%\LetsMakeMoney\config.json` and logs at `%APPDATA%\LetsMakeMoney\debug.log`.

## Reproducible native build

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_native_dependencies.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -ValidateOnly
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -Target template_debug
```

See [native/windows/README.md](native/windows/README.md) for the locked toolchain, offline cache, Release build, and troubleshooting.

## Verification

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_verification.ps1 -Suite docs
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_verification.ps1 -Suite main
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v06.ps1
```

Real tray clicks, taskbar behavior, DPI, multi-monitor behavior, Authenticode, and startup after a real Windows sign-in remain GUI/manual Acceptance boundaries.

## Contributing and security

Code, documentation, UI design descriptions, tests, and native integration contributions are welcome. v0.7 does not accept external visual asset files. Read [CONTRIBUTING.md](CONTRIBUTING.md), the [Code of Conduct](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md). Report vulnerabilities privately rather than opening a public issue.

## License

- Project-authored source code, build scripts, plain-text configuration, and code documentation use the [MIT License](LICENSE).
- Cat artwork, animation frames, the logo, and application icons are excluded from MIT and use the [Restricted Assets License](ASSETS_LICENSE.md); see [ASSETS_MANIFEST.md](ASSETS_MANIFEST.md).
- Third-party dependencies retain their own licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and `LICENSES/`.

Do not extract restricted visual assets for another project or distribute unofficial binaries containing them without written permission.

## Known Beta limits and rollback

- Windows x86_64 only.
- Real startup after Windows sign-in is still an observed limitation unless a release explicitly records manual evidence.
- Keep the previous stable Zip and a configuration backup. To roll back, exit the current version, restore the backup if needed, and restart the previous release.
