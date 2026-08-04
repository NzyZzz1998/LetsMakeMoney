<div align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="LetsMakeMoney turns work time into visible earnings progress">
</div>

<div align="center">
  <a href="README.md">简体中文</a> ·
  <a href="https://github.com/NzyZzz1998/LetsMakeMoney/releases">Download</a> ·
  <a href="doc/current.md">Current status</a> ·
  <a href="doc/releases/v1.0.6/progress_v1.0.6.md">v1.0.6 bugfix status</a>
</div>

## Know what today is worth

LetsMakeMoney is a local-first Windows earnings-progress utility. After you configure your monthly salary, rest pattern, and work schedule, it turns an abstract monthly number into today's estimated earnings, work progress, time until the end of the workday, and monthly totals.

The compact earnings window is designed to stay on the desktop. Open the Today and Calendar workbench only when you need more detail. No account is required, and configuration and logs remain on the local device.

<div align="center">
  <img src="assets/readme/workbench.png" width="900" alt="LetsMakeMoney Windows Today earnings workbench">
</div>

## What it covers

| Daily visibility | Configuration and reliability | Windows experience |
| --- | --- | --- |
| Today's earnings, progress, and time remaining | Three-step onboarding and task-oriented Settings | Draggable compact earnings window |
| Daily schedule, daily rate, hourly rate, monthly total | Saved, unchanged, and failed-with-input-preserved states | Native tray hide, restore, and exit |
| Single weekend, double weekend, alternating weeks, and rest periods | Damaged-config recovery and local diagnostics | Verified at 100%, 125%, and 150% DPI |
| Workdays, weekends, holidays, and manual overrides | User-confirmed update checks | No silent updates or unnecessary taskbar entry |

## Current release status

The current public release is [**v1.0.6 Stable**](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.6). This maintenance release completed independent acceptance, required CI, a clean-source build, GitHub Release publication, and a round-trip verification of the published assets.

- The v1.0.6 release source commit is `51e4c08da5260af9b9f4808c4f6d29591319e655`.
- The portable Zip SHA256 is `AEE4BC4A41D3839E421138D0B152EA5A8B0FBDC60C5B189EA11790DE4ED8B66A`; the Release contains only the portable Zip and `SHA256SUMS.txt`.
- v1.0.6 fixes stale per-WebView theme state and adds first-frame, cross-window ThemeSession, configuration-hydration, and native-close transaction gates. See the [v1.0.6 status](doc/releases/v1.0.6/progress_v1.0.6.md).
- The Mini window can retract salary details at the left or right work-area edge and can be revealed by hover or the system tray while retaining its normal saved position.
- Years not covered by official calendar data use an explicitly labeled work-pattern estimate; the app never invents official holidays or adjusted workdays.
- Hidden windows pause local ticks and authoritative synchronization, then recalibrate immediately when restored.
- Windows sleep recovery, forward and backward system-time jumps, a real time-zone switch, and a continuous 120-minute run have been accepted.
- Stage copy, timeline alignment, overnight ownership, adjusted-workday sources, compound calendar states, and light/dark themes retain the v1.0.2 contracts.
- v1.0.6 does not include pets, cloud sync, an installer, system-following themes, or custom themes.
- Users who need the desktop-pet experience can remain on v0.9 Beta, which is also the explicit rollback baseline.

See the [current status source](doc/current.md) for the latest release identity and checksums.

## Run from source

### Requirements

- Windows 11 x86_64 (the verified v1.0.7 environment is single-display; real 125%/150% DPI evidence remains a final-candidate gate)
- Windows 10 x86_64 is best-effort only because no real device or VM evidence is currently available
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
# Run from the repository root to create an isolated v1.0.7 development candidate
powershell -ExecutionPolicy Bypass -File .\scripts\package_v107.ps1
```

v1.0.7 development candidates are written only to `.artifacts\candidates\v1.0.7\<candidate-id>\`; they do not overwrite `releases\` or a GitHub-downloaded cache. The flow must not depend on undeclared local paths or private files, and a same-named local file does not establish GitHub Release identity. The current public download remains v1.0.6 Stable.

See the [v1.0.7 support matrix](doc/releases/v1.0.7/support-matrix.md) for the exact environment boundary. Multi-display and Windows 10 are excluded from the v1.0.7 verified-pass statement.

## Data, privacy, and rollback

The v1.0 Windows line stores configuration and logs under:

```text
%APPDATA%\io.letsmakemoney.windows\
```

- No account is required, and salary or schedule data is not uploaded.
- Diagnostic summaries redact local paths and similar machine-specific details.
- The first migration from v0.9 keeps a compatibility backup.
- Exit v1.0 before restoring the old configuration with the [v0.9 rollback guide](doc/releases/v1.0/v0.9-rollback.md).

## Verification

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v10_docs.ps1
# After packaging a v1.0.7 development candidate, pass the emitted Zip path to the M7 gate
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v107.ps1 -Milestone M7 -CandidatePath <v1.0.7 candidate Zip path>
# Verify a controlled candidate independently; published mode additionally requires the tag, Release URL, and downloaded checksum file
powershell -ExecutionPolicy Bypass -File .\scripts\verify_v107_package.ps1 -Mode candidate -PackagePath <candidate Zip path> -ExpectedSourceHead <40-character commit> -ExpectedZipSha256 <SHA256>
```

Automated checks cover earnings calculations, configuration transactions, window contracts, the tray bridge, documentation, and package integrity. Real notification-area, taskbar, DPI, and restart-recovery behavior remains part of Windows desktop acceptance.

## Repository map

```text
apps/windows-v1/       Production v1.0 Tauri + React client
shared/                Holiday and shared data
scripts/               Verification, packaging, and compliance checks
doc/current.md         Single internal source of current project truth
doc/releases/v1.0.6/   v1.0.6 theme bugfix review, progress, and verification docs
```

## Contributing

Code, documentation, testing, and Windows-experience contributions are welcome. Start with:

- [Contributing guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security policy](SECURITY.md)

## License

Project-authored code and documentation use the [MIT License](LICENSE). The current v1.0 package contains no pet or other restricted visual assets. Historical v0.9 artwork remains governed by the restricted asset terms in that release. Third-party components and redistribution terms are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
