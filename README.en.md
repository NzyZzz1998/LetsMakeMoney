<div align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="LetsMakeMoney turns work time into visible earnings progress">
</div>

<div align="center">
  <a href="README.md">简体中文</a> ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases">Download</a> ·
  <a href="doc/current.md">Current status</a> ·
  <a href="doc/releases/v1.0.1/README.md">v1.0.1 docs</a>
</div>

## Know what today is worth

LetsMakeMoney is a local-first Windows earnings-progress utility. After you configure your monthly salary, rest pattern, and work schedule, it turns an abstract monthly number into today's estimated earnings, work progress, time until the end of the workday, and monthly totals.

The compact earnings window is designed to stay on the desktop. Open the Today and Calendar workbench only when you need more detail. No account is required, and configuration and logs remain on the local device.

<div align="center">
  <img src="assets/readme/workbench.png" width="900" alt="LetsMakeMoney v1.0.1 Today earnings workbench">
</div>

## What it covers

| Daily visibility | Configuration and reliability | Windows experience |
| --- | --- | --- |
| Today's earnings, progress, and time remaining | Three-step onboarding and task-oriented Settings | Draggable compact earnings window |
| Daily schedule, daily rate, hourly rate, monthly total | Saved, unchanged, and failed-with-input-preserved states | Native tray hide, restore, and exit |
| Single weekend, double weekend, alternating weeks, and lunch breaks | Damaged-config recovery and local diagnostics | Verified at 100%, 125%, and 150% DPI |
| Workdays, weekends, holidays, and manual overrides | User-confirmed update checks | No silent updates or unnecessary taskbar entry |

## Current release status

**v1.0.1 Stable** improves calendar accuracy, date overrides, overnight shifts, and money precision on top of the pet-free v1.0 client.

- The current public release is [v1.0.1 Stable](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.1).
- v1.0.1 has completed implementation, independent acceptance, and release closeout.
- It includes offline 2025/2026 mainland China holiday data and supports workday, paid-rest, unpaid-rest, and automatic date handling.
- Earnings advance by the second with authoritative synchronization, while monthly allocation remains exact to the cent.
- v1.0.1 has passed automated gates, real Windows acceptance, and release closeout.
- v1.0.1 does not include pets, transparent pet windows, click-through, pure-pet mode, cloud sync, themes, or an installer.
- Users who need the desktop-pet experience can remain on v0.9 Beta, which is also the explicit rollback baseline.

See the [current status source](doc/current.md) for the latest release identity and checksums.

## Run from source

### Requirements

- Windows 10/11 x86_64
- Node.js 22+
- Rust stable with the MSVC toolchain
- Microsoft Edge WebView2 Runtime

### Start the app

```powershell
git clone https://github.com/NzyZzz1998/LetsMakeMoney.git
cd LetsMakeMoney\apps\windows-v1
npm install
npm run tauri dev
```

### Build the portable package

```powershell
# Run from the repository root
powershell -ExecutionPolicy Bypass -File .\scripts\package_v101.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v101_package.ps1
```

Release outputs are written to `releases\v1.0.1\`. The build and verification flow must not depend on undeclared local paths or private files.

## Data, privacy, and rollback

v1.0.1 stores configuration and logs under:

```text
%APPDATA%\io.letsmakemoney.windows\
```

- No account is required, and salary or schedule data is not uploaded.
- Diagnostic summaries redact local paths and similar machine-specific details.
- The first migration from v0.9 keeps a compatibility backup.
- Exit v1.0 before restoring the old configuration with the [v0.9 rollback guide](doc/releases/v1.0/v0.9-rollback.md).

## Verification

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v101.ps1 -SkipReleaseBuild
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_docs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v101_package.ps1
```

Automated checks cover earnings calculations, configuration transactions, window contracts, the tray bridge, documentation, and package integrity. Real notification-area, taskbar, DPI, and restart-recovery behavior remains part of Windows desktop acceptance.

## Repository map

```text
apps/windows-v1/       Production v1.0 Tauri + React client
shared/                Holiday and shared data
scripts/               Verification, packaging, and compliance checks
doc/current.md         Single internal source of current project truth
doc/releases/v1.0.1/   v1.0.1 PRD, progress, acceptance, and release docs
```

## Contributing

Code, documentation, testing, and Windows-experience contributions are welcome. Start with:

- [Contributing guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security policy](SECURITY.md)

## License

Project-authored code and documentation use the [MIT License](LICENSE). The current v1.0 package contains no pet or other restricted visual assets. Historical v0.9 artwork remains governed by the restricted asset terms in that release. Third-party components and redistribution terms are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
