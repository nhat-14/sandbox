#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load environment
load_wfm_env() {
  local env_file="$SCRIPT_DIR/wfm.env"
  if [[ -f "$env_file" ]]; then
    echo "[INFO] Loading environment from: $env_file"
    set -a
    source "$env_file"
    set +a
  else
    echo "[WARN] wfm.env not found at: $env_file"
  fi
}

load_wfm_env

# Check Taskfile installation
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
    export REGISTRY_HOST="${REGISTRY_HOST:-127.0.0.1}"
    export REGISTRY_PORT="${REGISTRY_PORT:-5000}"
    export WFM_HOST="${WFM_HOST:-127.0.0.1}"
    export WFM_PORT="${WFM_PORT:-8082}"
    export WFM_SYMPHONY_BRANCH="${WFM_SYMPHONY_BRANCH:-main}"
    export SANDBOX_REPO_BRANCH="${SANDBOX_REPO_BRANCH:-main}"

    task "$@"
  )
}

# Prompt for data cleanup
prompt_data_cleanup() {
  echo ""
  echo "⚠️  Warning: This will delete all Symphony data including Redis volumes"
  read -p "Do you want to clean Symphony data? (y/n): " clean_symphony_data
  if [[ "$clean_symphony_data" =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}

# Interactive menu
show_menu() {
  clear
  echo "Choose an option:"
  echo "1) PreRequisites: Setup"
  echo "2) PreRequisites: Cleanup"
  echo "3) Symphony: Start"
  echo "4) Symphony: Stop"
  echo "5) ObservabilityStack: Start"
  echo "6) ObservabilityStack: Stop"
  echo "7) Exit"
  read -p "Enter choice [1-7]: " choice

  case $choice in
    1)
      run_task bootstrap
      run_task registry:up
      run_task app-supplier-test:push:nextcloud
      run_task app-supplier-test:push:otel
    ;;
    2) run_task nuke ;;
    3) run_task wfm-server:up ;;
    4)
      if prompt_data_cleanup; then
        run_task wfm-server:down
        run_task wfm-server:clean
      else
        run_task wfm-server:down
      fi
      ;;
    5) run_task obs-backend:up ;;
    6) run_task obs-backend:down ;;
    7) echo "👋 Goodbye!"; exit 0 ;;
    *) echo "⚠️ Invalid choice"; sleep 2 ;;
  esac

  echo ""
  read -p "Press Enter to continue..."
}

# Main loop for interactive mode
main_loop() {
  while true; do
    show_menu
  done
}

# CLI mode
if [[ -z "$1" ]]; then
  main_loop
else
  case "$1" in
    install) run_task bootstrap ;;
    uninstall) run_task nuke ;;
    start) run_task wfm-server:up ;;
    stop)
      if prompt_data_cleanup; then
        run_task wfm-server:down
        run_task wfm-server:clean
      else
        run_task wfm-server:down
      fi
      ;;
    obs-install) run_task obs-backend:up ;;
    obs-uninstall) run_task obs-backend:down ;;
    *)
      echo "Usage: $0 {install|uninstall|start|stop|obs-install|obs-uninstall}"
      exit 1
      ;;
  esac
fi
