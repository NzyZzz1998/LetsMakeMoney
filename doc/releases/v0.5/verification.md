# LetsMakeMoney v0.5 Beta 楠岃瘉鏂囨。

**鏈€鍚庢洿鏂?*: 2026-07-09
**閫傜敤鐗堟湰**: v0.5 Beta
**椤圭洰璺緞**: `<PROJECT_ROOT>`

## Final sign-off summary - 2026-07-09

**Final result**: 鏈€氳繃 / 鍙戝竷闃诲銆?
Most v0.5 acceptance items have passed through automation, package smoke checks, Computer Use screenshots, debug logs, and targeted retests. The only remaining release blocker is the real Windows tray left-click pure-pet restore path. Current sign-off cannot mark v0.5 as `閫氳繃 / 鍙彂甯僠 until the regenerated v0.5 package has manual evidence that pure-pet mode restores the desktop pet without a taskbar entry after tray hide/show.

鏈枃妗ｇ敤浜?v0.5 Beta 鐨勪汉宸ラ獙璇佸拰鍥炲綊璁板綍銆倂0.5 閲嶇偣楠岃瘉 Settings / Wizard 鍏变韩鎺т欢绯荤粺锛屼互鍙婃墭鐩?/ 鐐瑰嚮绌块€?/ 绾瀹犳仮澶嶉摼璺€?
缁撴灉寤鸿濉啓锛?
- `閫氳繃`
- `閮ㄥ垎閫氳繃`
- `澶辫触`
- `寰呴獙璇乣
- `鏆傜紦`

## 1. 鍩虹淇℃伅

| 椤圭洰 | 濉啓 |
|---|---|
| 楠岃瘉鏃ユ湡 | |
| Windows 鐗堟湰 | |
| Godot 鐗堟湰 | 4.7 stable |
| 杩愯鏂瑰紡 | 瀵煎嚭 exe / Godot 缂栬緫鍣?|
| exe 璺緞 | `<PROJECT_ROOT>\build\LetsMakeMoney.exe` |
| 閰嶇疆璺緞 | `%APPDATA%\LetsMakeMoney\config.json` |
| debug 鏃ュ織璺緞 | `%APPDATA%\LetsMakeMoney\debug.log` |
| 楠岃瘉缁撹 | 閫氳繃 / 閮ㄥ垎閫氳繃 / 鏈€氳繃 / 寰呴獙璇?|

## 2. 楠岃瘉鍓嶅噯澶?
### 2.1 鍏抽棴鏃ц繘绋?
```powershell
Stop-Process -Name LetsMakeMoney -Force -ErrorAction SilentlyContinue
```

缁撴灉锛?
澶囨敞锛?
### 2.2 鑷姩楠岃瘉

```powershell
cd <PROJECT_ROOT>
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v04.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_m5.ps1
```

缁撴灉锛?
澶囨敞锛?
## 3. Settings 鍏变韩鎺т欢绯荤粺

