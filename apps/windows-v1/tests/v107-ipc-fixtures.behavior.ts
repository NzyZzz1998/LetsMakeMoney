import fixture from "./fixtures/v107-ipc-contracts.json";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const ids = new Set(fixture.scenarios.map(scenario => scenario.id));
assert(ids.size === fixture.scenarios.length, "IPC fixture ids must be unique");
assert(fixture.contract_version === 1, "IPC fixture contract version drift");
assert(fixture.config_version === 8, "IPC fixture config version drift");

for (const scenario of fixture.scenarios) {
  assert(scenario.command.length > 0, `${scenario.id} must name a command`);
  assert(scenario.invariants.length > 0, `${scenario.id} must preserve at least one invariant`);
  assert(Object.keys(scenario.expected).length > 0, `${scenario.id} must define an outcome`);
}

for (const id of [
  "config-save-success",
  "config-save-unchanged",
  "config-save-failure-preserves-old-config",
  "dashboard-authoritative-success",
  "dashboard-authoritative-failure",
  "window-show-success",
  "window-show-failure-compensates",
  "window-hide-success",
]) {
  const scenario = fixture.scenarios.find(candidate => candidate.id === id);
  assert(scenario?.implementation_status === "active", `${id} must describe an active v1.0.6 behavior`);
}

const overtime = fixture.scenarios.filter(scenario => scenario.domain === "overtime");
assert(overtime.length === 7, "overtime fixture must cover date/month read, save, delete, validation, corruption, and recovery");
assert(overtime.every(scenario => scenario.implementation_status === "active"), "M3 overtime fixtures must describe active behavior");
assert(overtime.every(scenario => "schema_version" in scenario.expected), "overtime responses must carry schema identity");
assert(
  overtime.find(scenario => scenario.id === "overtime-save")?.request.hourly_rate_fen_snapshot === 6250,
  "overtime save must use the persisted rate snapshot field",
);
assert(
  overtime.some(scenario => scenario.command === "recover_overtime_records"),
  "corrupt overtime data must have an explicit recovery contract",
);

console.log(`PASS v1.0.7 IPC fixtures (${fixture.scenarios.length} scenarios)`);
