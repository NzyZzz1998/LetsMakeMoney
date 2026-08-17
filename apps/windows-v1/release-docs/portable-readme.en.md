# LetsMakeMoney v{{VERSION}} Portable

- Platform: {{PLATFORM}}
- Channel: {{CHANNEL}}
- Distribution: installation-free portable Zip

LetsMakeMoney is a local-first Windows earnings-progress utility. Salary, schedule, date overrides, overtime records, and logs remain on the local device.

## Start

1. Extract the entire Zip into a writable directory. Do not run the app from an archive preview.
2. Double-click `LetsMakeMoney.exe`.
3. On first launch, use the wizard to configure salary, rest pattern, and work schedule.
4. After the app is hidden, use the LetsMakeMoney icon in the Windows notification area to restore or exit it.

Windows 10/11 requires the Microsoft Edge WebView2 Runtime. If startup fails, confirm that a working WebView2 Runtime is installed before reopening the app.

## Data and logs

Configuration, logs, and local state are stored in:

```text
%APPDATA%\io.letsmakemoney.windows\
```

Before upgrading or rolling back, exit the app from the tray and back up this directory. Extract a new version into a separate program directory; do not overwrite the EXE or DLL while the app is running. The portable program directory and user-data directory are independent.

## Updates and rollback

- The in-app update check only queries public GitHub Releases. Downloading and replacing the program always requires user action.
- This package does not include an installer, silent updates, or automatic program replacement. Mini is the default desktop companion; users may explicitly switch to the Classic orange cat in Settings, and the two modes are mutually exclusive.
- If the Classic runtime package is missing, damaged, or fails validation, the app safely falls back to Mini without affecting earnings, calendar, or configuration data.
- To roll back, exit the current version and run a retained older portable directory. Restore configuration only from your own backup when necessary.
- Published files and checksums are available from [GitHub Releases](https://github.com/NzyZzz1998/LetsMakeMoney/releases).

## Included documentation and licenses

- [MIT code license](LICENSE)
- [Visual asset license](ASSETS_LICENSE.md)
- [Asset manifest](ASSETS_MANIFEST.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Changelog](CHANGELOG.md)
- [简体中文](README.md)

Every relative link above points to a file in this Zip and remains readable offline.

## Online support

- [Repository](https://github.com/NzyZzz1998/LetsMakeMoney)
- [Issue tracker](https://github.com/NzyZzz1998/LetsMakeMoney/issues)
- [Security policy](https://github.com/NzyZzz1998/LetsMakeMoney/blob/main/SECURITY.md)

Do not post salary data, complete configuration, raw logs, user names, or absolute local paths in a public issue.
