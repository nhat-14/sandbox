#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if ! command -v task >/dev/null 2>&1; then
  echo "⚠️  Taskfile not found. Installing..."
  sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
  echo "✅ Taskfile installed"
fi

run_task() {
  (cd "${PROJECT_ROOT}" && task "$@")
}

usage() {
  echo "Usage: $0 {list-packages|list-devices|list-deployments|list-all-non-interactive|upload|upload-app-non-interactive|delete-package|delete-package-non-interactive|deploy|deploy-non-interactive|delete-instance|delete-instance-non-interactive|get-package-id-by-name|get-device-id-by-role}"
}

if [[ -z "${1:-}" ]]; then
  run_task cli:interactive
  exit 0
fi

case "$1" in
  list-packages) run_task cli:list-packages ;;
  list-devices) run_task cli:list-devices ;;
  list-deployments) run_task cli:list-deployments ;;
  list-all-non-interactive) run_task cli:list-all-non-interactive ;;
  upload) run_task cli:upload ;;
  upload-app-non-interactive) run_task cli:upload-app-non-interactive PACKAGE_NAME="${2:-}" ;;
  delete-package) run_task cli:delete-package ;;
  delete-package-non-interactive) run_task cli:delete-package-non-interactive PACKAGE_NAME="${2:-}" ;;
  deploy) run_task cli:deploy ;;
  deploy-non-interactive) run_task cli:deploy-non-interactive PACKAGE_ID="${2:-}" DEVICE_ID="${3:-}" ;;
  delete-instance) run_task cli:delete-instance ;;
  delete-instance-non-interactive) run_task cli:delete-instance-non-interactive INSTANCE_ID="${2:-}" ;;
  get-package-id-by-name) run_task cli:get-package-id-by-name PACKAGE_NAME="${2:-}" ;;
  get-device-id-by-role) run_task cli:get-device-id-by-role DEVICE_ROLE="${2:-}" ;;
  *)
    usage
    exit 1
    ;;
esac

