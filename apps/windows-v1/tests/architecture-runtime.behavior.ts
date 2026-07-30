import {
  createAppRuntime,
  createDeferredDisposer,
  type DesktopBridge,
} from "../src/runtime/appRuntime";
import {
  FixedTimeService,
  formatLocalDate,
  formatLocalTime,
  monthKey,
} from "../src/runtime/timeService";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const calls: string[] = [];
let eventHandler: ((payload: unknown) => void) | null = null;
let unlistenCount = 0;

const bridge: DesktopBridge = {
  invoke: async <T>(command: string, args?: Record<string, unknown>) => {
    calls.push(`invoke:${command}:${JSON.stringify(args ?? {})}`);
    return { ok: true } as T;
  },
  emit: async (event: string, payload?: unknown) => {
    calls.push(`emit:${event}:${JSON.stringify(payload ?? null)}`);
  },
  listen: async <T>(event: string, handler: (payload: T) => void) => {
    calls.push(`listen:${event}`);
    eventHandler = handler as (payload: unknown) => void;
    return () => {
      unlistenCount += 1;
    };
  },
};

const desktopRuntime = createAppRuntime(bridge);
assert(desktopRuntime.isDesktop, "a supplied bridge must identify the desktop runtime");

const invokeResult = await desktopRuntime.invoke<{ ok: boolean }>("read_configuration");
assert(invokeResult.ok, "desktop invoke must return the bridge result");
await desktopRuntime.emit("lmm://configuration-updated", { source: "test" });
const unlisten = await desktopRuntime.listen<{ value: number }>(
  "lmm://test",
  payload => calls.push(`payload:${payload.value}`),
);
eventHandler?.({ value: 7 });
unlisten();

assert(
  calls.join("|")
    === "invoke:read_configuration:{}"
      + "|emit:lmm://configuration-updated:{\"source\":\"test\"}"
      + "|listen:lmm://test|payload:7",
  "runtime operations must delegate without changing command, event, args or payload",
);
assert(unlistenCount === 1, "runtime listeners must expose the bridge unlisten function");

let attachedDisposals = 0;
const attachedDisposer = createDeferredDisposer();
attachedDisposer.attach(() => {
  attachedDisposals += 1;
});
attachedDisposer.dispose();
attachedDisposer.dispose();
assert(attachedDisposals === 1, "an attached disposer must run exactly once");

let lateDisposals = 0;
const lateDisposer = createDeferredDisposer();
lateDisposer.dispose();
lateDisposer.attach(() => {
  lateDisposals += 1;
});
assert(lateDisposals === 1, "a disposer attached after teardown must run immediately");

let replacedDisposals = 0;
const replacedDisposer = createDeferredDisposer();
replacedDisposer.attach(() => {
  replacedDisposals += 1;
});
replacedDisposer.attach(() => {
  replacedDisposals += 1;
});
replacedDisposer.dispose();
assert(replacedDisposals === 2, "replacing a disposer must release both registrations");

const browserRuntime = createAppRuntime();
assert(!browserRuntime.isDesktop, "a missing bridge must identify browser preview mode");
let unavailableError = "";
try {
  await browserRuntime.invoke("read_configuration");
} catch (error) {
  unavailableError = error instanceof Error ? error.message : String(error);
}
assert(
  unavailableError === "desktop_runtime_unavailable:read_configuration",
  "browser preview must fail desktop-only calls with a stable error code",
);

const fixed = new FixedTimeService(new Date(2026, 6, 30, 9, 8, 7, 6), 12_345);
assert(fixed.wallClockMs() === new Date(2026, 6, 30, 9, 8, 7, 6).getTime(), "fixed wall clock");
assert(fixed.monotonicMs() === 12_345, "fixed monotonic clock");
assert(formatLocalDate(fixed.now()) === "2026-07-30", "local date formatting");
assert(formatLocalTime(fixed.now()) === "09:08:07", "local time formatting");
assert(monthKey(fixed.now()) === "2026-07", "local month formatting");

console.log("architecture runtime behavior: 15/15 passed");
