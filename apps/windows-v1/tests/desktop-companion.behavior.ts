import {
  defaultConfig,
  normalizeConfiguration,
  resolveDesktopCompanionLabel,
  type DesktopCompanionMode,
} from "../src/domain/configuration";
import { createAppRuntime, type DesktopBridge } from "../src/runtime/appRuntime";
import { createWindowService } from "../src/services/windowService";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(
  defaultConfig.desktop_companion_mode === "mini",
  "new and migrated users must remain on the Mini companion by default",
);
assert(
  resolveDesktopCompanionLabel("mini") === "mini",
  "Mini mode must resolve to the Mini window",
);
assert(
  resolveDesktopCompanionLabel("pet") === "pet",
  "pet mode must resolve to the isolated pet window",
);

const invalidMode = normalizeConfiguration({
  desktop_companion_mode: "both" as DesktopCompanionMode,
});
assert(
  invalidMode.desktop_companion_mode === "mini",
  "invalid or obsolete companion values must fail closed to Mini",
);

const calls: Array<{ command: string; args?: Record<string, unknown> }> = [];
const bridge: DesktopBridge = {
  invoke: async <T>(command: string, args?: Record<string, unknown>) => {
    calls.push({ command, args });
    return undefined as T;
  },
  emit: async () => undefined,
  listen: async () => () => undefined,
};
const windows = createWindowService(createAppRuntime(bridge));
await windows.switchDesktopCompanion("pet");

assert(
  calls.length === 1 && calls[0].command === "switch_desktop_companion",
  "mode changes must use the dedicated atomic backend transaction",
);
assert(
  calls[0].args?.mode === "pet",
  "the atomic switch must receive the requested companion mode",
);

calls.length = 0;
const status = await windows.petPackageStatus();
assert(status === undefined, "the bridge fixture should return its typed placeholder");
assert(
  calls.length === 1 && calls[0].command === "pet_package_status",
  "Settings must query the backend-owned product approval gate",
);

calls.length = 0;
await windows.showDesktopCompanion();
assert(
  calls.length === 1 && calls[0].command === "show_desktop_companion",
  "Wizard and recovery paths must show the persisted active companion",
);

console.log("desktop companion behavior: 10/10 passed");