| 缂栧彿 | 鎿嶄綔姝ラ | 棰勬湡琛屼负 | 缁撴灉 | 澶囨敞 |
|---|---|---|---|---|
| V05-MAN-001 | 鍙抽敭灏忕尗锛岀偣鍑烩€滆缃€?| 璁剧疆绐楀彛鎵撳紑锛屾暣浣撲负绱у噾鏆栬壊鍋忓ソ闈㈡澘 | 寰呴獙璇?| |
| V05-MAN-002 | 鍒囨崲鈥滃伐璧勨€濋〉 | 鏈堣柂銆佷紤鎭ā寮忋€佹椂闂磋緭鍏ュ拰鍙灏忔椂鏁板竷灞€绋冲畾 | 寰呴獙璇?| |
| V05-MAN-003 | 灞曞紑鈥滀紤鎭ā寮忊€濅笅鎷夋 | 涓嬫媺 popup 涓烘殩鑹茬焊闈㈤鏍硷紝涓嶅嚭鐜版繁鐏扮郴缁熻彍鍗?| 寰呴獙璇?| |
| V05-MAN-004 | 鍒囨崲鈥滄瀹犫€濋〉 | 瀹犵墿閫夋嫨鍒楄〃鍙敤锛屽綋鍓嶅疇鐗╁彲璇嗗埆 | 寰呴獙璇?| |
| V05-MAN-005 | 鍒囨崲鈥滄樉绀衡€濋〉 | 閫忔槑搴︺€佺缉鏀俱€佺獥鍙ｆā寮忋€佺函妗屽疇妯″紡鎺т欢缁熶竴 | 寰呴獙璇?| |
| V05-MAN-006 | 灞曞紑鈥滅獥鍙ｆā寮忊€濅笅鎷夋 | 涓嬫媺鏍峰紡涓?Settings 涓€鑷达紝閫変腑鎬佹竻妤?| 寰呴獙璇?| |
| V05-MAN-007 | 鍒囨崲鈥滈潰鏉库€濋〉 | 闈㈡澘椤圭洰寮€鍏崇揣鍑戙€佸彲璇汇€佸彲鐐瑰嚮 | 寰呴獙璇?| |
| V05-MAN-008 | 鍒囨崲鈥滈€氱敤鈥濋〉 | 寮€鏈鸿嚜鍚€侀殣钘忓埌鎵樼洏鍜岀淮鎶ゆ寜閽竷灞€绋冲畾 | 寰呴獙璇?| |
| V05-MAN-009 | 淇敼涓€涓缃苟淇濆瓨 | 鍑虹幇鈥滃凡淇濆瓨鈥濆弽棣堬紝閰嶇疆鍐欏叆 | 寰呴獙璇?| |
| V05-MAN-010 | 涓嶄慨鏀硅缃洿鎺ヤ繚瀛?| 鍑虹幇鈥滄棤鍙樺寲鈥濆弽棣堬紝涓嶈鎶ュけ璐?| 寰呴獙璇?| |
| V05-MAN-011 | 鐐瑰嚮鍙栨秷 | 涓嶄繚瀛樻湭纭淇敼骞跺叧闂缃?| 寰呴獙璇?| |
| V05-MAN-012 | 鐐瑰嚮鍙充笂瑙掑叧闂?| 璁剧疆绐楀彛鍏抽棴锛屾瀹犳仮澶嶅師浜や簰绛栫暐 | 寰呴獙璇?| |

## 4. Wizard 鍏变韩鎺т欢绯荤粺

| 缂栧彿 | 鎿嶄綔姝ラ | 棰勬湡琛屼负 | 缁撴灉 | 澶囨敞 |
|---|---|---|---|---|
| V05-MAN-020 | 浠庤缃腑鐐瑰嚮鈥滈噸鏂拌繍琛屽悜瀵尖€?| Wizard 鎵撳紑锛岄鏍间笌 Settings 鍚屾簮 | 寰呴獙璇?| |
| V05-MAN-021 | 鏌ョ湅娆㈣繋椤?| 椤甸潰绱у噾锛屼笉鍍忛粯璁ゅ脊绐楁垨鏃у悜瀵?| 寰呴獙璇?| |
| V05-MAN-022 | 杩涘叆钖祫 / 鏃堕棿椤?| SpinBox銆丱ptionButton銆佹椂闂磋緭鍏ヤ笌 Settings 涓€鑷?| 寰呴獙璇?| |
| V05-MAN-023 | 灞曞紑浼戞伅妯″紡涓嬫媺妗?| popup 涓烘殩鑹茬焊闈㈤鏍?| 寰呴獙璇?| |
| V05-MAN-024 | 杩涘叆瀹犵墿椤?| 鑷冲皯鏈夊綋鍓嶅疇鐗╁彲閫夛紝涓嶅嚭鐜扳€滄棤鍔ㄧ墿鍙€夆€?| 寰呴獙璇?| |
| V05-MAN-025 | 杩涘叆纭椤?| 閰嶇疆鎽樿鍙锛屽畬鎴愭寜閽竻妤?| 寰呴獙璇?| |
| V05-MAN-026 | 娴嬭瘯涓婁竴姝?/ 涓嬩竴姝?| 姝ラ鍒囨崲姝ｅ父锛岃〃鍗曞€间笉涓㈠け | 寰呴獙璇?| |
| V05-MAN-027 | 鐐瑰嚮鍙栨秷鎴栧叧闂?| Wizard 鍏抽棴锛屾瀹犳仮澶嶅師浜や簰绛栫暐 | 寰呴獙璇?| |
| V05-MAN-028 | 鐐瑰嚮瀹屾垚 | 閰嶇疆淇濆瓨锛屽悜瀵煎叧闂紝妗屽疇鍙户缁娇鐢?| 寰呴獙璇?| |

