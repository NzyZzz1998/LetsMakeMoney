from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


runtime_managed = [
    ROOT / "src" / "App.tsx",
    ROOT / "src" / "model.ts",
    ROOT / "src" / "configModel.ts",
    ROOT / "src" / "theme.ts",
]

required_architecture_files = [
    ROOT / "src" / "components" / "WindowFrame.tsx",
    ROOT / "src" / "features" / "mini" / "MiniWindow.tsx",
    ROOT / "src" / "hooks" / "useWindowDrag.ts",
    ROOT / "src-tauri" / "src" / "commands" / "income.rs",
]

for path in required_architecture_files:
    require(path.is_file(), f"missing architecture module: {path.relative_to(ROOT)}")

for path in runtime_managed:
    source = path.read_text(encoding="utf-8")
    require(
        "@tauri-apps/api" not in source,
        f"{path.name} must use runtime/services instead of importing Tauri directly",
    )
    require(
        "function isTauri" not in source,
        f"{path.name} must use the shared runtime capability",
    )

model = (ROOT / "src" / "model.ts").read_text(encoding="utf-8")
require(
    "appRuntime." not in model,
    "model.ts must use domain services instead of the low-level runtime bridge",
)
require("new Date()" not in model, "model.ts must obtain the current instant from TimeService")
require("Date.now()" not in model, "model.ts must obtain wall-clock milliseconds from TimeService")
require(
    "createTimeEnvironmentSample()" not in model,
    "model.ts must build environment samples from TimeService",
)

app = (ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
require(
    "function useWindowDrag" not in app,
    "App.tsx must delegate native drag behavior to the window drag hook",
)
require(
    "function WindowFrame" not in app,
    "App.tsx must use the shared window frame component",
)
require(
    "function MiniWindow" not in app,
    "App.tsx must delegate the mini feature to features/mini",
)
require("new Date(" not in app, "App.tsx must obtain business dates from TimeService or utilities")

rust_lib = (ROOT / "src-tauri" / "src" / "lib.rs").read_text(encoding="utf-8")
require(
    "fn calculate_month_salary(" not in rust_lib,
    "lib.rs must delegate income commands to commands/income.rs",
)
require(
    "commands::income::calculate_month_salary" in rust_lib,
    "lib.rs must register the extracted income command",
)

print("architecture structure verification: 22/22 passed")
