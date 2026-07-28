import { normalizeThemeMode } from "../src/theme";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(normalizeThemeMode("light") === "light", "light must remain light");
assert(normalizeThemeMode("dark") === "dark", "dark must remain dark");
assert(normalizeThemeMode("system") === "light", "unsupported system mode must fall back to light");
assert(normalizeThemeMode("midnight") === "light", "unknown modes must fall back to light");
assert(normalizeThemeMode(undefined) === "light", "missing mode must fall back to light");

console.log("v1.0.2 theme behavior: 5/5 passed");