## 5. 鎵樼洏 / 鐐瑰嚮绌块€?/ 绾瀹犳仮澶?
| 缂栧彿 | 鎿嶄綔姝ラ | 棰勬湡琛屼负 | 缁撴灉 | 澶囨敞 |
|---|---|---|---|---|
| V05-MAN-040 | 寮€鍚函妗屽疇妯″紡 | 浠诲姟鏍忕瓥鐣ユ寜閰嶇疆搴旂敤锛岀獥鍙ｄ粛鍙壘鍥?| 寰呴獙璇?| |
| V05-MAN-041 | 鎵樼洏宸﹂敭闅愯棌绐楀彛 | 妗屽疇闅愯棌锛屾墭鐩樺浘鏍囦繚鐣?| 寰呴獙璇?| |
| V05-MAN-042 | 鍐嶆鎵樼洏宸﹂敭鏄剧ず绐楀彛 | 妗屽疇鎭㈠锛岄噸鏂板簲鐢ㄧ函妗屽疇鍜岀偣鍑荤┛閫忕瓥鐣?| 寰呴獙璇?| |
| V05-MAN-043 | 鎵樼洏鍙抽敭鎵撳紑鑿滃崟 | 鑿滃崟鍙敤锛屾牱寮忎笉鐮村潖 | 寰呴獙璇?| |
| V05-MAN-044 | 浠庢墭鐩樿彍鍗曟墦寮€璁剧疆 | 璁剧疆绐楀彛鍙偣鍑伙紝涓嶈閫忔槑绌块€忕牬鍧?| 寰呴獙璇?| |
| V05-MAN-045 | 鍏抽棴璁剧疆鍚庣Щ鍔ㄩ紶鏍囧埌妗屽疇绌虹櫧鍖哄煙 | 鐐瑰嚮绌块€忔仮澶嶏紝鐚拰 Panel 浠嶅彲浜や簰 | 寰呴獙璇?| |
| V05-MAN-046 | native 鑳藉姏涓嶅彲鐢ㄦ椂鍚姩 | 闄嶇骇鍒板彲鎵惧洖鏅€氱獥鍙ｏ紝涓嶈繘鍏ヤ笉鍙仮澶嶇姸鎬?| 寰呴獙璇?| |

## 6. debug.log 楠岃瘉

| 缂栧彿 | 鎿嶄綔姝ラ | 棰勬湡鏃ュ織浜嬩欢 | 缁撴灉 | 澶囨敞 |
|---|---|---|---|---|
| V05-MAN-060 | 鎵撳紑骞跺叧闂?Settings | `settings_opened` / `settings_closed` 鎴栫瓑浠风ǔ瀹氫簨浠?| 寰呴獙璇?| |
| V05-MAN-061 | 淇濆瓨 Settings | `settings_saved` / `settings_no_change` / `settings_save_failed` | 寰呴獙璇?| |
| V05-MAN-062 | 鎵撳紑骞跺畬鎴?Wizard | `wizard_opened` / `wizard_step_changed` / `wizard_finished` | 寰呴獙璇?| |
| V05-MAN-063 | 鎵樼洏宸﹂敭闅愯棌 / 鏄剧ず | `tray_toggle_requested` / `window_policy_reapplied` | 寰呴獙璇?| |
| V05-MAN-064 | 鎵撳紑 Settings 鎴?Wizard | `passthrough_suspended` / `passthrough_resumed` | 寰呴獙璇?| |
| V05-MAN-065 | 寮€鍚函妗屽疇鍚庢仮澶嶇獥鍙?| `pure_pet_mode_apply` 鎴?fallback 浜嬩欢 | 寰呴獙璇?| |

## 7. 鍥炲綊楠岃瘉

