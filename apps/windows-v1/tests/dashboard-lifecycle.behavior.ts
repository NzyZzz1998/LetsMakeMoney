import {
  createDashboardLifecycle,
  shouldApplyDashboardRequest,
  transitionDashboardLifecycle,
} from "../src/dashboardLifecycle";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

let lifecycle = createDashboardLifecycle();
assert(lifecycle.visible && lifecycle.timersRunning, "dashboard starts visible with one timer set");
assert(lifecycle.mounted && lifecycle.generation === 0, "dashboard starts in lifecycle generation zero");
const initialGeneration = lifecycle.generation;
assert(
  shouldApplyDashboardRequest(lifecycle, initialGeneration, 1, 1),
  "a current visible request may update the dashboard",
);

let transition = transitionDashboardLifecycle(lifecycle, { type: "hidden" });
lifecycle = transition.state;
assert(!lifecycle.visible && !lifecycle.timersRunning, "hidden must stop both timers");
assert(transition.effects.join(",") === "stop_timers", "first hidden stops timers once");
assert(lifecycle.generation === 1, "hidden invalidates visible in-flight requests");
assert(
  !shouldApplyDashboardRequest(lifecycle, initialGeneration, 1, 1),
  "a response started before hidden must not overwrite the retained snapshot",
);

transition = transitionDashboardLifecycle(lifecycle, { type: "hidden" });
lifecycle = transition.state;
assert(transition.effects.length === 0, "duplicate hidden must be idempotent");

transition = transitionDashboardLifecycle(lifecycle, { type: "configuration_updated" });
lifecycle = transition.state;
assert(lifecycle.configurationDirty, "hidden configuration changes must be remembered");
assert(transition.effects.length === 0, "hidden configuration changes must not sync");

transition = transitionDashboardLifecycle(lifecycle, { type: "shown" });
lifecycle = transition.state;
assert(lifecycle.visible && lifecycle.timersRunning, "shown must restore timers");
assert(!lifecycle.configurationDirty, "shown sync consumes the hidden configuration change");
assert(lifecycle.generation === 2, "shown starts a fresh request generation");
assert(
  transition.effects.join(",") === "reset_time_sample,start_timers,sync_window_shown",
  "shown must reset time, register one timer set and sync exactly once",
);

transition = transitionDashboardLifecycle(lifecycle, { type: "shown" });
lifecycle = transition.state;
assert(transition.effects.length === 0, "duplicate shown must not duplicate timers or sync");

transition = transitionDashboardLifecycle(lifecycle, { type: "configuration_updated" });
lifecycle = transition.state;
assert(
  transition.effects.join(",") === "sync_configuration_updated",
  "visible configuration changes must sync immediately",
);

transition = transitionDashboardLifecycle(lifecycle, { type: "unmounted" });
lifecycle = transition.state;
assert(!lifecycle.timersRunning, "unmount must stop timers");
assert(!lifecycle.mounted, "unmount permanently rejects later responses");
assert(transition.effects.join(",") === "stop_timers", "unmount cleans up once");
assert(
  !shouldApplyDashboardRequest(lifecycle, lifecycle.generation - 1, 2, 2),
  "an unmounted dashboard must reject late async results",
);

console.log("dashboard lifecycle behavior: 14/14 passed");
