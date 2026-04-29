#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ----------------------------
# Environment Loading
# ----------------------------
load_device_agent_env() {
  if [[ -n "$_DEVICE_ENV_LOADED" ]]; then
    return 0
  fi
  export _DEVICE_ENV_LOADED=1

  local device="${1:-${DEVICE_TYPE:-}}"

  # Prompt if not provided
  if [[ -z "$device" ]]; then
    echo "Select device type:"
    echo "  1) Docker"
    echo "  2) K3s"
    echo -n "Enter choice [1-2]: "
    read -r choice

    case "$choice" in
      1) device="docker" ;;
      2) device="k3s" ;;
      *)
        echo "[ERROR] Invalid choice (expected 1 or 2)"
        return 1
        ;;
    esac
  fi

  device="${device,,}"

  if [[ "$device" != "docker" && "$device" != "k3s" ]]; then
    echo "[ERROR] Invalid device type: '$device'"
    return 1
  fi

  export DEVICE_TYPE="$device"
  echo "[INFO] Device type selected: $DEVICE_TYPE"

  # Load environment file
  local env_file="$SCRIPT_DIR/device-agent.env"
  if [[ -f "$env_file" ]]; then
    set -a
    source "$env_file"
    set +a
  else
    echo "[WARN] device-agent.env not found at: $env_file"
  fi
}

# ----------------------------
# Taskfile Wrapper
# ----------------------------
check_taskfile() {
  if ! command -v task &> /dev/null; then
    echo "⚠️  Taskfile not found. Installing..."
    curl -sL https://taskfile.dev/install.sh | sh -s -- -d -b /usr/local/bin
    echo "✅ Taskfile installed"
  fi
}

check_taskfile

# Run task from project root with environment variables
run_task() {
  (
    cd "$PROJECT_ROOT"
    # Export all variables that Taskfiles need
    export DEVICE_TYPE="${DEVICE_TYPE}"
    export REGISTRY_HOST="${REGISTRY_HOST:-127.0.0.1}"
    export REGISTRY_PORT="${REGISTRY_PORT:-5000}"
    export WFM_HOST="${WFM_HOST:-127.0.0.1}"
    export WFM_PORT="${WFM_PORT:-8082}"
    export SANDBOX_REPO_BRANCH="${SANDBOX_REPO_BRANCH:-main}"

    task "$@"
  )
}

# ----------------------------
# Registry Certificate Helper
# ----------------------------
copy_registry_certs_to_agent() {
  local registry_cert_dir="$PROJECT_ROOT/poc/app-registry/.local/certificates"
  local agent_cert_dir="$PROJECT_ROOT/poc/device/agent/.local/certificates"


  if [[ ! -d "$registry_cert_dir" ]]; then
    echo "[ERROR] Registry certificates not found at: $registry_cert_dir"
    echo "[INFO] Please copy the registry certificates manually"
    return 1
  fi

  mkdir -p "$agent_cert_dir"

  # Copy registry CA certificate
  if [[ -f "$registry_cert_dir/ca-crt.pem" ]]; then
    cp "$registry_cert_dir/ca-crt.pem" "$agent_cert_dir/registry-ca-crt.pem"
    echo "✅ Copied registry CA certificate to agent"
  else
    echo "[ERROR] Registry CA certificate not found"
    return 1
  fi
}

# ----------------------------
# Agent Status
# ----------------------------
show_status() {
  echo "Checking device agent status..."
  run_task agent:status
}