| 缂栧彿 | 鎿嶄綔姝ラ | 棰勬湡琛屼负 | 缁撴灉 | 澶囨敞 |
|---|---|---|---|---|
| V05-REG-001 | Panel 鎶樺彔 / 灞曞紑 | 鏆栬壊 Panel 浠嶆甯告樉绀猴紝涓嶉敊浣?| 寰呴獙璇?| |
| V05-REG-002 | 灏忕尗鍗曞嚮 / 鍙屽嚮 / 闀挎寜 / 鎷栨嫿 / 鍙抽敭 | 浜や簰浠嶅彲鐢紝鏃ュ織鏃犲紓甯?| 寰呴獙璇?| |
| V05-REG-003 | 鍙抽敭鑿滃崟浜岀骇椤?| 鑿滃崟鍔熻兘涓嶅彉 | 寰呴獙璇?| |
| V05-REG-004 | M4 鑷姩楠岃瘉 | `verify_m4.ps1` 閫氳繃鎴栬褰曟槑纭樊寮?| 寰呴獙璇?| |
| V05-REG-005 | M5 鑷姩楠岃瘉 | `verify_m5.ps1` 閫氳繃鎴栬褰曟槑纭樊寮?| 寰呴獙璇?| |

## 8. 鏈€缁堢粨璁?
| 椤圭洰 | 缁撹 |
|---|---|
| Settings 鍏变韩鎺т欢 | 寰呴獙璇?|
| Wizard 鍏变韩鎺т欢 | 寰呴獙璇?|
| 鎵樼洏 / 绾瀹犳仮澶?| 寰呴獙璇?|
| 鐐瑰嚮绌块€忎繚鎶?| 寰呴獙璇?|
| 鏃ュ織瀹屾暣鎬?| 寰呴獙璇?|
| 鍙戝竷鍖呭彲鐢ㄦ€?| 寰呴獙璇?|
| 鏄惁鍙繘鍏ュ彂甯冩敹鍙?| 寰呴獙璇?|
## Release-blocker Bugfix Retest Notes - 2026-07-09

These notes are appended after v0.5 acceptance found release-blocking issues.

### Settings save feedback retest

