# VM Control Script

A simple Bash script to start, stop, and connect to a libvirt-managed virtual machine using `virsh` and `virt-viewer`, with robust error handling and configurable options.

## Features

* **Automatic privilege elevation**: Detects if not run as root and re-invokes itself with `sudo`.
* **Dependency checks**: Verifies that required commands (`virsh`, `virt-viewer`, `systemctl`, `grep`) are installed.
* **Configurable VM**: Set `VM_NAME` (default: `win11`) and `VM_URI` (`qemu:///system`).
* **Verbose mode**: `-v` / `--verbose` for detailed logging.
* **Graceful start/stop**: Checks current VM state before issuing `start` or `shutdown`.
* **Libvirt daemon management**: Ensures `libvirtd` is running, with retry logic.
* **Strict error handling**: `set -euo pipefail` to catch failures and undefined variables.

## Prerequisites

* A Linux distribution with **systemd**
* **libvirt** and **QEMU/KVM** installed
* CLI tools: `virsh`, `virt-viewer`, `systemctl`, `grep`, `sudo`

## Installation

1. Copy the script to a system directory (e.g., `/usr/local/bin/vm-control.sh`).
2. Make it executable:

   ```sh
   chmod +x /usr/local/bin/vm-control.sh
   ```
3. (Optional) Create a symbolic link for convenience:

   ```sh
   ln -s /usr/local/bin/vm-control.sh /usr/local/bin/vmctl
   ```

4. (Optional) Set up an alias in your shell configuration file (e.g., `.bashrc` or `.zshrc`):

   ```sh
   alias win11-up='/usr/local/bin/vm-control.sh --name win11'
   alias win11-down='/usr/local/bin/vm-control.sh -s --name win11'
   ```


## Usage

```sh
vm-control.sh [OPTIONS]
```

### Options

| Flag              | Description                            |
| ----------------- | -------------------------------------- |
| `-v`, `--verbose` | Enable verbose logging                 |
| `-s`, `--stop`    | Stop the virtual machine               |
| `--name <name>`   | Specify the VM name (default: `win11`) |
| `-h`, `--help`    | Show this help message and exit        |

### Examples

* **Start the default VM**:

  ```sh
  sudo vm-control.sh
  ```

* **Start with verbose output**:

  ```sh
  sudo vm-control.sh -v
  ```

* **Stop a VM named `ubuntu20`**:

  ```sh
  sudo vm-control.sh -s --name ubuntu20
  ```

## Configuration

You can override the following variables at the top of the script if needed:

```bash
# libvirt connection URI (e.g., qemu:///system, qemu+ssh://user@host/system)
VM_URI="qemu:///system"

# Systemd service managing libvirt
LIBVIRT_SERVICE="libvirtd"

# Number of attempts to start the libvirt daemon
MAX_RETRIES=10

# Seconds to wait between retries
RETRY_INTERVAL=5
```

## VM Configuration

In the `configs` directory you can find the XML configuration files that I personally use in my setup. These can be loaded into librit using the `virsh defin` or `virsh create` commands. Alternatively, you can use the `virt-manager` GUI to load these files. The XML files are:
* `win11.xml`: Windows 11 VM configuration -> [link](configs/win11.xml)

## Error Handling

* Exits on any command failure or undefined variable usage (`set -euo pipefail`).
* Automatically retries starting `libvirtd` up to `$MAX_RETRIES` times.
* Exits with an error if required dependencies are missing.

## License

This project is released under the [MIT License](LICENSE).
