import { executeConfigurationSave } from "../src/configurationTransaction";
import { defaultConfig, type AppConfig } from "../src/domain/configuration";
import {
  applyDashboardSyncFailure,
  createBrowserDashboardProjection,
  createTauriDashboardProjection,
} from "../src/dashboardProjection";
import {
  createAppRuntime,
  createDeferredDisposer,
  type DesktopBridge,
} from "../src/runtime/appRuntime";
import { createConfigurationService } from "../src/services/configurationService";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const original: AppConfig = {
  ...defaultConfig,
  monthly_salary: 10_000,
};
const edited: AppConfig = {
  ...original,
  monthly_salary: 12_000,
};

let saveCalls = 0;
let saveMode: "saved" | "failed" | "throw" = "saved";
const configurationService = {
  async save() {
    saveCalls += 1;
    if (saveMode === "throw") throw new Error("配置目录不可写");
    return saveMode === "failed"
      ? { status: "failed" as const, message: "配置校验失败" }
      : { status: "saved" as const, message: "设置已保存" };
  },
};

const unchanged = await executeConfigurationSave({
  persisted: original,
  draft: original,
  service: configurationService,
});
assert(unchanged.ok && unchanged.feedback === "unchanged", "unchanged save returns unchanged");
assert(saveCalls === 0 && !unchanged.publishUpdated, "unchanged save does not invoke native storage");

saveMode = "failed";
const businessFailure = await executeConfigurationSave({
  persisted: original,
  draft: edited,
  service: configurationService,
});
assert(!businessFailure.ok && businessFailure.feedback === "failed", "business save failure is stable");
assert(
  businessFailure.persisted.monthly_salary === 10_000
  && businessFailure.draft.monthly_salary === 12_000,
  "business failure keeps the old authority and user draft",
);
assert(
  businessFailure.message.includes("配置校验失败"),
  "business failure exposes a readable classified message",
);

saveMode = "throw";
const invokeFailure = await executeConfigurationSave({
  persisted: original,
  draft: edited,
  service: configurationService,
});
assert(!invokeFailure.ok && invokeFailure.feedback === "failed", "invoke exception maps to failed");
assert(
  invokeFailure.persisted.monthly_salary === 10_000
  && invokeFailure.draft.monthly_salary === 12_000,
  "invoke exception cannot pollute the old configuration or discard the draft",
);
assert(invokeFailure.message.includes("配置目录不可写"), "invoke exception remains actionable");

saveMode = "saved";
const retrySuccess = await executeConfigurationSave({
  persisted: invokeFailure.persisted,
  draft: invokeFailure.draft,
  service: configurationService,
});
assert(retrySuccess.ok && retrySuccess.feedback === "saved", "retry converges to saved");
assert(retrySuccess.persisted.monthly_salary === 12_000, "retry updates the authoritative configuration");
assert(retrySuccess.publishUpdated, "successful retry requests one configuration broadcast");

const trustedSnapshot = {
  state: "ready" as const,
  syncState: "synced" as const,
  amount: 186.42,
  ownerDate: "2026-07-31",
  phase: "working",
};
const staleSnapshot = applyDashboardSyncFailure(trustedSnapshot, {
  code: "calculation_unavailable",
  message: "计算不可用",
  blocked: false,
});
assert(staleSnapshot.state === "ready" && staleSnapshot.syncState === "stale", "sync failure marks trusted data stale");
assert(staleSnapshot.amount === 186.42, "sync failure retains the last trusted income");

const blockedSnapshot = applyDashboardSyncFailure(trustedSnapshot, {
  code: "calculation_unavailable",
  message: "计算不可用",
  blocked: true,
});
assert(blockedSnapshot.state === "error", "repeated boundary failure blocks local projection");
assert(blockedSnapshot.amount === 186.42, "blocked state still retains the trusted snapshot");

const initialFailure = applyDashboardSyncFailure({
  state: "loading" as const,
  syncState: "syncing" as const,
}, {
  code: "calculation_unavailable",
  message: "请稍后重试",
  blocked: false,
});
assert(initialFailure.state === "error", "initial failure without authority shows an error");
assert(initialFailure.message === "请稍后重试", "initial failure does not invent income");

const browserProjection = createBrowserDashboardProjection({
  phase: "working",
  ownerDate: "2026-02-02",
  amount: 125,
  dailySalary: 500,
  hourlySalary: 62.5,
  progressPercent: 25,
  completedSeconds: 7_200,
  effectiveSeconds: 28_800,
  monthTotal: 125,
  expectedMonthlyPay: 10_000,
  workdays: 20,
  salarySlotCount: 20,
  algorithmVersion: "fixture",
});
const tauriProjection = createTauriDashboardProjection({
  phase: "working",
  ownerDate: "2026-02-02",
  earnedMinor: 12_500,
  dailyTargetMinor: 50_000,
  hourlySalaryMinor: 6_250,
  progressRatio: 0.25,
  completedSeconds: 7_200,
  effectiveSeconds: 28_800,
  monthEarnedMinor: 12_500,
  payableSalaryMinor: 1_000_000,
  workdays: 20,
  salarySlotCount: 20,
  algorithmVersion: "fixture",
});
assert(
  JSON.stringify(browserProjection) === JSON.stringify(tauriProjection),
  "browser and Tauri adapters produce the same domain result for an equivalent fixture",
);
assert(!("message" in tauriProjection), "retry success projection clears the prior error message");

let activeListeners = 0;
let unlistenCalls = 0;
const bridge: DesktopBridge = {
  async invoke<T>() {
    return { status: "saved", message: "设置已保存" } as T;
  },
  async emit() {},
  async listen<T>(_event: string, _handler: (payload: T) => void) {
    activeListeners += 1;
    let active = true;
    return () => {
      if (!active) return;
      active = false;
      activeListeners -= 1;
      unlistenCalls += 1;
    };
  },
};
const runtime = createAppRuntime(bridge);
const firstMount = createDeferredDisposer();
const firstListener = await runtime.listen("lmm://configuration-updated", () => undefined);
firstMount.attach(firstListener);
assert(activeListeners === 1, "first mount registers one listener");
firstMount.dispose();
assert(activeListeners === 0 && unlistenCalls === 1, "unmount removes the first listener");

const secondMount = createDeferredDisposer();
const secondListener = await runtime.listen("lmm://configuration-updated", () => undefined);
secondMount.attach(secondListener);
const replacementListener = await runtime.listen("lmm://configuration-updated", () => undefined);
secondMount.attach(replacementListener);
assert(activeListeners === 1, "replacement or duplicate mount keeps only one listener");
secondMount.dispose();
secondMount.dispose();
assert(activeListeners === 0 && unlistenCalls === 3, "listener cleanup is idempotent");

const desktopConfiguration = createConfigurationService(runtime);
const desktopSave = await executeConfigurationSave({
  persisted: original,
  draft: edited,
  service: desktopConfiguration,
});
assert(desktopSave.ok && desktopSave.feedback === "saved", "Tauri command success reaches React transaction state");

console.log("high-risk combinations behavior: 24/24 passed");