Required result values: `閫氳繃` / `閮ㄥ垎閫氳繃` / `鏈€氳繃` / `寰呴獙璇乣.

| Item | Steps | Expected | Result | Notes |
|---|---|---|---|---|
| V05-BUG-001-A | Open Settings, change one value, click Save | UI shows success, config file changes, `debug.log` contains `settings_save_success` and `config_save_success` | 寰呴獙璇?| |
| V05-BUG-001-B | Click Save again without changes | UI shows no-change feedback, `debug.log` contains `settings_save_no_change` | 寰呴獙璇?| |
| V05-BUG-001-C | Force config save failure, change a value, click Save | UI shows save failure, user input remains visible, config file is not silently reported as saved, `debug.log` contains `settings_save_failed` and `config_save_failed` with a readable reason | 寰呴獙璇?| |

### Wizard semantic log retest

| Item | Steps | Expected | Result | Notes |
|---|---|---|---|---|
| V05-BUG-002-A | Open rerun Wizard | `debug.log` contains `wizard_opened` | 寰呴獙璇?| |
| V05-BUG-002-B | Navigate Welcome -> Salary -> Pet -> Confirm | `debug.log` contains `wizard_step_changed` for each step transition | 寰呴獙璇?| |
| V05-BUG-002-C | Finish Wizard | Config writes successfully, Wizard closes, `debug.log` contains `wizard_finished` and `wizard_closed: reason=finished` | 寰呴獙璇?| |
| V05-BUG-002-D | Reopen Wizard and click Cancel | Wizard closes, `debug.log` contains `wizard_cancelled` and `wizard_closed: reason=cancelled` | 寰呴獙璇?| |

### Tray left-click manual evidence

Computer Use cannot reliably enumerate or click the Windows notification-area tray icon. If automated tray clicking is unavailable, this item requires human evidence.

| Item | Steps | Expected | Result | Notes |
|---|---|---|---|---|
| V05-BUG-003-A | Enable pure pet mode, launch exported exe, use app menu or close behavior to hide to tray | Window hides, process remains alive, tray icon remains visible | 寰呴獙璇?| Attach screenshot or describe tray icon state. |
| V05-BUG-003-B | Left-click the Windows tray icon | Desktop pet restores and remains recoverable | 寰呴獙璇?| Attach screenshot after restore. |
| V05-BUG-003-C | After restore, inspect taskbar / Alt-Tab behavior under pure pet mode | Pure pet taskbar strategy is preserved after restore | 寰呴獙璇?| Attach screenshot or notes. |
| V05-BUG-003-D | Inspect `%APPDATA%\\LetsMakeMoney\\debug.log` | Log contains tray toggle / restore and window policy reapply events | 寰呴獙璇?| Paste relevant log tail. |

### Targeted retest result - 2026-07-09

| Item | Result | Evidence |
|---|---|---|
| Settings save success | 閫氳繃 | Computer Use changed `monthly_salary` from `1000` to `1100`; config file updated; `debug.log` contains `config_save_success` and `settings_save_success`. |
| Settings no-change save | 閫氳繃 | Re-clicking Save without changes showed no-change feedback; `debug.log` contains `settings_save_no_change`. |
| Settings forced save failure | 閫氳繃 | ACL-denied config write showed save failure feedback, kept unsaved `1200` visible in UI, preserved config at `1100`, and logged `config_save_failed` / `settings_save_failed` with a readable open-file reason. |
| Wizard opened / step logs | 閫氳繃 | `debug.log` contains `wizard_opened` and `wizard_step_changed` for `1 -> 2`, `2 -> 3`, and `3 -> 4`. |
| Wizard finish logs | 閫氳繃 | `debug.log` contains `wizard_finished: changed_keys=[] step=4` and `wizard_closed: reason=finished step=4`. |
| Wizard cancel / close logs | 閫氳繃 | `debug.log` contains `wizard_cancelled: step=1` and `wizard_closed: reason=cancelled step=1`. |
| Click passthrough protection around modal flows | 閫氳繃 | Settings/Wizard open and close flows contain `passthrough_suspended: reason=modal_opened` and `passthrough_resumed: reason=modal_closed`. |
| Tray left-click restore | 寰呬汉宸ヨˉ璇?| Computer Use cannot reliably click the Windows notification-area icon. Manual screenshot/log evidence is still required before final release sign-off. |

### Tray left-click manual retest follow-up - 2026-07-09

| Item | Result | Evidence / Expected Follow-up |
|---|---|---|
| Non-pure-pet tray left-click restore | 閫氳繃 | User manual retest confirmed that left-clicking the tray icon restores the window after hiding to tray. In non-pure-pet mode, the desktop pet and taskbar entry may both be visible. |
| Pure-pet tray left-click restore | 宸蹭慨澶嶅緟澶嶆祴 | Correct expectation confirmed by user: tray icon left-click must hide/show the window in both pure-pet and non-pure-pet modes. A prior build failed to restore in pure-pet mode; the latest fix keeps left-click restore enabled for both modes. |
| Pure-pet taskbar strategy after tray path | 宸蹭慨澶嶅緟澶嶆祴 | A prior retest showed the pure-pet window restored but still exposed a taskbar entry. The latest fix invalidates WindowsPlatform taskbar visibility cache after native show/setup so pure-pet restore can call native `set_taskbar_visible(false)` again. |
| Required final manual evidence | 寰呬汉宸ヨˉ璇?| Retest the regenerated v0.5 package: pure-pet left-click hide/show should restore the desktop pet without a taskbar entry; non-pure-pet should restore with the normal taskbar entry. `debug.log` should include `tray_left_toggle_requested`, `WindowsPlatform.set_taskbar_visible: ... visible=false`, and `window_policy_reapplied`. |

### Final acceptance sign-off - 2026-07-09

| Item | Result | Evidence / Decision |
|---|---|---|
| Overall v0.5 beta acceptance | 鏈€氳繃 | Release sign-off cannot mark v0.5 as `閫氳繃 / 鍙彂甯僠 until the tray left-click pure-pet restore path has passing manual evidence. |
| Release blocker | 鏈€氳繃 | Latest user-provided tray evidence before sign-off showed pure-pet restore exposing a taskbar entry. A fix and regenerated package are available, but no passing manual retest evidence has been provided in this thread. |
| Required final retest | 寰呴獙璇?| Use `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`, enable pure-pet mode, left-click tray icon to hide, left-click tray icon again to restore. Expected: desktop pet restores, taskbar entry remains hidden. |
| Scope decision | 閫氳繃 | No new feature scope is opened. This remains a release-blocking verification item, not an IDEA/PRD candidate. |
