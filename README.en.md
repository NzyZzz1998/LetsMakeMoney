<div align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="LetsMakeMoney keeps today's earnings progress visible on the Windows desktop">
</div>

<div align="center">
  <a href="README.md">简体中文</a> ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases">Download stable</a> ·
  <a href="doc/current.md">Project status</a> ·
  <a href="doc/releases/v1.0.F/README.md">v1.0 Final candidate</a>
</div>

## What is today's work worth?

LetsMakeMoney is a local-first Windows earnings-progress utility. Configure a monthly salary, work schedule, and rest pattern, and it turns that abstract monthly number into today's estimated earnings, work progress, the next stage countdown, and monthly hour summaries.

The Mini view stays quietly on the desktop. Open the full workbench only when you need to adjust a date, record overtime, or inspect the month. No account is required; salary, schedule, overtime, and logs remain on the local machine.

<div align="center">
  <img src="assets/readme/workbench.png" width="900" alt="LetsMakeMoney Today workbench with demonstration data">
  <br>
  <sub>Real Windows interface shown with demonstration data.</sub>
</div>

## Core experience

| See progress at a glance | Understand each workday | Keep the desktop private | Run locally and reliably |
| --- | --- | --- | --- |
| Today's earnings, stage countdown, and progress | Single weekend, double weekend, alternating weeks, and overnight shifts | Mini retracts sensitive amounts at a work-area edge | Transactional configuration, recovery, and diagnostics |
| Daily schedule, daily rate, hourly rate, and monthly total | Official calendar data, estimated years, and manual date overrides | Hover to reveal, leave to retract, tray to recover | Light/dark themes with local persistence |
| Per-day overtime and monthly hour summaries | Paid rest, unpaid rest, and adjusted workdays | Mini hides while the workbench is open | Verified at 100%, 125%, and 150% DPI |

## Start in three steps

1. Download the latest stable portable Zip from [Releases](https://github.com/NzyZzz1998/LetsMakeMoney/releases).
2. Extract it, run `LetsMakeMoney.exe`, and enter your salary, rest pattern, and schedule.
3. Use Mini for live progress; open the workbench, Settings, or onboarding from the system tray.

There is currently no installer or silent update. Update checks only proceed after user confirmation.

## v1.0 Final candidate

| Fact | Current status |
| --- | --- |
| Public stable release | [v1.0.7 Stable](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.7) |
| Candidate on `test` | v1.0.8, internal codename v1.0.F |
| Candidate purpose | Final quality release in the v1.0 line; no tag or Release yet |
| Completed | Automated gates, core GUI, light/dark themes, Windows 11 single-display 100%/125%/150% DPI |
| Evidence still needed | Real notification-area mouse flow and taskbar policy |

The v1.0.8 candidate further closes the v1.0 line:

- Adopts the L2 “Oatmeal Graphite” identity across the app, windows, taskbar, and tray.
- Applies schedule-aware overtime limits and links manual weekend work with overtime in one transaction.
- Protects date and overtime mutations with rollback and legacy-data preservation.
- Unifies TimeField, Combobox, window surfaces, and the privacy strip.
- Uses one current gate for cold start, candidate identity, version facts, and package integrity.

See the [v1.0 Final verification record](doc/releases/v1.0.F/verification.md) for candidate hashes and acceptance boundaries. The `test` branch is for release review and does not replace a published Release.

## Data and privacy

```text
%APPDATA%\io.letsmakemoney.windows\
```

- No account is required; salary, schedule, date overrides, and overtime are not uploaded.
- Diagnostic summaries redact machine-specific paths.
- Mini can retract amounts at the left or right work-area edge and retain only a non-monetary stage label.
- Years outside the bundled official calendar are clearly marked as estimates; the app never invents official holidays or adjusted workdays.
- The historical desktop-pet release remains available as [`v0.9-beta`](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta) and is not part of the current v1.0 product line.

## Support boundary

- **Verified:** Windows 11 x86_64, single display, 100% / 125% / 150% DPI.
- **Runtime requirement:** Microsoft Edge WebView2 Runtime.
- **Best effort:** Windows 10 x86_64; no real-device or VM evidence is currently available.
- **Not verified:** multi-display setups are excluded from the verified-pass statement.

See the [v1.0 Final support matrix](doc/releases/v1.0.F/support-matrix.md) for details.

## Run from source

### Requirements

- Node.js 22+
- Python 3.12
- Rust 1.97.1 with the MSVC toolchain
- Visual Studio 2022 Build Tools with Desktop development with C++
- Windows SDK and Microsoft Edge WebView2 Runtime

```powershell
git clone https://github.com/NzyZzz1998/LetsMakeMoney.git
cd LetsMakeMoney\apps\windows-v1
npm install
npm run tauri dev
```

### Verify and package

```powershell
# Repository root: the only current verification entry point
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1

# Create an isolated local v1.0.8 candidate without replacing published assets
powershell -ExecutionPolicy Bypass -File .\scripts\package_v10f.ps1
```

Local candidates are written only to `.artifacts\candidates\v1.0.8\<candidate-id>\`. A same-named local Zip does not establish GitHub Release identity; published downloads must be verified against the Releases page and its SHA256 file.

## Repository map

```text
apps/windows-v1/       Tauri 2 + React 19 Windows client
shared/                Official calendar and shared data
scripts/               Current gate, packaging, and compliance checks
doc/current.md         Current project fact source
doc/releases/v1.0.F/   v1.0.8 PRD, progress, acceptance, and release preparation
```

## Contributing and license

Code, documentation, tests, and Windows-experience improvements are welcome. Start with the [contributing guide](CONTRIBUTING.md), [Code of Conduct](CODE_OF_CONDUCT.md), and [security policy](SECURITY.md).

Project-authored code and documentation use the [MIT License](LICENSE). v1.0 packages contain no pet or other restricted visual assets. Third-party components and redistribution terms are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