# ----------------------------
# Menu
# ----------------------------
show_menu() {
  clear
  echo "Device Type: $DEVICE_TYPE"
  echo ""
  echo "Choose an option:"
  echo "1) Install-prerequisites"
  echo "2) Uninstall-prerequisites"
  echo "3) WFM-Client-Start(docker-compose-device)"
  echo "4) WFM-Client-Stop(docker-compose-device)"
  echo "5) WFM-Client-Start(k3s-device)"
  echo "6) WFM-Client-Stop(k3s-device)"
  echo "7) WFM-Client-Status"
  echo "8) OTEL-collector-promtail-installation"
  echo "9) OTEL-collector-promtail-uninstallation"
  echo "10) cleanup-residual"
  echo "11) Exit"
  read -rp "Enter choice [1-11]: " choice

  case $choice in
    1)
      if [[ "$DEVICE_TYPE" == "docker" ]]; then
        run_task bootstrap:docker
      else
        run_task bootstrap:k3s
      fi
      ;;
    2)
      if [[ "$DEVICE_TYPE" == "docker" ]]; then
        run_task nuke:docker
      else
        run_task nuke:k3s
      fi
      ;;
    3)
      copy_registry_certs_to_agent || return 1
      run_task agent:up TARGET=docker
      ;;
    4)
      run_task agent:down
      ;;
    5)
      copy_registry_certs_to_agent || return 1
      run_task agent:start-helm TARGET=kubernetes
      ;;
    6)
      run_task agent:stop-helm
      ;;
    7)
      show_status
      ;;
    8)
      if [[ "$DEVICE_TYPE" == "docker" ]]; then
        run_task obs-collector:up
      else
        run_task obs-collector:helm-install
      fi
      ;;
    9)
      if [[ "$DEVICE_TYPE" == "docker" ]]; then
        run_task obs-collector:down
      else
        run_task obs-collector:uninstall
      fi
      ;;
    10)
      run_task nuke
      ;;
    11)
      echo "👋 Goodbye!"
      exit 0
      ;;
    *)
      echo "⚠️ Invalid choice"
      ;;
  esac

  echo ""
  read -rp "Press Enter to continue..."
}

# ----------------------------
# Main Loop
# ----------------------------
main_loop() {
  while true; do
    show_menu
  done
}

# ----------------------------
# Main Execution
# ----------------------------
if [[ -z "$1" ]]; then
  # No arguments - prompt for device type, then run interactive menu
  if ! load_device_agent_env; then
    echo "[ERROR] Failed to load device agent environment"
    exit 1
  fi
  main_loop

elif [[ "$1" == "docker" || "$1" == "k3s" ]] && [[ -z "$2" ]]; then
  # Device type specified but no command - run interactive menu
  if ! load_device_agent_env "$1"; then
    echo "[ERROR] Failed to load device agent environment"
    exit 1
  fi
  main_loop

elif [[ "$1" == "docker" || "$1" == "k3s" ]] && [[ -n "$2" ]]; then
  # Device type + command - execute command
  if ! load_device_agent_env "$1"; then
    echo "[ERROR] Failed to load device agent environment"
    exit 1
  fi

  case "$2" in
    install)
      if [[ "$DEVICE_TYPE" == "docker" ]]; then
        run_task bootstrap:docker
      else
        run_task bootstrap:k3s
      fi
      ;;
    uninstall)
      run_task nuke
      ;;
    start-docker)
      copy_registry_certs_to_agent || exit 1
      run_task agent:up TARGET=docker
      ;;
    stop-docker)
      run_task agent:down
      ;;
    start-k3s)
      copy_registry_certs_to_agent || exit 1
      run_task agent:start-helm TARGET=kubernetes
      ;;
    stop-k3s)
      run_task agent:stop-helm
      ;;
    status)
      show_status
      ;;
    otel-install)
      if [[ "$DEVICE_TYPE" == "docker" ]]; then
        run_task obs-collector:up
      else
        run_task obs-collector:helm-install
      fi
      ;;
    otel-uninstall)
      if [[ "$DEVICE_TYPE" == "docker" ]]; then
        run_task obs-collector:down
      else
        run_task obs-collector:uninstall
      fi
      ;;
    cleanup)
      run_task nuke
      ;;
    *)
      echo "[ERROR] Unknown command: $2"
      echo "Available: install, uninstall, start-docker, stop-docker, start-k3s, stop-k3s, status, otel-install, otel-uninstall, cleanup"
      exit 1
      ;;
  esac

else
  # Invalid usage
  echo "[ERROR] Invalid usage. Device type (docker/k3s) is required."
  echo ""
  echo "Usage Examples:"
  echo "  Interactive mode:"
  echo "    $0              # Prompts for device type"
  echo "    $0 docker       # Interactive menu for docker"
  echo "    $0 k3s          # Interactive menu for k3s"
  echo ""
  echo "  Command mode:"
  echo "    $0 docker install"
  echo "    $0 k3s start-k3s"
  exit 1
fi
