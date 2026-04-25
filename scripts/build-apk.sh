#!/usr/bin/env bash
# Build the Android APK via a separate GitHub Actions workflow run.
#
# Usage:
#   ./scripts/build-apk.sh [branch] [output-dir]
#
# Arguments:
#   branch     Git ref to build (default: current branch).
#              The ref must already be pushed to the remote.
#   output-dir Local directory to download APKs into (default: /tmp/apk-output).
#
# The script:
#   1. Triggers the "Build (Android APK)" workflow on the given ref.
#   2. Waits for the run to finish.
#   3. Downloads the `release-apks` artifact into <output-dir>.
#
# The Copilot agent environment injects GITHUB_TOKEN automatically.
# If you need to override it, set GH_TOKEN before calling this script.

set -euo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
OUTDIR="${2:-/tmp/apk-output}"
REPO="shelbeely/GitSync"
WORKFLOW="build.yml"

echo "==> Triggering '${WORKFLOW}' on ref '${BRANCH}' ..."
gh workflow run "${WORKFLOW}" --repo "${REPO}" --ref "${BRANCH}"

# Give the API a moment to register the new run.
sleep 8

# Find the run that was just created (most recent queued/in-progress run for this workflow).
RUN_ID=$(gh run list \
  --workflow="${WORKFLOW}" \
  --repo="${REPO}" \
  --limit=1 \
  --json databaseId \
  --jq '.[0].databaseId')

if [[ -z "${RUN_ID}" ]]; then
  echo "ERROR: Could not find a workflow run. Did the dispatch succeed?" >&2
  exit 1
fi

echo "==> Watching run ${RUN_ID} (this will take ~15-20 minutes) ..."
gh run watch "${RUN_ID}" --repo "${REPO}" --exit-status

echo "==> Downloading APK artifacts to '${OUTDIR}' ..."
mkdir -p "${OUTDIR}"
gh run download "${RUN_ID}" \
  --repo "${REPO}" \
  --name release-apks \
  --dir "${OUTDIR}"

echo "==> Done. APKs are in ${OUTDIR}:"
ls -lh "${OUTDIR}"
