#!/bin/bash
# This script was written in a hurry, but it does it's job.
# I had the foresigh to make it a bit more robust by using getopt + adding a VM_NAME variable so it can be used for other VMs too.

set -euo pipefail
IFS=$'\n\t'

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    # Try to recall the script with sudo
    echo "This script requires root privileges. Attempting to run with sudo..."

    if command -v sudo >/dev/null 2>&1; then
        # Re-run the script with sudo
        exec sudo "$0" "$@"
    else
        echo "Error: This script requires root privileges. Please run it as root or with sudo."
        exit 1
    fi
fi

for cmd in virsh virt-viewer systemctl grep; do
  if ! command -v "$cmd" >/dev/null; then
    echo "Error: $cmd is required but not installed." >&2
    exit 1
  fi
done

VERBOSE=false
STOP=false
VM_NAME="win11"
VM_URI="qemu:///system"
LIBVIRT_SERVICE="libvirtd"
MAX_RETRIES=10
RETRY_INTERVAL=5

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  -v, --verbose         Enable verbose output"
  echo "  -s, --stop            Stop the virtual machine"
  echo "      --name <name>     Specify the name of the VM (default: win11)"
  echo "  -h, --help            Display this help message"
  exit "$1"
}

# Use GNU getopt if available, otherwise fall back to the built-in getopts
if command -v getopt >/dev/null 2>&1; then
  # GNU getopt is available
  TEMP=$(getopt -o vsn:h --long verbose,stop,name:,help -n "$0" -- "$@")
  if [ $? != 0 ]; then
    echo "Error: Failed to parse options." >&2
    exit 1
  fi
  eval set -- "$TEMP"

  while true; do
    case "$1" in
      -v | --verbose ) VERBOSE=true; shift ;;
      -s | --stop ) STOP=true; shift ;;
      -n | --name ) VM_NAME="$2"; shift 2 ;;
      -h | --help ) usage 0; shift ;;
      -- ) shift; break ;;
      * ) break ;;
    esac
  done
else
  # Fallback to built-in getopts (less robust for long options with arguments, but should be fine you know)
  while getopts ":vsn:h" opt; do
    case "$opt" in
      v) VERBOSE=true ;;
      s) STOP=true ;;
      n) VM_NAME="$OPTARG" ;;
      h) usage 0 ;;
      \?) echo "Error: Invalid option -$OPTARG" >&2; exit 1 ;;
      :) echo "Error: Option -$OPTARG requires an argument." >&2; exit 1 ;;
    esac
  done

  shift $((OPTIND - 1))
fi

log() {
   if [ "${VERBOSE:-false}" = true ]; then
     echo "$@"
   fi
 }

log "Verbose mode is enabled."

if [ -n "$VM_NAME" ]; then
    log "Operating on VM: $VM_NAME"
fi

function ensure_daemon_running() {
    # Check if the libvirt daemon is running
    if ! systemctl is-active --quiet libvirtd; then
        log "Libvirt daemon is not running. Attempting to start it..."
        systemctl start libvirtd
    fi

    # Check if the libvirt daemon is running
    for ((i=1; i<=MAX_RETRIES; i++)); do
        if systemctl is-active --quiet libvirtd; then
            log "Libvirt daemon is running."
            break
        else
            log "Libvirt daemon is not running. Attempting to start it... ($i/$MAX_RETRIES)"
            sleep $RETRY_INTERVAL
        fi

        # If we reach the maximum number of retries, exit with an error
        if [ $i -eq $MAX_RETRIES ]; then
            log "Failed to start libvirt daemon after $MAX_RETRIES attempts."
            exit 1
        fi
    done
}

virsh_cmd() {
  virsh --connect "$VM_URI" "$@"
}

function start_vm() {
    log "Attempting to start " $VM_NAME "..." 

    if ! virsh_cmd list --state-running | grep -qF "$VM_NAME"; then
        log "Starting " $VM_NAME "..." 
        virsh_cmd start "$VM_NAME"
    else
        log $VM_NAME " is already running."
    fi
}

function stop_vm() {
    log "Attempting to stop " $VM_NAME "..." 

    if ! virsh_cmd list --state-shutoff | grep -qF "$VM_NAME"; then
        log "STOP " $VM_NAME "..." 
        virsh_cmd shutdown $VM_NAME
    else
        log $VM_NAME " is already stopped."
    fi
}

function connect_vm() {
    virt-viewer --connect $VM_URI $VM_NAME &
}

ensure_daemon_running

if [ "$STOP" = true ]; then
    stop_vm
else
    start_vm
    connect_vm
fi
