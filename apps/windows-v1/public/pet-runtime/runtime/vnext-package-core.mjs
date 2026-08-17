const SAFE_FALLBACK = Object.freeze({
  kind: "embedded_static_shape",
  logicalSize: { width: 256, height: 208 },
});

const DEFAULT_G8_ACTIONS = Object.freeze([
  "run_loop",
  "run_prepare",
  "run_stop",
  "working_ack",
  "working_play_loop_a",
]);

const REQUIRED_EVIDENCE = Object.freeze([
  "evidence/license.json",
  "evidence/provenance.json",
  "evidence/source-evidence.json",
]);

function degraded(reason, details = undefined) {
  return {
    status: "degraded",
    reason,
    details,
    safeFallback: SAFE_FALLBACK,
    actions: new Map(),
  };
}

function validRelativePath(value) {
  return typeof value === "string"
    && value.length > 0
    && !value.includes("\\")
    && !value.includes(":")
    && !value.startsWith("/")
    && !value.split("/").includes("..");
}

function isSha256(value) {
  return typeof value === "string" && /^[A-F0-9]{64}$/.test(value);
}

function parseJson(bytes) {
  return JSON.parse(new TextDecoder().decode(bytes));
}

function concatBytes(chunks) {
  const length = chunks.reduce((total, chunk) => total + chunk.length, 0);
  const result = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}

function buildTreePayload(files) {
  const encoder = new TextEncoder();
  const chunks = [];
  for (const relativePath of [...files.keys()].sort()) {
    chunks.push(encoder.encode(relativePath));
    chunks.push(Uint8Array.of(0));
    chunks.push(encoder.encode(files.get(relativePath)));
  }
  return concatBytes(chunks);
}

function decodeLinearRuns(runs, width, height) {
  const result = [];
  const pixelCount = width * height;
  for (const run of runs) {
    if (!Array.isArray(run) || run.length !== 2) {
      throw new Error("hitmask_run_invalid");
    }
    let [start, remaining] = run;
    if (!Number.isInteger(start) || !Number.isInteger(remaining) || start < 0 || remaining <= 0 || start + remaining > pixelCount) {
      throw new Error("hitmask_run_out_of_bounds");
    }
    while (remaining > 0) {
      const y = Math.floor(start / width);
      const x = start % width;
      const segmentWidth = Math.min(remaining, width - x);
      result.push({ x, y, width: segmentWidth, height: 1 });
      start += segmentWidth;
      remaining -= segmentWidth;
    }
  }
  return result;
}

function validateAction(action, manifest, boundBytes, hitMasksByPath) {
  if (!action || typeof action.id !== "string" || !Array.isArray(action.frames) || action.frames.length === 0) {
    throw new Error("action_contract_invalid");
  }
  if (!["loop", "oneshot"].includes(action.playbackKind)) {
    throw new Error("action_playback_invalid");
  }
  if (!Number.isInteger(action.maxRuntimeMs) || action.maxRuntimeMs <= 0) {
    throw new Error("action_runtime_invalid");
  }
  const logicalWidth = manifest.logicalSize.width;
  const logicalHeight = manifest.logicalSize.height;
  const frames = action.frames.map((frame, frameIndex) => {
    if (!validRelativePath(frame.asset) || !boundBytes.has(frame.asset)) {
      throw new Error("frame_asset_invalid");
    }
    if (!Number.isInteger(frame.durationMs) || frame.durationMs <= 0 || !isSha256(frame.sha256)) {
      throw new Error("frame_contract_invalid");
    }
    const rect = frame.rect;
    if (
      !rect
      || ![rect.x, rect.y, rect.width, rect.height].every(Number.isInteger)
      || rect.x < 0
      || rect.y < 0
      || rect.width !== logicalWidth
      || rect.height !== logicalHeight
    ) {
      throw new Error("frame_rect_invalid");
    }
    const [maskPath, maskId, ...extra] = String(frame.hitMask ?? "").split("#");
    if (extra.length > 0 || !validRelativePath(maskPath) || !maskId) {
      throw new Error("frame_hitmask_reference_invalid");
    }
    const maskDocument = hitMasksByPath.get(maskPath);
    const mask = maskDocument?.masks?.[maskId];
    if (!mask || !Array.isArray(mask.runs) || !isSha256(mask.sha256)) {
      throw new Error("frame_hitmask_missing");
    }
    return {
      ...frame,
      id: `${action.id}-${String(frameIndex).padStart(3, "0")}`,
      atlasPath: frame.asset,
      hitMaskId: maskId,
      hitMaskRuns: decodeLinearRuns(mask.runs, logicalWidth, logicalHeight),
    };
  });
  const nominalRuntimeMs = frames.reduce((total, frame) => total + frame.durationMs, 0);
  if (action.playbackKind === "oneshot" && action.maxRuntimeMs <= nominalRuntimeMs) {
    throw new Error("action_timeout_not_protective");
  }
  return {
    ...action,
    frames,
    nominalRuntimeMs,
    testPlaceholder: false,
  };
}

