import process from "node:process";

function usage() {
  console.error("Usage: node cdp_v107_probe.mjs <websocket-url> <snapshot|evaluate> [base64-expression]");
  process.exit(2);
}

const [, , websocketUrl, mode, encodedExpression] = process.argv;
if (!websocketUrl || !mode) usage();

const socket = new WebSocket(websocketUrl);
let nextId = 1;
const pending = new Map();

function request(method, params = {}) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}

socket.addEventListener("message", event => {
  const message = JSON.parse(String(event.data));
  if (!message.id || !pending.has(message.id)) return;
  const waiter = pending.get(message.id);
  pending.delete(message.id);
  if (message.error) waiter.reject(new Error(`${message.error.code}: ${message.error.message}`));
  else waiter.resolve(message.result);
});

socket.addEventListener("close", () => {
  for (const { reject } of pending.values()) reject(new Error("CDP connection closed"));
  pending.clear();
});

function waitForOpen() {
  return new Promise((resolve, reject) => {
    socket.addEventListener("open", resolve, { once: true });
    socket.addEventListener("error", () => reject(new Error("CDP connection failed")), { once: true });
  });
}

function snapshotExpression() {
  return String.raw`(async () => {
    await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    const navigation = performance.getEntriesByType("navigation")[0] ?? null;
    const paints = Object.fromEntries(
      performance.getEntriesByType("paint").map(entry => [entry.name, entry.startTime]),
    );
    const resources = performance.getEntriesByType("resource");
    const longTasks = performance.getEntriesByType("longtask").map(entry => entry.duration);
    const bodyText = document.body?.innerText ?? "";
    return {
      title: document.title,
      url: location.href,
      ready_state: document.readyState,
      body_text: bodyText.slice(0, 600),
      body_text_length: bodyText.length,
      theme: document.documentElement.dataset.theme ?? null,
      theme_ready: document.documentElement.dataset.themeReady ?? null,
      time_origin_epoch_ms: performance.timeOrigin,
      first_paint_ms: paints["first-paint"] ?? null,
      first_contentful_paint_ms: paints["first-contentful-paint"] ?? null,
      dom_content_loaded_ms: navigation?.domContentLoadedEventEnd ?? null,
      load_event_end_ms: navigation?.loadEventEnd ?? null,
      resource_count: resources.length,
      resource_transfer_bytes: resources.reduce((total, entry) => total + (entry.transferSize || 0), 0),
      resource_encoded_bytes: resources.reduce((total, entry) => total + (entry.encodedBodySize || 0), 0),
      long_task_count: longTasks.length,
      max_long_task_ms: longTasks.length ? Math.max(...longTasks) : 0,
      tauri_bridge_ready: typeof window.__TAURI_INTERNALS__?.invoke === "function"
    };
  })()`;
}

await waitForOpen();
try {
  await request("Runtime.enable");
  let expression;
  if (mode === "snapshot") {
    expression = snapshotExpression();
  } else if (mode === "evaluate" && encodedExpression) {
    expression = Buffer.from(encodedExpression, "base64").toString("utf8");
  } else {
    usage();
  }
  const response = await request("Runtime.evaluate", {
    expression,
    awaitPromise: true,
    returnByValue: true,
    userGesture: true,
  });
  if (response.exceptionDetails) {
    throw new Error(response.exceptionDetails.exception?.description ?? response.exceptionDetails.text);
  }
  process.stdout.write(JSON.stringify(response.result?.value ?? null));
} finally {
  socket.close();
}
