#!/usr/bin/env bash
# Runs the RatesKit tests with coverage and enforces the 70% coverage gate.
# Works anywhere Swift is installed (macOS, Linux, Windows).
set -euo pipefail
cd "$(dirname "$0")/.."
MIN="${MIN_COVERAGE:-70}"
PY="$(command -v python3 || command -v python)"
MD=()
if [ -n "${COVERAGE_MD:-}" ]; then
  printf '| Package | Line coverage | Lines | Gate |\n|---|---|---|---|\n' > "$COVERAGE_MD"
  MD=(--markdown "$COVERAGE_MD")
fi
cd Packages/RatesKit
swift test --enable-code-coverage
json="$(swift test --show-codecov-path)"
cd ../..
"$PY" scripts/check_coverage.py llvm "$json" --name RatesKit --min "$MIN" "${MD[@]}"