export async function loadVNextPayload({
  readFile,
  digest,
  runtimePaths = null,
  expectedActions = DEFAULT_G8_ACTIONS,
  readyStatus = "ready_for_g8",
}) {
  if (
    !Array.isArray(expectedActions)
    || expectedActions.length === 0
    || expectedActions.some((actionId) => typeof actionId !== "string" || actionId.length === 0)
    || new Set(expectedActions).size !== expectedActions.length
  ) {
    return degraded("expected_action_scope_invalid");
  }
  let packageIndexBytes;
  try {
    packageIndexBytes = await readFile("package-index.json");
  } catch (error) {
    return degraded("package_index_missing", String(error));
  }

  let packageIndex;
  try {
    packageIndex = parseJson(packageIndexBytes);
  } catch {
    return degraded("package_index_invalid_json");
  }
  if (
    packageIndex.schemaVersion !== 1
    || packageIndex.manifest !== "motion-manifest.json"
    || !isSha256(packageIndex.manifestSha256)
    || !isSha256(packageIndex.packageTreeSha256)
    || packageIndex.status !== "approved"
    || packageIndex.ready !== true
    || packageIndex.published !== false
  ) {
    return degraded("package_index_contract_invalid");
  }

  let manifestBytes;
  try {
    manifestBytes = await readFile(packageIndex.manifest);
  } catch (error) {
    return degraded("manifest_missing", String(error));
  }
  if (await digest(manifestBytes) !== packageIndex.manifestSha256) {
    return degraded("manifest_hash_mismatch");
  }

  let manifest;
  try {
    manifest = parseJson(manifestBytes);
  } catch {
    return degraded("manifest_invalid_json");
  }
  if (
    manifest.schemaVersion !== 2
    || manifest.packageVersion !== packageIndex.packageVersion
    || manifest.petId !== packageIndex.petId
    || !Array.isArray(manifest.actions)
    || !manifest.sha256?.files
    || !Number.isInteger(manifest.logicalSize?.width)
    || !Number.isInteger(manifest.logicalSize?.height)
  ) {
    return degraded("manifest_contract_invalid");
  }

  const boundHashes = new Map(Object.entries(manifest.sha256.files));
  if (REQUIRED_EVIDENCE.some((relativePath) => !boundHashes.has(relativePath))) {
    return degraded("required_evidence_missing");
  }
  const boundBytes = new Map();
  for (const [relativePath, expectedHash] of boundHashes) {
    if (!validRelativePath(relativePath) || !isSha256(expectedHash)) {
      return degraded("bound_path_or_hash_invalid", relativePath);
    }
    let bytes;
    try {
      bytes = await readFile(relativePath);
    } catch (error) {
      return degraded("bound_file_missing", { relativePath, message: String(error) });
    }
    if (await digest(bytes) !== expectedHash) {
      return degraded("file_hash_mismatch", relativePath);
    }
    boundBytes.set(relativePath, bytes);
  }

  const treeFiles = new Map([[packageIndex.manifest, packageIndex.manifestSha256], ...boundHashes]);
  if (await digest(buildTreePayload(treeFiles)) !== packageIndex.packageTreeSha256) {
    return degraded("package_tree_hash_mismatch");
  }

  const expectedRuntimePaths = ["package-index.json", packageIndex.manifest, ...boundHashes.keys()].sort();
  if (runtimePaths !== null) {
    const normalized = [...runtimePaths].sort();
    if (JSON.stringify(normalized) !== JSON.stringify(expectedRuntimePaths)) {
      return degraded("runtime_allowlist_mismatch", { expected: expectedRuntimePaths, actual: normalized });
    }
  }

  let license;
  let provenance;
  let sourceEvidence;
  try {
    license = parseJson(boundBytes.get("evidence/license.json"));
    provenance = parseJson(boundBytes.get("evidence/provenance.json"));
    sourceEvidence = parseJson(boundBytes.get("evidence/source-evidence.json"));
  } catch {
    return degraded("evidence_invalid_json");
  }
  if (
    license.redistribution !== "product-runtime"
    || provenance.reviewStatus !== "approved"
    || provenance.productReturnApproved !== true
    || provenance.published !== false
    || sourceEvidence.petId !== manifest.petId
  ) {
    return degraded("evidence_contract_invalid");
  }

  const hitMasksByPath = new Map();
  for (const [relativePath, bytes] of boundBytes) {
    if (!relativePath.startsWith("hitmasks/")) {
      continue;
    }
    let document;
    try {
      document = parseJson(bytes);
    } catch {
      return degraded("hitmask_invalid_json", relativePath);
    }
    if (
      document.format !== "alpha-rle-v1"
      || document.logicalWidth !== manifest.logicalSize.width
      || document.logicalHeight !== manifest.logicalSize.height
      || !document.masks
    ) {
      return degraded("hitmask_contract_invalid", relativePath);
    }
    hitMasksByPath.set(relativePath, document);
  }

  const actions = new Map();
  try {
    for (const action of manifest.actions) {
      if (actions.has(action.id)) {
        throw new Error("action_id_duplicate");
      }
      actions.set(action.id, validateAction(action, manifest, boundBytes, hitMasksByPath));
    }
  } catch (error) {
    return degraded(error instanceof Error ? error.message : "action_contract_invalid");
  }
  if (JSON.stringify([...actions.keys()].sort()) !== JSON.stringify([...expectedActions].sort())) {
    return degraded("g8_action_scope_invalid", [...actions.keys()].sort());
  }

  const atlasBytesByPath = new Map(
    [...boundBytes].filter(([relativePath]) => relativePath.startsWith("assets/")),
  );
  return {
    status: readyStatus,
    packageIndex,
    manifest,
    manifestSha256: packageIndex.manifestSha256,
    packageTreeSha256: packageIndex.packageTreeSha256,
    runtimePaths: expectedRuntimePaths,
    actions,
    atlasBytesByPath,
    hitMasksByPath,
    evidence: { license, provenance, sourceEvidence },
    safeFallback: SAFE_FALLBACK,
    adapter: {
      kind: "pet_package_vnext_product",
      packageIndexSchemaVersion: packageIndex.schemaVersion,
      sourceSchemaVersion: manifest.schemaVersion,
      derivedHitMask: false,
      vNextReady: true,
      qualityMaterialApproved: true,
      productReturnApproved: true,
    },
  };
}
