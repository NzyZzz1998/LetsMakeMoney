from __future__ import annotations

import json
import re
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
RUST = APP_ROOT / "src-tauri" / "src"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def source(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def verify_shared_date_editor() -> None:
    app = source(APP_ROOT / "src" / "App.tsx")
    editor = source(APP_ROOT / "src" / "features" / "calendar" / "DateOverrideEditor.tsx")
    require(app.count("<DateOverrideEditor") == 2, "Today and Calendar must use the same date editor")
    require("function DateOverrideEditor" not in app, "App.tsx must not keep a second date editor")
    require("shouldSubmitDateOverride" in editor, "Unchanged date submissions need a client guard")
    for token in ("automatic", "workday", "paid_rest", "unpaid_rest", "Escape"):
        require(token in editor, f"Shared date editor is missing {token}")


def verify_overtime_layers() -> None:
    required = [
        RUST / "models" / "overtime.rs",
        RUST / "repositories" / "overtime_repository.rs",
        RUST / "services" / "overtime_service.rs",
        RUST / "commands" / "overtime.rs",
        APP_ROOT / "src" / "features" / "calendar" / "overtimeModel.ts",
        APP_ROOT / "src" / "features" / "calendar" / "overtimeService.ts",
        APP_ROOT / "src" / "features" / "calendar" / "OvertimeEditor.tsx",
        APP_ROOT / "contracts" / "overtime-records-v1.schema.json",
    ]
    missing = [path.relative_to(APP_ROOT).as_posix() for path in required if not path.is_file()]
    require(not missing, f"Missing M3 overtime layers: {missing}")

    model = source(RUST / "models" / "overtime.rs")
    repository = source(RUST / "repositories" / "overtime_repository.rs")
    service = source(RUST / "services" / "overtime_service.rs")
    commands = source(RUST / "commands" / "overtime.rs")
    lib = source(RUST / "lib.rs")
    for token in (
        "business_date",
        "minutes",
        "hourly_rate_fen_snapshot",
        "created_at",
        "updated_at",
        "Date::from_calendar_date",
    ):
        require(token in model, f"Overtime model is missing {token}")
    for token in ("json.tmp", "json.previous", "json.corrupt-backup", "sync_all"):
        require(token in repository, f"Overtime repository is missing transactional evidence: {token}")
    require("existing.hourly_rate_fen_snapshot" not in service, "Edits must not replace the original rate snapshot")
    require("existing.minutes = request.minutes" in service, "Edits must update the duration")
    require("Mutex<()>" in service, "Overtime writes require one serialized runtime owner")
    for command in (
        "read_overtime_record",
        "read_overtime_month",
        "save_overtime_record",
        "delete_overtime_record",
        "recover_overtime_records",
    ):
        require(command in commands and command in lib, f"Missing active overtime command: {command}")
    require("hourly_rate_fen_snapshot" not in re.sub(r"request: SaveOvertimeRequest.*?\n", "", commands), "Logs must not expose the rate snapshot")


def verify_ipc_and_schema() -> None:
    fixture = json.loads(source(APP_ROOT / "tests" / "fixtures" / "v107-ipc-contracts.json"))
    overtime = [item for item in fixture["scenarios"] if item["domain"] == "overtime"]
    require(len(overtime) == 7, "M3 needs seven overtime IPC scenarios")
    require(all(item["implementation_status"] == "active" for item in overtime), "M3 IPC scenarios must be active")
    require(any(item["command"] == "recover_overtime_records" for item in overtime), "Recovery IPC fixture missing")

    schema = json.loads(source(APP_ROOT / "contracts" / "overtime-records-v1.schema.json"))
    require(schema["properties"]["schema_version"]["const"] == 1, "Overtime schema identity drift")
    require(schema["properties"]["records"]["items"]["additionalProperties"] is False, "Overtime records must be strict")


def main() -> int:
    checks = [verify_shared_date_editor, verify_overtime_layers, verify_ipc_and_schema]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.7 M3 static contracts ({len(checks)} groups)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
