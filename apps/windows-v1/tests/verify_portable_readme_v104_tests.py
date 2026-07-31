from __future__ import annotations

import shutil
import tempfile
from pathlib import Path

import sys


RELEASE_DOCS = Path(__file__).resolve().parents[1] / "release-docs"
sys.path.insert(0, str(RELEASE_DOCS))

import portable_readme as contract  # noqa: E402


VERSION = "1.0.4"
PLATFORM = "Windows x86_64"
CHANNEL = "Stable"


def make_package(root: Path) -> Path:
    package = root / "LetsMakeMoney-v1.0.4-windows-x86_64"
    package.mkdir()
    for name in contract.REQUIRED_LOCAL_FILES - set(contract.TEMPLATES):
        (package / name).write_text(f"{name}\n", encoding="utf-8")
    contract.render_package_readmes(
        RELEASE_DOCS,
        package,
        version=VERSION,
        platform=PLATFORM,
        channel=CHANNEL,
    )
    return package


def expect_rejected(package: Path, label: str) -> None:
    try:
        contract.validate_package_readmes(
            package,
            version=VERSION,
            platform=PLATFORM,
            channel=CHANNEL,
        )
    except contract.PortableReadmeError:
        print(f"PASS rejected {label}")
        return
    raise AssertionError(f"invalid portable README fixture was accepted: {label}")


def mutate_copy(source: Path, root: Path, label: str) -> Path:
    destination = root / label
    shutil.copytree(source, destination)
    return destination


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="lmm-v104-readme-") as raw:
        root = Path(raw)
        valid = make_package(root)
        identities = contract.validate_package_readmes(
            valid,
            version=VERSION,
            platform=PLATFORM,
            channel=CHANNEL,
        )
        assert set(identities) == set(contract.TEMPLATES)
        print("PASS accepted valid portable package")

        stale = mutate_copy(valid, root, "stale-version")
        path = stale / "README.md"
        path.write_text(path.read_text(encoding="utf-8").replace("v1.0.4", "v1.0.3", 1), encoding="utf-8")
        expect_rejected(stale, "stale version")

        empty = mutate_copy(valid, root, "empty-readme")
        (empty / "README.en.md").write_text("", encoding="utf-8")
        expect_rejected(empty, "empty README")

        broken_link = mutate_copy(valid, root, "broken-relative-link")
        path = broken_link / "README.md"
        path.write_text(path.read_text(encoding="utf-8") + "\n[内部文档](doc/current.md)\n", encoding="utf-8")
        expect_rejected(broken_link, "unsupported relative link")

        placeholder = mutate_copy(valid, root, "placeholder")
        path = placeholder / "README.md"
        path.write_text(path.read_text(encoding="utf-8") + "\n{{VERSION}}\n", encoding="utf-8")
        expect_rejected(placeholder, "unresolved placeholder")

        missing_license = mutate_copy(valid, root, "missing-license")
        (missing_license / "LICENSE").unlink()
        expect_rejected(missing_license, "missing license")

        wrong_platform = mutate_copy(valid, root, "wrong-platform")
        path = wrong_platform / "README.en.md"
        path.write_text(path.read_text(encoding="utf-8").replace(PLATFORM, "Windows ARM64"), encoding="utf-8")
        expect_rejected(wrong_platform, "wrong platform")

        wrong_executable = mutate_copy(valid, root, "wrong-executable")
        path = wrong_executable / "README.md"
        path.write_text(path.read_text(encoding="utf-8").replace("LetsMakeMoney.exe", "Wrong.exe"), encoding="utf-8")
        expect_rejected(wrong_executable, "wrong executable")

    print("PASS v1.0.4 portable README contracts (8/8)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
