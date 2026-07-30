import {
  createDashboardLifecycle,
  transitionDashboardLifecycle,
} from "../src/dashboardLifecycle";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

let lifecycle = createDashboardLifecycle();
assert(lifecycle.visible && lifecycle.timersRunning, "dashboard starts visible with one timer set");

let transition = transitionDashboardLifecycle(lifecycle, { type: "hidden" });
lifecycle = transition.state;
assert(!lifecycle.visible && !lifecycle.timersRunning, "hidden must stop both timers");
assert(transition.effects.join(",") === "stop_timers", "first hidden stops timers once");

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
assert(transition.effects.join(",") === "stop_timers", "unmount cleans up once");

console.log("dashboard lifecycle behavior: 8/8 passed");
