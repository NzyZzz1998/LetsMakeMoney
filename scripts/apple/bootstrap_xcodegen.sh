#!/usr/bin/env bash
set -euo pipefail

version="2.45.4"
sha256="090ec29491aad50aec10631bf6e62253fed733c50f3aab0f5ffc86bc170bdbef"
install_root="${1:-${RUNNER_TEMP:-/tmp}/lmm-xcodegen}"
archive="${install_root}/xcodegen.zip"
url="https://github.com/yonaskolb/XcodeGen/releases/download/${version}/xcodegen.zip"

mkdir -p "${install_root}"
curl --fail --location --silent --show-error "${url}" --output "${archive}"
echo "${sha256}  ${archive}" | shasum --algorithm 256 --check
ditto -x -k "${archive}" "${install_root}"
"${install_root}/xcodegen/bin/xcodegen" --version

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${install_root}/xcodegen/bin" >> "${GITHUB_PATH}"
fi
