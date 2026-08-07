import {
  evaluateWindowSurfaceVariant,
  WINDOW_SURFACE_ATTRIBUTES,
} from "../src/components/windowSurfaceContract";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(WINDOW_SURFACE_ATTRIBUTES["data-shadow-owner"] === "none", "transparent windows must not add an outer shadow arc");
assert(WINDOW_SURFACE_ATTRIBUTES["data-surface-owner"] === "web-content", "Web content must own border, radius and fill");
assert(evaluateWindowSurfaceVariant("single-web-surface").accepted, "single Web surface sample must pass");
assert(!evaluateWindowSurfaceVariant("native-shadow").accepted, "native shadow sample must fail double-arc risk");
assert(!evaluateWindowSurfaceVariant("opaque-outer").accepted, "opaque outer sample must fail transparent-corner risk");

console.log("window surface behavior: 5/5 passed");
