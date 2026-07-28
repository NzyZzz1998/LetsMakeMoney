import React from "react";
import ReactDOM from "react-dom/client";
import { App } from "./App";
import { listenForThemeChanges } from "./theme";
import "./styles.css";

const root = document.getElementById("root");
const THEME_LISTENER_COLD_START_DELAY_MS = 3000;

if (!root) {
  throw new Error("Missing application root");
}

ReactDOM.createRoot(root).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

// Tauri creates the hidden product windows from its setup hook. Registering an
// IPC listener before that hook returns can race WebView2 initialization.
window.setTimeout(() => {
  void listenForThemeChanges().catch(error => {
    console.error("Failed to register the cross-window theme listener", error);
  });
}, THEME_LISTENER_COLD_START_DELAY_MS);
