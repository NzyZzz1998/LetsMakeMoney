import {
  evaluateWindowSurfaceVariant,
  WINDOW_SURFACE_ATTRIBUTES,
} from "../src/components/windowSurfaceContract";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(WINDOW_SURFACE_ATTRIBUTES["data-shadow-owner"] === "native-window", "native window must own the shadow");
assert(WINDOW_SURFACE_ATTRIBUTES["data-surface-owner"] === "web-content", "Web content must own border, radius and fill");
assert(evaluateWindowSurfaceVariant("native-shadow").accepted, "native shadow sample must pass");
assert(!evaluateWindowSurfaceVariant("web-shadow").accepted, "Web shadow sample must fail double-owner risk");
assert(!evaluateWindowSurfaceVariant("opaque-outer").accepted, "opaque outer sample must fail transparent-corner risk");

console.log("window surface behavior: 5/5 passed");
