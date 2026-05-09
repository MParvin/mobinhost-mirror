# Mobinhost Mirror Setup

A simple bash script to change your Linux system repositories to use Mobinhost mirror servers.

## What It Does

This script automatically:
- Backs up your current repository settings
- Changes repository URLs to use mirror.mobinhost.com
- Tests if the new settings work
- Restores the backup if something goes wrong

## Supported Operating Systems

- Ubuntu
- Debian
- Raspbian
- Fedora
- AlmaLinux
- RHEL / CentOS (EPEL repositories)
- Alpine Linux
- Arch Linux
- Manjaro

## How to Use

### Step 1: Download the Script

```bash
git clone https://github.com/yourusername/mobinhost-mirror.git
cd mobinhost-mirror
```

### Step 2: Make the Script Executable

```bash
chmod +x mirror-setup.sh
```

### Step 3: Run with Sudo

```bash
sudo ./mirror-setup.sh
```

## What to Expect

The script will:
1. Check if you are running it with sudo
2. Detect your operating system
3. Create a backup of your current settings
4. Change repositories to use Mobinhost mirror
5. Test if the new settings work
6. Show success message or restore backup if failed

## Backup Location

All backups are saved in `/var/backups/mobinhost-mirror/`

Each backup has a timestamp, so you can find your old settings if needed.

## If Something Goes Wrong

The script will automatically restore your backup if the new settings don't work.

Error messages are simple and tell you what went wrong.

## Manual Restore

If you need to manually restore your backup:

### For Ubuntu/Debian/Raspbian:
```bash
sudo cp /var/backups/mobinhost-mirror/sources.list.backup.* /etc/apt/sources.list
sudo apt update
```

### For Fedora:
```bash
cd /etc/yum.repos.d/
sudo tar xzf /var/backups/mobinhost-mirror/fedora_backup.*.tar.gz
sudo dnf clean all && sudo dnf makecache
```

### For AlmaLinux:
```bash
cd /etc/yum.repos.d/
sudo tar xzf /var/backups/mobinhost-mirror/almalinux_backup.*.tar.gz
sudo dnf clean all && sudo dnf makecache
```

### For Alpine:
```bash
sudo cp /var/backups/mobinhost-mirror/repositories.backup.* /etc/apk/repositories
sudo apk update
```

### For Arch/Manjaro:
```bash
sudo cp /var/backups/mobinhost-mirror/mirrorlist.backup.* /etc/pacman.d/mirrorlist
sudo pacman -Sy
```

## Requirements

- Root or sudo access
- Internet connection
- One of the supported operating systems

## License

See LICENSE file for details.
