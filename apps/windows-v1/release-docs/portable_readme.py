from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Iterable


TEMPLATES = {
    "README.md": "portable-readme.zh-CN.md",
    "README.en.md": "portable-readme.en.md",
}
REQUIRED_LOCAL_FILES = {
    "README.md",
    "README.en.md",
    "LICENSE",
    "ASSETS_LICENSE.md",
    "ASSETS_MANIFEST.md",
    "THIRD_PARTY_NOTICES.md",
    "CHANGELOG.md",
}
REQUIRED_HTTPS_URLS = {
    "https://github.com/NzyZzz1998/LetsMakeMoney",
    "https://github.com/NzyZzz1998/LetsMakeMoney/issues",
    "https://github.com/NzyZzz1998/LetsMakeMoney/releases",
    "https://github.com/NzyZzz1998/LetsMakeMoney/blob/main/SECURITY.md",
}
LINK_PATTERN = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
VERSION_PATTERN = re.compile(r"\bv(\d+\.\d+\.\d+)\b")
PLACEHOLDER_PATTERN = re.compile(r"\{\{[A-Z0-9_]+\}\}")
WINDOWS_PATH_PATTERN = re.compile(r"(?i)(?<![A-Z0-9])[A-Z]:[\\/]")


class PortableReadmeError(ValueError):
    pass


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PortableReadmeError(message)


def render_text(template: str, version: str, platform: str, channel: str) -> str:
    rendered = (
        template.replace("{{VERSION}}", version)
        .replace("{{PLATFORM}}", platform)
        .replace("{{CHANNEL}}", channel)
    )
    require(not PLACEHOLDER_PATTERN.search(rendered), "README contains an unresolved placeholder")
    return rendered


def _validate_links(text: str, package_root: Path) -> None:
    targets = set(LINK_PATTERN.findall(text))
    for target in targets:
        if target.startswith("https://"):
            continue
        require("://" not in target, f"README contains a non-HTTPS URL: {target}")
        require(
            target in REQUIRED_LOCAL_FILES,
            f"README contains an unsupported relative link: {target}",
        )
        local_path = package_root / target
        require(local_path.is_file(), f"README local link is missing: {target}")
        require(local_path.stat().st_size > 0, f"README local link is empty: {target}")
    for url in REQUIRED_HTTPS_URLS:
        require(url in text, f"README is missing online support URL: {url}")


def validate_document(
    text: str,
    *,
    name: str,
    package_root: Path,
    version: str,
    platform: str,
    channel: str,
) -> None:
    require(bool(text.strip()), f"{name} is empty")
    require(len(text) >= 800, f"{name} is unexpectedly short")
    require("LetsMakeMoney.exe" in text, f"{name} does not name the executable")
    require("%APPDATA%\\io.letsmakemoney.windows\\" in text, f"{name} misses the data directory")
    require(platform in text, f"{name} platform does not match the package")
    require(channel in text, f"{name} channel does not match the package")
    require(f"v{version}" in text, f"{name} version does not match the package")
    versions = set(VERSION_PATTERN.findall(text))
    require(versions <= {version}, f"{name} contains a stale version: {sorted(versions)}")
    require(not PLACEHOLDER_PATTERN.search(text), f"{name} contains an unresolved placeholder")
    require(not re.search(r"!\[[^\]]*\]\(", text), f"{name} embeds a Markdown image")
    require("<img" not in text.lower(), f"{name} embeds an HTML image")
    require(not WINDOWS_PATH_PATTERN.search(text), f"{name} contains an absolute local path")
    _validate_links(text, package_root)

    if name == "README.md":
        for phrase in ("便携", "不包含安装器", "默认使用 Mini", "Classic", "安全回落", "升级", "回退"):
            require(phrase in text, f"{name} is missing required phrase: {phrase}")
    else:
        for phrase in (
            "Portable",
            "does not include an installer",
            "Mini is the default",
            "Classic",
            "safely falls back",
            "upgrading",
            "roll back",
        ):
            require(phrase.lower() in text.lower(), f"{name} is missing required phrase: {phrase}")


def validate_package_readmes(
    package_root: Path,
    *,
    version: str,
    platform: str,
    channel: str,
) -> dict[str, str]:
    for required in REQUIRED_LOCAL_FILES:
        path = package_root / required
        require(path.is_file(), f"package documentation is missing: {required}")
        require(path.stat().st_size > 0, f"package documentation is empty: {required}")

    identities: dict[str, str] = {}
    for output_name in TEMPLATES:
        path = package_root / output_name
        text = path.read_text(encoding="utf-8")
        validate_document(
            text,
            name=output_name,
            package_root=package_root,
            version=version,
            platform=platform,
            channel=channel,
        )
        identities[output_name] = sha256(path)
    return identities


def render_package_readmes(
    template_root: Path,
    package_root: Path,
    *,
    version: str,
    platform: str,
    channel: str,
) -> dict[str, str]:
    for output_name, template_name in TEMPLATES.items():
        template_path = template_root / template_name
        require(template_path.is_file(), f"README template is missing: {template_name}")
        rendered = render_text(
            template_path.read_text(encoding="utf-8"),
            version,
            platform,
            channel,
        )
        (package_root / output_name).write_text(rendered, encoding="utf-8", newline="\n")
    return validate_package_readmes(
        package_root,
        version=version,
        platform=platform,
        channel=channel,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Render and verify LetsMakeMoney portable README files.")
    parser.add_argument("--mode", choices=("render", "verify"), required=True)
    parser.add_argument("--package-root", type=Path, required=True)
    parser.add_argument("--template-root", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--version", required=True)
    parser.add_argument("--platform", default="Windows x86_64")
    parser.add_argument("--channel", default="Stable")
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.mode == "render":
            identities = render_package_readmes(
                args.template_root,
                args.package_root,
                version=args.version,
                platform=args.platform,
                channel=args.channel,
            )
        else:
            identities = validate_package_readmes(
                args.package_root,
                version=args.version,
                platform=args.platform,
                channel=args.channel,
            )
    except (OSError, UnicodeError, PortableReadmeError) as error:
        print(f"FAIL {error}")
        return 1
    print(json.dumps(identities, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
