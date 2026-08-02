import React from "react";
import ReactDOM from "react-dom/client";
import { App } from "./App";
import {
  bootstrapTheme,
  listenForThemeChanges,
  synchronizeTheme,
} from "./theme";
import "./styles.css";

const root = document.getElementById("root");
if (!root) {
  throw new Error("Missing application root");
}

async function start() {
  await bootstrapTheme();
  ReactDOM.createRoot(root!).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );

  void listenForThemeChanges().catch(error => {
    console.error("Failed to register the cross-window theme listener", error);
  });
  window.addEventListener("lmm:window-shown", () => {
    void synchronizeTheme("window_shown").catch(() => undefined);
  });
}

void start();
