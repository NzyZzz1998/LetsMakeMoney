<p align="center">
  <img src="assets/readme/hero.png" alt="LetsMakeMoney Windows v0.9 Beta: desktop pet and live earnings progress" width="100%">
</p>

<p align="center">
  <a href="README.md">简体中文</a>
  ·
  <a href="doc/releases/v0.9/README.md">v0.9 Release Record</a>
  ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta">Download v0.9 Beta</a>
  ·
  <a href="CONTRIBUTING.md">Contribute</a>
</p>

## What it is

LetsMakeMoney is a Windows desktop pet built with Godot 4.7. Give it your monthly salary and work schedule, and it keeps today's estimated earnings, work progress, and finishing time visible while the pet reacts to working, awake-rest, and sleeping states.

Configuration and logs stay local. No account is required, and updates are never installed silently.

| Earnings progress | Desktop companion | Native Windows behavior | Local control |
|---|---|---|---|
| Estimates earnings from real workdays, breaks, and schedule | Classic and Duoduo react to the workday rhythm | Tray, transparency, click-through, and pure-pet mode | You control configuration, diagnostics, and updates |

## v0.9 Beta

Windows v0.9 Beta substantially rebuilt salary logic, configuration flows, window UI, and the pet runtime. The locked candidate passed final acceptance. Refer to the [GitHub Release `v0.9-beta`](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta) for the actual publication status, downloads, and checksums.

| Fact | Current record |
|---|---|
| Release line | `main` / Windows v0.9 Beta |
| Status | Final acceptance passed |
| Official download | [v0.9 Beta GitHub Release](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta) |
| Previous stable Beta | [v0.8 Beta](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.8-beta) |
| Stable fallback | v0.8 Beta |

See the [v0.9 version entry](doc/releases/v0.9/README.md), [verification record](doc/releases/v0.9/verification.md), and [manual acceptance boundaries](doc/releases/v0.9/manual-verification.md) for the authoritative facts.

## What changed in v0.9

- **Unified salary and schedule rules:** single-weekend, double-weekend, alternating weeks, eight-hour workdays, lunch breaks, holidays, and adjusted workdays.
- **Rebuilt configuration flows:** Wizard and Settings share draft configuration, defaults, validation, saving, and failure recovery.
- **Reorganized desktop information:** a revised earnings Panel plus a single-instance Today Details window with position memory and safe fallback.
- **Upgraded the pet runtime:** general package validation and corruption fallback, the retained Classic path, and Duoduo integration.
- **Improved interaction state:** event-driven animation, state-aware clicks, hold-to-drag behavior, and dynamic hit regions.
- **Protected Windows-specific behavior:** tray recovery, transparent windows, click-through, context menus, and pure-pet mode.

## Acceptance boundaries

Automated regression, candidate startup, the primary windows at 100% DPI, and directed Classic, Duoduo, Panel, Today Details, and modal click-through checks passed.

The following items are **not recorded as passed**:

- Full-window checks at real Windows 125% and 150% DPI.
- Real mouse interaction with the Windows notification-area icon and taskbar entry.
- The 500 ms hold-to-run transition and release recovery.
- Complete visual-quality review of every Classic and Duoduo state and event action.
- Real-desktop fallback behavior for a deliberately corrupted pet package.
- A continuous two-hour GUI stability run.

These boundaries are not recorded as passed, but they do not block portable Beta distribution under the approved acceptance policy.

## How to try it

### Download and run

1. Download the **Windows x86_64** portable Zip from the [v0.9 Beta GitHub Release](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta).
2. Extract it into its own directory.
3. Run `LetsMakeMoney.exe` and complete the salary and schedule Wizard.
4. Right-click the pet to open Today Details, Settings, or reconfiguration. Use the system tray to recover hidden windows.

### Release integrity

v0.9 passed final acceptance. Verify the download against the `SHA256SUMS.txt` attached to the GitHub Release; do not substitute a local `build/` directory, an older Zip, or a Git HEAD alone for an official release asset.

> Windows may show an unknown-publisher warning. Public executables are not Authenticode-signed. Download stable packages only from this repository's GitHub Releases and compare the supplied SHA-256.

Local data:

```text
%APPDATA%\LetsMakeMoney\config.json
%APPDATA%\LetsMakeMoney\debug.log
```

Exit the app and back up `config.json` before upgrading. Portable and test-installed builds share this data directory and should not run at the same time.

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

# v0.9 aggregate verification
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v09.ps1

# Build and verify a v0.9 candidate package
powershell -ExecutionPolicy Bypass -File .\scripts\package_v09.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v09_package.ps1

# The stable fallback remains protected by v0.8 verification
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v08.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\package_v08.ps1
```

See [scripts/README.md](scripts/README.md) for script tiers and maintenance boundaries. Automated checks protect contracts; Windows tray, taskbar, DPI, and click-through behavior still require real desktop acceptance.

## Release history

- **v0.6 Beta:** shared controls, diagnostics, and Windows edge-path stabilization.
- **v0.7 Beta:** open-source governance, reproducible builds, and portable distribution.
- **v0.8 Beta:** the salary-calendar, lunch-break, and work-schedule baseline.
- **v0.9 Beta:** UI, configuration, and pet-runtime reconstruction; final acceptance passed and public Beta distribution enabled.

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
