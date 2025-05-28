#!/usr/bin/env bash

# Exit on error
set -e

SYSTEM_NAME=""
DISK=""
SKIP_CONFIRM=false
SHOW_USAGE=false

# Parse arguments
for arg in "$@"; do
  if [[ "$arg" == "-h" ]]; then
    SHOW_USAGE=true
  elif [[ "$arg" == "-y" ]]; then
    SKIP_CONFIRM=true
  elif [[ -z "$SYSTEM_NAME" ]]; then
    SYSTEM_NAME="$arg"
  elif [[ -z "$DISK" ]]; then
    DISK="$arg"
  fi
done

if [[ "$SHOW_USAGE" == "true" || -z "$SYSTEM_NAME" || -z "$DISK" ]]; then
    echo "Usage: $0 [<options>] <system-name> <disk>"
    echo "Options:"
    echo "  -h    Show this help message"
    echo "  -y    Skip confirmation"
    echo ""
    echo "Example: $0 homelab1 /dev/nvme0s1"
    echo "Example: $0 -y homelab1 /dev/nvme0s1"
    exit 1
fi

echo "Installing NixOS on $SYSTEM_NAME with disk $DISK"

# Get disk device from second argument, or auto-detect
# We need to know which disk to install on (like /dev/sda, /dev/vda)
PART_DELIM=""  # Default delimiter for partitions (sda1, vda1)

if [[ "$DISK" == "/dev/nvme"* ]]; then
  PART_DELIM="p"  # NVMe uses pX (nvme0n1p1, nvme0n1p2)
fi

# Verify disk exists
echo "Verifying disk exists..."
if ! lsblk "$DISK" &>/dev/null; then
    echo "Error: Disk $DISK does not exist or is not accessible"
    exit 1
fi

echo "Installing $SYSTEM_NAME to $DISK"

# Show current disk layout to user before we modify anything
echo
lsblk
echo

# Skip confirmation if SKIP_CONFIRM is true (-y flag is set)
if [[ "$SKIP_CONFIRM" == "false" ]]; then
    # Ask user to confirm they're okay with erasing the disk
    read -p "This will ERASE all data on $DISK. Continue? (y/N): " response
    case "$response" in
        [yY]) ;;
        *) echo "Installation cancelled"; exit 1 ;;
    esac
fi

# Cleanup and unmount everything
echo "[1/8] Cleaning up any previous installation..."
# Turn off swap first (important: do this before unmounting)
set +e  # Don't exit on errors during cleanup
find /proc/swaps -type f 2>/dev/null | grep -v "^Filename" | awk '{print $1}' | xargs -r swapoff
# Unmount everything mounted under /mnt if it exists
if mountpoint -q /mnt; then
    umount -R /mnt
fi
# Wipe filesystem signatures to ensure clean slate
wipefs -a $DISK
set -e  # Resume exiting on errors

# Partition disk
echo "[2/8] Partitioning disk..."
# Create a new GPT (modern partition table format)
parted $DISK -- mklabel gpt
# Create root partition (where Linux lives) from 512MB to 8GB before end
parted $DISK -- mkpart root ext4 512MB -8GB
# Create swap partition (virtual memory) in the last 8GB
parted $DISK -- mkpart swap linux-swap -8GB 100%
# Create boot partition (where bootloader lives) in first 512MB
parted $DISK -- mkpart ESP fat32 1MB 512MB
# Mark the boot partition as bootable
parted $DISK -- set 3 esp on

# Wait for kernel to recognize new partitions
echo "[3/8] Waiting for partitions to be ready..."
sleep 2
partprobe $DISK

# Format partitions
echo "[4/8] Formatting partitions..."
# Use the partition delimiter to construct the right partition names
mkfs.ext4 -F -L nixos ${DISK}${PART_DELIM}1
mkswap -L swap ${DISK}${PART_DELIM}2
mkfs.fat -F 32 -n boot ${DISK}${PART_DELIM}3

# Mount partitions
echo "[5/8] Mounting partitions..."
# Mount the root filesystem to /mnt (where we'll install NixOS)
mount /dev/disk/by-label/nixos /mnt
# Create boot directory
mkdir -p /mnt/boot
# Mount boot partition with specific permissions (umask=077 makes it only accessible by root)
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot
# Enable the swap partition using the direct device reference
swapon ${DISK}${PART_DELIM}2

# Generate hardware configuration
echo "[6/8] Generating hardware configuration..."
# This detects hardware and creates the necessary config files
nixos-generate-config --root /mnt

# Prepare the flake with the correct hardware configuration
echo "[7/8] Preparing and installing NixOS..."
# Create a temporary working directory
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Clone the repository
echo "Cloning the flake repository..."
git clone https://github.com/primalivet/homelab.git
cd homelab

# Replace the hardware configuration in the flake with the generated one
echo "Updating hardware configuration..."
mkdir -p "machines/$SYSTEM_NAME"
cp /mnt/etc/nixos/hardware-configuration.nix "machines/$SYSTEM_NAME/"

# Install NixOS using the local modified flake
echo "Installing NixOS..."
nixos-install --no-root-passwd --root /mnt --flake ".#$SYSTEM_NAME"

# Cleanup the temporary directory
cd /
rm -rf $TEMP_DIR

# Cleanup
echo "[8/8] Cleaning up..."
# Unmount everything in reverse order
umount /mnt/boot
umount /mnt
# Turn off swap using the direct device reference
swapoff ${DISK}${PART_DELIM}2

echo
echo "Installation complete!"
echo "You can now reboot."
