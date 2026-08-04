import { createAppRuntime, type DesktopBridge } from "../src/runtime/appRuntime";
import { createVersionService } from "../src/services/versionService";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

async function rejects(action: () => Promise<unknown>, expected: string) {
  try {
    await action();
  } catch (error) {
    assert(String(error).includes(expected), `expected ${expected}, received ${String(error)}`);
    return;
  }
  throw new Error(`expected rejection containing ${expected}`);
}

const browserService = createVersionService(createAppRuntime(), async () => "9.9.9");
assert(await browserService.read() === "dev-preview", "browser preview must use an explicit non-release identity");

const bridge: DesktopBridge = {
  invoke: async <T>() => undefined as T,
  emit: async () => undefined,
  listen: async () => () => undefined,
};
const desktopRuntime = createAppRuntime(bridge);
const desktopService = createVersionService(desktopRuntime, async () => "1.0.7");
assert(await desktopService.read() === "1.0.7", "desktop version must come from Tauri package metadata");

await rejects(
  () => createVersionService(desktopRuntime, async () => "").read(),
  "invalid_desktop_version_metadata",
);
await rejects(
  () => createVersionService(desktopRuntime, async () => "v1.0.7").read(),
  "invalid_desktop_version_metadata",
);
await rejects(
  () => createVersionService(desktopRuntime, async () => Promise.reject(new Error("metadata_unavailable"))).read(),
  "metadata_unavailable",
);

console.log("PASS version metadata behavior (6 checks)");
