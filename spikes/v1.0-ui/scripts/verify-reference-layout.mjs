import { access, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { chromium } from "../.toolchains/playwright/node_modules/playwright-core/index.mjs";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const spikeRoot = path.resolve(scriptDirectory, "..");
const repositoryRoot = path.resolve(spikeRoot, "..", "..");
const referencePath = path.join(
  repositoryRoot,
  "doc",
  "prototypes",
  "v1.0",
  "index.html",
);
const evidenceDirectory = path.join(
  spikeRoot,
  "evidence",
  "runtime",
  "reference-dpi",
);
const edgeCandidates = [
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
  "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
];

async function firstExistingPath(candidates) {
  for (const candidate of candidates) {
    try {
      await access(candidate);
      return candidate;
    } catch {
      // Try the next standard installation path.
    }
  }
  throw new Error("未找到 Microsoft Edge，无法执行参考原型布局验证。");
}

async function inspectWindow(page, mode, scale) {
  await page.locator(`[data-window="${mode}"]`).first().click();
  await page.waitForTimeout(80);

  const idByMode = {
    mini: "#mini-window",
    workbench: "#workbench-window",
    settings: "#settings-window",
  };
  const locator = page.locator(idByMode[mode]);
  const box = await locator.boundingBox();
  const geometry = await locator.evaluate((element) => ({
    clientWidth: element.clientWidth,
    scrollWidth: element.scrollWidth,
    clientHeight: element.clientHeight,
    scrollHeight: element.scrollHeight,
    overflowX: element.scrollWidth > element.clientWidth,
    overflowY: element.scrollHeight > element.clientHeight,
  }));

  await locator.screenshot({
    path: path.join(
      evidenceDirectory,
      `${mode}-${String(scale).replace(".", "_")}x.png`,
    ),
  });

  return { scale, mode, box, geometry };
}

async function inspectLongAmount(page, scale) {
  await page.locator("#long-content").check({ force: true });
  await page.locator('[data-window="mini"]').first().click();
  await page.waitForTimeout(80);

  const locator = page.locator("#mini-window");
  const box = await locator.boundingBox();
  const geometry = await locator.evaluate((element) => {
    const amount = element.querySelector("[data-amount]");
    return {
      clientWidth: element.clientWidth,
      scrollWidth: element.scrollWidth,
      clientHeight: element.clientHeight,
      scrollHeight: element.scrollHeight,
      overflowX: element.scrollWidth > element.clientWidth,
      overflowY: element.scrollHeight > element.clientHeight,
      amountText: amount?.textContent ?? "",
      amountClientWidth: amount?.clientWidth ?? 0,
      amountScrollWidth: amount?.scrollWidth ?? 0,
      amountClientHeight: amount?.clientHeight ?? 0,
      amountScrollHeight: amount?.scrollHeight ?? 0,
      amountOverflow: amount
        ? amount.scrollWidth > amount.clientWidth ||
          amount.scrollHeight > amount.clientHeight + 1
        : true,
    };
  });

  await locator.screenshot({
    path: path.join(
      evidenceDirectory,
      `mini-long-${String(scale).replace(".", "_")}x.png`,
    ),
  });

  return { scale, mode: "mini-long", box, geometry };
}

await mkdir(evidenceDirectory, { recursive: true });
const executablePath = await firstExistingPath(edgeCandidates);
const browser = await chromium.launch({ headless: true, executablePath });
const results = [];

try {
  for (const scale of [1, 1.25, 1.5]) {
    const context = await browser.newContext({
      viewport: { width: 1920, height: 1080 },
      deviceScaleFactor: scale,
    });
    const page = await context.newPage();
    await page.goto(pathToFileURL(referencePath).href);
    await page.waitForLoadState("load");

    for (const mode of ["mini", "workbench", "settings"]) {
      results.push(await inspectWindow(page, mode, scale));
    }
    results.push(await inspectLongAmount(page, scale));
    await context.close();
  }
} finally {
  await browser.close();
}

const failures = results.filter(
  ({ geometry }) =>
    geometry.overflowX ||
    geometry.overflowY ||
    geometry.amountOverflow === true,
);
const report = {
  referencePath,
  executablePath,
  generatedAt: new Date().toISOString(),
  results,
  failures,
};

await writeFile(
  path.join(evidenceDirectory, "metrics.json"),
  `${JSON.stringify(report, null, 2)}\n`,
  "utf8",
);

if (failures.length > 0) {
  console.error(JSON.stringify(report, null, 2));
  process.exitCode = 1;
} else {
  console.log(
    `REFERENCE_LAYOUT_OK routes=${results.length} scales=100%,125%,150%`,
  );
}
