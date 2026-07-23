<p align="center">
  <img src="assets/readme/hero.png" alt="LetsMakeMoney: a Windows earnings-progress desktop companion with an orange cat" width="100%">
</p>

<p align="center">
  <a href="README.md">简体中文</a>
  ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta">Download v0.8 Beta</a>
  ·
  <a href="CONTRIBUTING.md">Contribute</a>
</p>

## What it is

LetsMakeMoney is a Windows desktop pet built with Godot 4.7. Give it your monthly salary and work schedule, and it keeps today's estimated earnings, work progress, and finishing time visible while an orange cat accompanies your day.

Configuration and logs stay local. No account is required, and updates are never installed silently.

| Earnings progress | Desktop companion | Native Windows behavior | Local control |
|---|---|---|---|
| Estimates earnings from real workdays, breaks, and schedule | The cat reacts to work and rest states | Tray, transparency, click-through, and pure-pet mode | You control configuration, diagnostics, and updates |

## Current release

The current public release is **v0.8 Beta** for **Windows x86_64**, distributed as a portable Zip through GitHub Releases.

- Salary estimates use actual workdays in the calendar month and deduct lunch breaks.
- Single-weekend, double-weekend, and alternating-week schedules are supported.
- The desktop pet, earnings panel, first-run Wizard, Settings, tray recovery, and pure-pet mode remain available.
- Automated regressions and real Windows desktop acceptance have completed.
- Multi-monitor behavior, a clean Windows user or VM, Authenticode/SmartScreen, and startup after a real sign-in remain explicitly unverified Beta boundaries.
- v0.9 is a frozen development candidate, not the current stable release.

See [current status](doc/current.md), [v0.8 verification](doc/releases/v0.8/verification.md), and [v0.8 release notes](doc/releases/v0.8/release-notes.md) for the authoritative record.

## Quick start

1. Download the Windows x86_64 portable Zip from the [v0.8 Beta Release](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta).
2. Extract it into its own directory.
3. Run `LetsMakeMoney.exe` and complete the salary and schedule Wizard.
4. Right-click the pet to open today's details, Settings, or reconfiguration. Use the system tray to recover hidden windows.

> Windows may show an unknown-publisher warning. v0.8 does not publish an installer, and its executable is not Authenticode-signed. Download only from this repository and compare the SHA-256 supplied with the Release.

Local data:

```text
%APPDATA%\LetsMakeMoney\config.json
%APPDATA%\LetsMakeMoney\debug.log
```

Exit the app and back up `config.json` before upgrading. Portable and test-installed builds share this data directory and should not run at the same time.

## Product experience

- **Live earnings receipt:** today's earnings, hourly rate, work progress, and schedule.
- **Orange desktop cat:** a transparent borderless window with dragging, context menus, and basic interaction.
- **Click-through transparency:** transparent pixels do not block the desktop; modal windows temporarily protect interaction.
- **Pure-pet mode:** hides the taskbar entry while preserving a tray recovery path.
- **Schedule configuration:** lunch breaks and multiple rest patterns with safe migration from older configuration.
- **Local diagnostics:** log rotation, corrupted-configuration recovery, and a redacted diagnostic summary.

## Run from source

Requirements:

- Windows x86_64
- Godot 4.7 stable
- PowerShell
- MSYS2 UCRT64, Python 3.12, and SCons 4.10.1 for local native-bridge builds

```powershell
$env:LMM_GODOT_EXE = "<Godot 4.7 console executable>"
& $env:LMM_GODOT_EXE --path (Resolve-Path .).Path
```

Build the Windows native bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_native_dependencies.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -ValidateOnly
powershell -ExecutionPolicy Bypass -File .\scripts\build_native_windows.ps1 -Target template_debug
```

See the [Windows native build guide](native/windows/README.md) for locked dependencies, offline caching, and troubleshooting.

## Verification

```powershell
# Documentation and public-compliance checks
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_verification.ps1 -Suite docs

# Active main verification suite
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_verification.ps1 -Suite main

# v0.8 release regression
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v08.ps1

# v0.8 portable package and package verification
powershell -ExecutionPolicy Bypass -File .\scripts\package_v08.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v08_package.ps1
```

See [scripts/README.md](scripts/README.md) for script tiers and maintenance boundaries. Automated checks protect contracts; Windows tray, taskbar, DPI, and click-through behavior still require real desktop acceptance.

## Contributing

Code, documentation, tests, UI specifications, and Windows native integration contributions are welcome. Start with:

- [Contributing guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security policy](SECURITY.md)
- [Current project status](doc/current.md)

Report vulnerabilities privately as described in `SECURITY.md`; do not open public issues containing sensitive information.

## License

- Project-authored source code, build scripts, plain-text configuration, and code documentation use the [MIT License](LICENSE).
- Cat artwork, animation frames, the logo, and application icons are excluded from MIT and use the [Restricted Assets License](ASSETS_LICENSE.md); see [ASSETS_MANIFEST.md](ASSETS_MANIFEST.md).
- Third-party dependencies retain their own licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and `LICENSES/`.

Do not extract restricted visual assets for another project or distribute unofficial binaries containing them without written permission.
