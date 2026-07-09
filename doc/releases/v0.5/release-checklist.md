# LetsMakeMoney v0.5 Beta 鍙戝竷鍓嶆鏌ユ竻鍗?
**鏈€鍚庢洿鏂?*: 2026-07-09
**閫傜敤鐗堟湰**: v0.5 Beta
**褰撳墠鐘舵€?*: `/acceptance` 鏈€氳繃 / 鍙戝竷闃诲锛屾湭鍙戝竷

## 1. 鏂囨。鐘舵€?
- [x] [idea-pool.md](idea-pool.md) 宸插畬鎴愩€?- [x] [prd.md](prd.md) 宸插畬鎴愬苟纭閫氳繃銆?- [x] [dev_plan_v0.5.md](dev_plan_v0.5.md) 宸插畬鎴愬苟纭閫氳繃銆?- [x] [progress_v0.5.md](progress_v0.5.md) 宸插畬鎴愬苟纭閫氳繃銆?- [x] [status.md](status.md) 宸插垱寤恒€?- [x] [verification.md](verification.md) 宸插垱寤恒€?- [x] [release-checklist.md](release-checklist.md) 宸插垱寤恒€?- [x] [progress_v0.5.md](progress_v0.5.md) 涓叏閮ㄥ疄鐜?checklist 涓庡疄鐜扮粨鏋滀竴鑷淬€?- [ ] [verification.md](verification.md) 涓汉宸ラ獙鏀剁粨鏋滃凡濉啓銆?- [x] v0.5 release notes 宸插垱寤哄苟鍚屾褰撳墠瀹炵幇銆?- [x] [../../current.md](../../current.md) 宸叉洿鏂颁负 v0.5 瀹炵幇瀹屾垚 / 寰呴獙鏀剁姸鎬併€?
## 2. 鑷姩楠岃瘉

鍦?PowerShell 涓粠椤圭洰鏍圭洰褰曟墽琛岋細

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v04.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_m4.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_m5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_docs_status.ps1
```

- [x] v0.5 鑷姩楠岃瘉閫氳繃銆?- [x] v0.4 鍥炲綊楠岃瘉閫氳繃鎴栬褰曟槑纭樊寮傘€?- [x] M4 鍥炲綊閫氳繃鎴栬褰曟槑纭樊寮傘€?- [x] M5 鍥炲綊閫氳繃鎴栬褰曟槑纭樊寮傘€?- [x] 鏂囨。鍙ｅ緞鎵弿閫氳繃銆?
## 3. 鎵嬪姩楠岃瘉

- [x] Settings 宸ヨ祫椤垫埅鍥鹃€氳繃銆?- [x] Settings 鏄剧ず椤垫埅鍥鹃€氳繃銆?- [x] Settings 閫氱敤椤垫埅鍥鹃€氳繃銆?- [x] Settings OptionButton 灞曞紑鐘舵€侀€氳繃銆?- [x] Wizard 娆㈣繋椤垫埅鍥鹃€氳繃銆?- [x] Wizard 钖祫 / 鏃堕棿椤垫埅鍥鹃€氳繃銆?- [x] Wizard 瀹犵墿椤垫埅鍥鹃€氳繃銆?- [x] Wizard 纭椤垫埅鍥鹃€氳繃銆?- [ ] 鎵樼洏宸﹂敭闅愯棌 / 鏄剧ず閫氳繃銆?- [ ] 绾瀹犳仮澶嶈矾寰勯€氳繃銆?- [ ] 璁剧疆椤?/ Wizard 鎵撳紑鏈熼棿鐐瑰嚮绌块€忎繚鎶ら€氳繃銆?- [ ] debug.log 鍏抽敭浜嬩欢瀹屾暣銆?- [ ] Panel銆佸彸閿彍鍗曘€佸皬鐚氦浜掑洖褰掗€氳繃銆?
## 4. 鎵撳寘涓庡寘楠岃瘉

鍙戝竷鍓嶅簲鐢熸垚 v0.5 涓撳睘鍖呬綋锛屼笉鍏佽鐩存帴鎶?v0.4 鍖呬綋閲嶅懡鍚嶄负 v0.5銆?
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package_v05.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_v05_package.ps1
```

- [x] 鐢熸垚 `releases/v0.5/LetsMakeMoney-v0.5-beta-windows-x86_64.zip`銆?- [x] 灞曞紑鐩綍鍐呭寘鍚?`LetsMakeMoney.exe`銆?- [x] 灞曞紑鐩綍鍐呭寘鍚?`letsmakemoney_native.dll`銆?- [x] 灞曞紑鐩綍鍐呭寘鍚?`app_icon.ico`銆?- [x] 灞曞紑鐩綍鍐呭寘鍚?`README.md`銆?- [x] 灞曞紑鐩綍鍐呭寘鍚?`release-notes.md`銆?- [x] 灞曞紑鐩綍鍐呭寘鍚?`manifest.json`銆?- [x] 灞曞紑鐩綍鍐呭寘鍚?`checksums.txt`銆?- [x] `manifest.json` 涓庡疄闄呮枃浠朵竴鑷淬€?- [x] `checksums.txt` 宸查噸鏂扮敓鎴愩€?
## 5. Git / GitHub

- [ ] 褰撳墠鍒嗘敮纭銆?- [ ] v0.5 瀹炵幇鎻愪氦宸叉帹閫併€?- [ ] v0.5 tag 鍛藉悕宸茬‘璁ゃ€?- [ ] release notes 涓?tag / 鍖呬綋鐗堟湰涓€鑷淬€?
## 6. 鍙戝竷鍐崇瓥

v0.5 Beta 鍙戝竷鍓嶅繀椤绘弧瓒筹細

- [ ] 鍏变韩鎺т欢绯荤粺瀹炵幇骞堕獙璇侀€氳繃銆?- [ ] Settings / Wizard 瑙嗚鍜屼氦浜掍笌 v0.5 鍘熷瀷鏂瑰悜涓€鑷淬€?- [ ] 鎵樼洏 / 鐐瑰嚮绌块€?/ 绾瀹犳仮澶嶈矾寰勯€氳繃銆?- [ ] 鑷姩楠岃瘉閫氳繃銆?- [ ] 鎵嬪姩楠岃瘉閫氳繃鎴栨槑纭褰曢潪闃诲宸茬煡闂銆?- [ ] 鍙戝竷鍖呴獙璇侀€氳繃銆?- [ ] 鏂囨。浜嬪疄婧愭棤鏃у彛寰勫啿绐併€?## Final acceptance decision - 2026-07-09

Release decision: **鏈€氳繃 / 鍙戝竷闃诲**.

Do not publish, tag, or create a GitHub release for v0.5 Beta yet. The implementation and package checks are complete, but final sign-off is blocked by one manual Windows tray item:

- [ ] Pure-pet mode: tray left-click hide/show restores the desktop pet without a taskbar entry.
- [ ] `debug.log` evidence includes `tray_left_toggle_requested`, `WindowsPlatform.set_taskbar_visible: ... visible=false`, and `window_policy_reapplied`.

All other already-verified v0.5 items remain accepted unless a later retest finds a regression.
