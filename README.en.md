<div align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="LetsMakeMoney v1.1.0: local earnings progress with the optional Classic desktop companion">
</div>

<div align="center">
  <a href="README.md">简体中文</a> ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases/latest">Download stable</a> ·
  <a href="doc/current.md">Project status</a> ·
  <a href="doc/releases/v1.1.0/release-notes.md">v1.1.0 release notes</a>
</div>

## What is today's work worth?

LetsMakeMoney is a local-first Windows earnings-progress utility. Configure a monthly salary, schedule, and rest pattern, and it turns that abstract monthly number into today's estimated earnings, work progress, stage countdowns, and monthly hour summaries.

v1.1.0 brings back the optional Classic orange cat companion. Mini and Classic are mutually exclusive: Mini remains the default, while Classic can be enabled in Settings. No account is required; salary, schedule, date overrides, overtime, and logs remain on the local machine.

## Real interface

<div align="center">
  <img src="assets/readme/workbench.png" width="900" alt="LetsMakeMoney Today workbench with demonstration data">
  <br>
  <sub>Real Windows workbench. Amounts, dates, and hours are demonstration data.</sub>
</div>

<table>
  <tr>
    <th align="center">Mini earnings view</th>
    <th align="center">Earnings calendar and monthly hours</th>
  </tr>
  <tr>
    <td align="center"><img src="assets/readme/mini.png" width="344" alt="LetsMakeMoney Mini earnings view"></td>
    <td align="center"><img src="assets/readme/calendar.png" width="560" alt="LetsMakeMoney earnings calendar, date states, and monthly hour summary"></td>
  </tr>
</table>

## v1.1.0: Classic returns

- **Three companion states:** `working`, `awake_rest`, and `sleeping` follow the authoritative work state.
- **State-aware interaction:** each state has its own click response; hold for 500ms to run, reverse direction immediately, and settle on release.
- **Transparent desktop interaction:** visible pixels are interactive while transparent pixels pass through.
- **Mini / Classic choice:** the active companion hides while the workbench is open and restores to the previous mode afterward.
- **Core-app isolation:** package or runtime failures safely fall back to Mini without blocking earnings, calendar, Settings, or tray workflows.

## Core experience

| See earnings progress | Understand each workday | Keep the desktop private | Run locally and reliably |
| --- | --- | --- | --- |
| Today's earnings, progress, and stage countdowns | Single weekend, double weekend, alternating weeks, and overnight shifts | Mini retracts sensitive amounts at a work-area edge | Transactional configuration, recovery, and diagnostics |
| Daily schedule, rates, and monthly total | Official calendars, estimated years, and date overrides | Hover to reveal, leave to retract, tray to recover | Light/dark themes with local persistence |
| Per-day overtime and monthly hour summaries | Paid rest, unpaid rest, and adjusted workdays | Desktop companion hides with the workbench | Verified at 100%, 125%, and 150% DPI |
| Mini / Classic choice | State-aware clicks and hold-to-drag | Transparent pixels pass through | Package failures fall back to Mini |

## Start in three steps

1. Download `LetsMakeMoney-v1.1.0-windows-x86_64.zip` from [Releases](https://github.com/NzyZzz1998/LetsMakeMoney/releases/latest).
2. Extract the archive completely, run `LetsMakeMoney.exe`, and enter your salary, rest pattern, and schedule.
3. Use Mini for live progress or switch to Classic in Settings; open the workbench, Settings, and onboarding from the system tray.

> [!NOTE]
> LetsMakeMoney currently ships as a portable Zip. Windows SmartScreen may show “Unknown publisher” because the executable is not code-signed. Download only from this repository and verify the SHA256 checksum.

## Data and privacy

```text
%APPDATA%\io.letsmakemoney.windows\
```

- No account is required; salary, schedule, date overrides, and overtime are not uploaded.
- Diagnostic summaries redact machine-specific paths.
- Mini can retract amounts at the left or right work-area edge and retain only a non-monetary stage label.
- Unsupported calendar years are clearly marked as estimates; the app never invents official holidays or adjusted workdays.
- Classic is enabled only after an explicit user choice. Its animation assets are not MIT-licensed; see the [visual asset license](ASSETS_LICENSE.md).

## Support boundary

- **Verified:** Windows 11 x86_64, single display, 100% / 125% / 150% DPI.
- **Best effort:** Windows 10 x86_64; no real-device or VM evidence is currently available.
- **Not verified:** multi-display setups are excluded from the verified-pass statement.
- **Runtime requirement:** Microsoft Edge WebView2 Runtime.

See the [v1.1.0 verification record](doc/releases/v1.1.0/verification.md) for the exact candidate identity, hashes, and acceptance boundaries.

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
# Repository root: the only current verification gate
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1

# Create an isolated candidate without replacing published assets
powershell -ExecutionPolicy Bypass -File .\scripts\package_v110.ps1
```

## Repository map

```text
apps/windows-v1/       Tauri 2 + React 19 Windows client
shared/                Official calendar and shared data
scripts/               Current gate, packaging, and compliance checks
doc/current.md         Current project fact source
doc/releases/v1.1.0/   v1.1.0 acceptance and release evidence
```

## Contributing and license

Code, documentation, tests, and Windows-experience improvements are welcome. Start with the [contributing guide](CONTRIBUTING.md), [Code of Conduct](CODE_OF_CONDUCT.md), and [security policy](SECURITY.md).

Project-authored code and documentation use the [MIT License](LICENSE). The Classic cat and its derived runtime assets are not MIT-licensed and may only ship with official LetsMakeMoney source and binaries; see [ASSETS_LICENSE.md](ASSETS_LICENSE.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
