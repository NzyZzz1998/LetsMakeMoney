# LetsMakeMoney

[简体中文](README.md) | [Current status](doc/current.md) | [v1.0 docs](doc/releases/v1.0/README.md)

LetsMakeMoney is a local Windows earnings-progress utility. After you enter your monthly salary and work schedule, a compact desktop window keeps today's estimated earnings, work progress, and time until the end of the workday visible. A separate workbench provides Today, Calendar, Settings, and onboarding flows.

v1.0 is rebuilt with Rust, Tauri, and React for a clear, restrained, and reliable Windows desktop experience. Configuration and logs stay on the local device. No account is required, and updates are never installed silently.

## v1.0 scope

- A pet-free compact earnings window that stays out of the taskbar.
- A Today and Calendar workbench for earnings, progress, schedule, and workday rules.
- A three-step onboarding wizard and four task-oriented Settings sections.
- Saved, unchanged, failed-with-input-preserved, reset, and damaged-config recovery states.
- Native tray actions for hide, restore, Settings, and exit.
- A local diagnostic summary, data-folder access, and user-confirmed update checks.
- A Windows x86_64 portable Zip.

v1.0 does not include pets, transparent pet windows, click-through, pure-pet mode, accounts, cloud sync, themes, or an installer. Users who need the previous desktop-pet experience can keep using [v0.9 Beta](https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v0.9-beta).

## Run from source

Requirements:

- Windows 10/11 x86_64
- Node.js 22+
- Rust stable with the MSVC toolchain
- Microsoft Edge WebView2 Runtime

```powershell
cd apps\windows-v1
npm install
npm run tauri dev
```

Build:

```powershell
cd apps\windows-v1
npm run build:web
npm run tauri build -- --no-bundle
```

## Verification

Run `scripts/verify_v10_m0.ps1` through `scripts/verify_v10_m6.ps1`. Real tray, taskbar, DPI, and restart-recovery behavior still requires Windows desktop acceptance; automated checks do not replace that evidence.

## Data and rollback

v1.0 stores local data under:

```text
%APPDATA%\io.letsmakemoney.windows\
```

The first migration from v0.9 keeps a compatibility backup. Exit v1.0 before restoring the old configuration by following the [v0.9 rollback guide](doc/releases/v1.0/v0.9-rollback.md).

## Contributing

Code, documentation, tests, and Windows-experience contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md) first.

## License

Project-authored code and documentation use the [MIT License](LICENSE). The current v1.0 package contains no pet or other restricted visual assets. Historical v0.9 artwork remains governed by the restricted asset terms in that version. Third-party components are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
