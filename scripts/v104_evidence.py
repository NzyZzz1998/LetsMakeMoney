from __future__ import annotations

import argparse
import hashlib
import json
import re
import zipfile
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


SHA256_PATTERN = re.compile(r"^[A-F0-9]{64}$")
COMMIT_PATTERN = re.compile(r"^[0-9a-f]{40}$")
ABSOLUTE_WINDOWS_PATH = re.compile(r"(?i)(?<![A-Z0-9])[A-Z]:[\\/]")
USER_PATH = re.compile(r"(?i)(?:[\\/])Users[\\/][^\\/\s]+")
EMAIL = re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.I)
SECRET_KEYS = re.compile(r"(?i)(token|password|passwd|private.?key|secret|certificate|salary|wage)")
ALLOWED_AVAILABILITY = {"available", "restricted", "missing", "not_collected"}
ALLOWED_RESULTS = {"passed", "partial", "failed", "pending", "not_run"}
ALLOWED_METHODS = {"automatic", "computer_use", "manual"}
ALLOWED_CONCLUSIONS = {"passed", "partial", "failed", "pending"}
ALLOWED_ARCHIVE_CONTENTS = {
    "screenshots",
    "recordings",
    "full_logs",
    "resource_curves",
    "system_operations",
}


class EvidenceError(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def sha256_bytes(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest().upper()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def parse_iso_datetime(value: Any, field: str) -> None:
    require(isinstance(value, str) and value.endswith("Z"), f"{field} must use UTC ISO-8601")
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise EvidenceError(f"{field} is not a valid timestamp") from error


def scan_private(value: Any, path: str = "$") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            require(not SECRET_KEYS.search(str(key)), f"{path}.{key} is a forbidden sensitive field")
            scan_private(child, f"{path}.{key}")
        return
    if isinstance(value, list):
        for index, child in enumerate(value):
            scan_private(child, f"{path}[{index}]")
        return
    if not isinstance(value, str):
        return
    require(not ABSOLUTE_WINDOWS_PATH.search(value), f"{path} contains an absolute local path")
    require(not USER_PATH.search(value), f"{path} contains a user directory")
    require(not EMAIL.search(value), f"{path} contains an email address")


def validate_raw_archive(raw: dict[str, Any]) -> None:
    expected = {
        "schema_version",
        "archive_id",
        "archive_sha256",
        "availability",
        "custodian_role",
        "contents",
        "retention",
        "reason",
        "updated_at",
    }
    require(set(raw) <= expected, "raw archive contains an unknown field")
    required = expected - {"reason"}
    require(required <= set(raw), "raw archive is missing a required field")
    require(raw["schema_version"] == "1.0", "raw archive schema version is unsupported")
    require(
        bool(re.fullmatch(r"LMM-V104-[A-Z0-9-]{6,64}", raw["archive_id"])),
        "raw archive id is invalid",
    )
    archive_hash = raw["archive_sha256"]
    require(
        archive_hash is None or bool(SHA256_PATTERN.fullmatch(archive_hash)),
        "raw archive SHA256 is invalid",
    )
    require(raw["availability"] in ALLOWED_AVAILABILITY, "raw archive availability is invalid")
    require(isinstance(raw["custodian_role"], str) and raw["custodian_role"], "custodian role is empty")
    require(
        isinstance(raw["contents"], list)
        and set(raw["contents"]) <= ALLOWED_ARCHIVE_CONTENTS
        and len(raw["contents"]) == len(set(raw["contents"])),
        "raw archive contents are invalid",
    )
    require(raw["retention"] == "owner-managed", "raw archive retention contract is invalid")
    parse_iso_datetime(raw["updated_at"], "raw_archive.updated_at")
    if raw["availability"] == "not_collected":
        require(archive_hash is None, "not-collected raw evidence cannot claim a hash")


def validate_summary(summary: dict[str, Any]) -> None:
    required = {
        "schema_version",
        "release_version",
        "channel",
        "branch",
        "commit",
        "source_tree_dirty",
        "artifacts",
        "environment",
        "checks",
        "conclusion",
        "limitations",
        "log_summary",
        "redaction",
        "raw_archive",
        "generated_at",
    }
    require(set(summary) == required, "acceptance summary fields do not match the schema")
    require(summary["schema_version"] == "1.0", "summary schema version is unsupported")
    require(summary["release_version"] == "1.0.4", "summary release version must be 1.0.4")
    require(summary["channel"] in {"stable-candidate", "stable"}, "summary channel is invalid")
    require(isinstance(summary["branch"], str) and summary["branch"], "summary branch is empty")
    require(bool(COMMIT_PATTERN.fullmatch(summary["commit"])), "summary commit is invalid")
    require(isinstance(summary["source_tree_dirty"], bool), "source_tree_dirty must be boolean")

    artifacts = summary["artifacts"]
    require(isinstance(artifacts, list) and artifacts, "summary artifacts are empty")
    names: set[str] = set()
    for artifact in artifacts:
        require(set(artifact) == {"name", "size", "sha256"}, "artifact fields are invalid")
        name = artifact["name"]
        require(
            isinstance(name, str)
            and name == PurePosixPath(name).name
            and "/" not in name
            and "\\" not in name,
            "artifact name must be a basename",
        )
        require(name not in names, "artifact name is duplicated")
        names.add(name)
        require(isinstance(artifact["size"], int) and artifact["size"] > 0, "artifact size is invalid")
        require(bool(SHA256_PATTERN.fullmatch(artifact["sha256"])), "artifact SHA256 is invalid")

    environment = summary["environment"]
    require(
        set(environment) == {"windows_version", "architecture", "dpi", "webview2_version"},
        "environment fields are invalid",
    )
    require(environment["architecture"] in {"x86_64", "arm64"}, "environment architecture is invalid")
    require(
        isinstance(environment["dpi"], list)
        and environment["dpi"]
        and set(environment["dpi"]) <= {100, 125, 150},
        "environment DPI values are invalid",
    )

    checks = summary["checks"]
    require(isinstance(checks, list) and checks, "summary checks are empty")
    check_ids: set[str] = set()
    for check in checks:
        require(
            set(check) == {
                "id",
                "method",
                "result",
                "started_at",
                "finished_at",
                "evidence_ref",
            },
            "check fields are invalid",
        )
        require(bool(re.fullmatch(r"V104-[A-Z0-9-]+", check["id"])), "check id is invalid")
        require(check["id"] not in check_ids, "check id is duplicated")
        check_ids.add(check["id"])
        require(check["method"] in ALLOWED_METHODS, "check method is invalid")
        require(check["result"] in ALLOWED_RESULTS, "check result is invalid")
        parse_iso_datetime(check["started_at"], f"{check['id']}.started_at")
        parse_iso_datetime(check["finished_at"], f"{check['id']}.finished_at")
        require(
            bool(re.fullmatch(r"(?:repo|archive):[A-Za-z0-9._/-]+", check["evidence_ref"])),
            "check evidence reference is invalid",
        )

    require(summary["conclusion"] in ALLOWED_CONCLUSIONS, "summary conclusion is invalid")
    require(isinstance(summary["limitations"], list), "summary limitations are invalid")
    log_summary = summary["log_summary"]
    require(
        set(log_summary) == {"event_counts", "error_categories", "truncated"},
        "log summary fields are invalid",
    )
    require(
        isinstance(log_summary["event_counts"], dict)
        and all(isinstance(value, int) and value >= 0 for value in log_summary["event_counts"].values()),
        "log event counts are invalid",
    )
    require(
        isinstance(log_summary["error_categories"], list)
        and all(re.fullmatch(r"[a-z0-9._-]+", value) for value in log_summary["error_categories"]),
        "log error categories are invalid",
    )
    require(isinstance(log_summary["truncated"], bool), "log truncated flag is invalid")
    require(
        summary["redaction"].get("policy_version") == "v1"
        and isinstance(summary["redaction"].get("removed_fields"), list),
        "redaction declaration is invalid",
    )
    validate_raw_archive(summary["raw_archive"])
    parse_iso_datetime(summary["generated_at"], "generated_at")
    scan_private(summary)


def load_package_identity(package_path: Path) -> dict[str, Any]:
    require(package_path.is_file(), "candidate package does not exist")
    require(package_path.name == "LetsMakeMoney-v1.0.4-windows-x86_64.zip", "candidate filename is invalid")
    with zipfile.ZipFile(package_path) as archive:
        roots = {PurePosixPath(name).parts[0] for name in archive.namelist() if name}
        require(roots == {"LetsMakeMoney-v1.0.4-windows-x86_64"}, "candidate root is invalid")
        root = next(iter(roots))
        required = {
            "LetsMakeMoney.exe",
            "WebView2Loader.dll",
            "README.md",
            "README.en.md",
            "BUILD-INFO.json",
        }
        names = set(archive.namelist())
        for name in required:
            require(f"{root}/{name}" in names, f"candidate identity file is missing: {name}")
        build_info = json.loads(archive.read(f"{root}/BUILD-INFO.json").decode("utf-8-sig"))
        artifacts = [
            {
                "name": package_path.name,
                "size": package_path.stat().st_size,
                "sha256": sha256_file(package_path),
            }
        ]
        for name in ("LetsMakeMoney.exe", "WebView2Loader.dll", "README.md", "README.en.md", "BUILD-INFO.json"):
            content = archive.read(f"{root}/{name}")
            artifacts.append({"name": name, "size": len(content), "sha256": sha256_bytes(content)})
    return {"build_info": build_info, "artifacts": artifacts}


def render_markdown(summary: dict[str, Any]) -> str:
    artifact_rows = "\n".join(
        f"| `{item['name']}` | {item['size']} | `{item['sha256']}` |"
        for item in summary["artifacts"]
    )
    check_rows = "\n".join(
        f"| `{item['id']}` | {item['method']} | {item['result']} | `{item['evidence_ref']}` |"
        for item in summary["checks"]
    )
    limitations = "\n".join(f"- {item}" for item in summary["limitations"]) or "- 无"
    return f"""# LetsMakeMoney v1.0.4 验收摘要

## 候选身份

- 分支：`{summary['branch']}`
- 提交：`{summary['commit']}`
- 工作树：{'有未提交变更' if summary['source_tree_dirty'] else '干净'}
- 结论：`{summary['conclusion']}`
- 生成时间：`{summary['generated_at']}`

| 产物 | 字节 | SHA256 |
| --- | ---: | --- |
{artifact_rows}

## 环境

- Windows：{summary['environment']['windows_version']}
- 架构：{summary['environment']['architecture']}
- DPI：{', '.join(str(value) + '%' for value in summary['environment']['dpi'])}
- WebView2：{summary['environment']['webview2_version']}

## 检查

| ID | 方法 | 结果 | 证据 |
| --- | --- | --- | --- |
{check_rows}

## 限制

{limitations}

## 原始证据

- 归档 ID：`{summary['raw_archive']['archive_id']}`
- 可用状态：`{summary['raw_archive']['availability']}`
- 责任角色：`{summary['raw_archive']['custodian_role']}`

本文件由同目录 JSON 确定性生成。仓库摘要不包含用户名、绝对路径、真实薪资、完整配置、秘密或未脱敏日志。
"""


def generate(
    package_path: Path,
    input_path: Path,
    output_dir: Path,
    generated_at: str,
) -> dict[str, Any]:
    payload = json.loads(input_path.read_text(encoding="utf-8"))
    package = load_package_identity(package_path)
    build_info = package["build_info"]
    summary = {
        "schema_version": "1.0",
        "release_version": "1.0.4",
        "channel": build_info["channel"],
        "branch": payload.get("branch", "main"),
        "commit": build_info["source_head"],
        "source_tree_dirty": bool(build_info["source_tree_dirty"]),
        "artifacts": package["artifacts"],
        "environment": payload["environment"],
        "checks": payload["checks"],
        "conclusion": payload["conclusion"],
        "limitations": payload["limitations"],
        "log_summary": payload["log_summary"],
        "redaction": {
            "policy_version": "v1",
            "removed_fields": [
                "user_paths",
                "personal_configuration",
                "salary_values",
                "raw_log_lines",
                "secrets",
            ],
        },
        "raw_archive": payload["raw_archive"],
        "generated_at": generated_at,
    }
    validate_summary(summary)
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "acceptance-summary.json"
    markdown_path = output_dir / "acceptance-summary.md"
    json_path.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    markdown_path.write_text(render_markdown(summary), encoding="utf-8", newline="\n")
    return summary


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate or verify v1.0.4 durable acceptance evidence.")
    parser.add_argument("--mode", choices=("generate", "verify"), required=True)
    parser.add_argument("--package", type=Path)
    parser.add_argument("--input", type=Path)
    parser.add_argument("--summary", type=Path)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument(
        "--generated-at",
        default=datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    )
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.mode == "generate":
            require(args.package is not None, "--package is required for generate mode")
            require(args.input is not None, "--input is required for generate mode")
            require(args.output_dir is not None, "--output-dir is required for generate mode")
            generate(args.package, args.input, args.output_dir, args.generated_at)
        else:
            require(args.summary is not None, "--summary is required for verify mode")
            summary = json.loads(args.summary.read_text(encoding="utf-8"))
            validate_summary(summary)
    except (OSError, KeyError, UnicodeError, json.JSONDecodeError, zipfile.BadZipFile, EvidenceError) as error:
        print(f"FAIL {error}")
        return 1
    print("PASS v1.0.4 durable evidence contract")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
