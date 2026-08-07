import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const styles = readFileSync(resolve(process.cwd(), "apps/windows-v1/src/styles.css"), "utf8");

assert.match(
  styles,
  /\.workbench-content--calendar\s*\{[^}]*overflow-y:\s*auto;[^}]*overflow-x:\s*hidden;/s,
  "calendar content must remain vertically reachable when feedback or six calendar weeks exceed the viewport",
);
assert.match(
  styles,
  /\.page-stack--calendar\s*>\s*\.feedback\s*\{[^}]*margin-top:\s*0;[^}]*min-height:\s*34px;/s,
  "calendar feedback must use the calendar spacing contract instead of form spacing",
);
assert.match(
  styles,
  /\.page-stack--calendar\s*\{[^}]*height:\s*auto;[^}]*min-height:\s*100%;[^}]*overflow:\s*visible;/s,
  "calendar stack must grow beyond the viewport so the outer scroll container can reach every row",
);

console.log("calendar layout behavior: 3/3 passed");
