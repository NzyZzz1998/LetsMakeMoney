import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const styles = readFileSync(resolve(process.cwd(), "apps/windows-v1/src/styles.css"), "utf8");
const app = readFileSync(resolve(process.cwd(), "apps/windows-v1/src/App.tsx"), "utf8");

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
assert.match(
  styles,
  /\.content-grid\s*\{[^}]*grid-template-columns:\s*minmax\(0,\s*1fr\)\s*210px;/s,
  "the standard workbench width must keep the schedule and summary side by side",
);
assert.match(
  styles,
  /@media\s*\(max-width:\s*700px\)\s*\{[^}]*\.content-grid\s*\{[^}]*grid-template-columns:\s*1fr;/s,
  "the two-column workbench layout may stack only below the compact fallback width",
);
assert.match(
  app,
  /<CalendarCoverageNotice\s+coverage=\{calendarMonth\.coverage\}\s+hideEstimated\s*\/>/s,
  "the calendar must not reserve a permanent banner for estimated-year guidance",
);

console.log("calendar layout behavior: 6/6 passed");
