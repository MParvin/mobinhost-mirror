#!/bin/bash

set -e

MIRROR_URL="http://mirror.mobinhost.com"
BACKUP_DIR="/var/backups/mobinhost-mirror"
ERROR_LOG="$BACKUP_DIR/error.log"

error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run with sudo or as root"
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$ID"
        OS_VERSION="$VERSION_ID"
        OS_CODENAME="${VERSION_CODENAME:-}"
    else
        error_exit "Cannot detect operating system"
    fi
}

is_supported_os() {
    case "$OS_NAME" in
        ubuntu|debian|fedora|almalinux|alpine|arch|manjaro|raspbian|rhel|centos)
            return 0
            ;;
        *)
            error_exit "Unsupported operating system: $OS_NAME"
            ;;
    esac
}

create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
}

backup_ubuntu_debian() {
    if [ -f /etc/apt/sources.list ]; then
        cp /etc/apt/sources.list "$BACKUP_DIR/sources.list.backup.$(date +%s)"
    fi
}

backup_fedora() {
    cd /etc/yum.repos.d/
    if ls fedora*.repo 1> /dev/null 2>&1; then
        tar czf "$BACKUP_DIR/fedora_backup.$(date +%s).tar.gz" fedora*.repo
    fi
}

backup_almalinux() {
    cd /etc/yum.repos.d/
    if ls almalinux*.repo 1> /dev/null 2>&1; then
        tar czf "$BACKUP_DIR/almalinux_backup.$(date +%s).tar.gz" almalinux*.repo
    fi
}

backup_rhel_centos() {
    cd /etc/yum.repos.d/
    if ls *.repo 1> /dev/null 2>&1; then
        tar czf "$BACKUP_DIR/rhel_centos_backup.$(date +%s).tar.gz" *.repo
    fi
}

backup_alpine() {
    if [ -f /etc/apk/repositories ]; then
        cp /etc/apk/repositories "$BACKUP_DIR/repositories.backup.$(date +%s)"
    fi
}

backup_arch_manjaro() {
    if [ -f /etc/pacman.d/mirrorlist ]; then
        cp /etc/pacman.d/mirrorlist "$BACKUP_DIR/mirrorlist.backup.$(date +%s)"
    fi
}

restore_latest_backup() {
    case "$OS_NAME" in
        ubuntu|debian|raspbian)
            LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/sources.list.backup.* 2>/dev/null | head -n1)
            if [ -n "$LATEST_BACKUP" ]; then
                cp "$LATEST_BACKUP" /etc/apt/sources.list
                echo "Restored configuration from backup"
            fi
            ;;
        fedora)
            LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/fedora_backup.*.tar.gz 2>/dev/null | head -n1)
            if [ -n "$LATEST_BACKUP" ]; then
                cd /etc/yum.repos.d/
                tar xzf "$LATEST_BACKUP"
                echo "Restored configuration from backup"
            fi
            ;;
        almalinux)
            LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/almalinux_backup.*.tar.gz 2>/dev/null | head -n1)
            if [ -n "$LATEST_BACKUP" ]; then
                cd /etc/yum.repos.d/
                tar xzf "$LATEST_BACKUP"
                echo "Restored configuration from backup"
            fi
            ;;
        rhel|centos)
            LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/rhel_centos_backup.*.tar.gz 2>/dev/null | head -n1)
            if [ -n "$LATEST_BACKUP" ]; then
                cd /etc/yum.repos.d/
                tar xzf "$LATEST_BACKUP"
                echo "Restored configuration from backup"
            fi
            ;;
        alpine)
            LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/repositories.backup.* 2>/dev/null | head -n1)
            if [ -n "$LATEST_BACKUP" ]; then
                cp "$LATEST_BACKUP" /etc/apk/repositories
                echo "Restored configuration from backup"
            fi
            ;;
        arch|manjaro)
            LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/mirrorlist.backup.* 2>/dev/null | head -n1)
            if [ -n "$LATEST_BACKUP" ]; then
                cp "$LATEST_BACKUP" /etc/pacman.d/mirrorlist
                echo "Restored configuration from backup"
            fi
            ;;
    esac
}

configure_ubuntu() {
    if [ -z "$OS_CODENAME" ]; then
        OS_CODENAME=$(lsb_release -cs)
    fi
    
    tee /etc/apt/sources.list > /dev/null <<EOF
deb $MIRROR_URL/ubuntu $OS_CODENAME main restricted universe multiverse
deb $MIRROR_URL/ubuntu $OS_CODENAME-updates main restricted universe multiverse
deb $MIRROR_URL/ubuntu $OS_CODENAME-backports main restricted universe multiverse
deb $MIRROR_URL/ubuntu $OS_CODENAME-security main restricted universe multiverse
EOF
}

configure_debian() {
    if [ -z "$OS_CODENAME" ]; then
        OS_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d'=' -f2)
    fi
    
    tee /etc/apt/sources.list > /dev/null <<EOF
deb $MIRROR_URL/debian $OS_CODENAME main
deb $MIRROR_URL/debian-security $OS_CODENAME-security main
EOF
}

configure_raspbian() {
    if [ -z "$OS_CODENAME" ]; then
        OS_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d'=' -f2)
    fi
    
    tee /etc/apt/sources.list > /dev/null <<EOF
deb $MIRROR_URL/raspbian $OS_CODENAME main contrib non-free
EOF
}

configure_fedora() {
    sed -i "s|^metalink=|#metalink=|g" /etc/yum.repos.d/fedora*.repo
    sed -i "s|^#baseurl=http://download.example/pub/fedora/linux|baseurl=$MIRROR_URL/fedora|g" /etc/yum.repos.d/fedora*.repo
    sed -i "s|^baseurl=http://download.example/pub/fedora/linux|baseurl=$MIRROR_URL/fedora|g" /etc/yum.repos.d/fedora*.repo
}

configure_almalinux() {
    sed -i "s|^mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/almalinux*.repo
    sed -i "s|^#baseurl=https://repo.almalinux.org|baseurl=$MIRROR_URL/almalinux|g" /etc/yum.repos.d/almalinux*.repo
    sed -i "s|^baseurl=https://repo.almalinux.org|baseurl=$MIRROR_URL/almalinux|g" /etc/yum.repos.d/almalinux*.repo
}

configure_rhel_centos() {
    if [ -f /etc/yum.repos.d/epel.repo ]; then
        sed -i "s|^metalink=|#metalink=|g" /etc/yum.repos.d/epel.repo
        sed -i "s|^#baseurl=http://download.fedoraproject.org/pub/epel|baseurl=$MIRROR_URL/epel|g" /etc/yum.repos.d/epel.repo
        sed -i "s|^baseurl=http://download.fedoraproject.org/pub/epel|baseurl=$MIRROR_URL/epel|g" /etc/yum.repos.d/epel.repo
    fi
}

configure_alpine() {
    ALPINE_VERSION=$(cat /etc/alpine-release | cut -d'.' -f1,2)
    tee /etc/apk/repositories > /dev/null <<EOF
$MIRROR_URL/alpine/v$ALPINE_VERSION/main
$MIRROR_URL/alpine/v$ALPINE_VERSION/community
EOF
}

configure_arch() {
    sed -i "1iServer = $MIRROR_URL/archlinux/\$repo/os/\$arch" /etc/pacman.d/mirrorlist
}

configure_manjaro() {
    tee /etc/pacman.d/mirrorlist > /dev/null <<EOF
Server = $MIRROR_URL/manjaro/stable/\$repo/\$arch
EOF
}

test_ubuntu_debian_raspbian() {
    if ! apt update 2>&1 | tee -a "$ERROR_LOG"; then
        return 1
    fi
    return 0
}

test_fedora_almalinux_rhel_centos() {
    if ! dnf clean all 2>&1 | tee -a "$ERROR_LOG"; then
        return 1
    fi
    if ! dnf makecache 2>&1 | tee -a "$ERROR_LOG"; then
        return 1
    fi
    return 0
}

test_alpine() {
    if ! apk update 2>&1 | tee -a "$ERROR_LOG"; then
        return 1
    fi
    return 0
}

test_arch_manjaro() {
    if ! pacman -Sy 2>&1 | tee -a "$ERROR_LOG"; then
        return 1
    fi
    return 0
}

configure_repositories() {
    case "$OS_NAME" in
        ubuntu)
            configure_ubuntu
            ;;
        debian)
            configure_debian
            ;;
        raspbian)
            configure_raspbian
            ;;
        fedora)
            configure_fedora
            ;;
        almalinux)
            configure_almalinux
            ;;
        rhel|centos)
            configure_rhel_centos
            ;;
        alpine)
            configure_alpine
            ;;
        arch)
            configure_arch
            ;;
        manjaro)
            configure_manjaro
            ;;
    esac
}

backup_repositories() {
    case "$OS_NAME" in
        ubuntu|debian|raspbian)
            backup_ubuntu_debian
            ;;
        fedora)
            backup_fedora
            ;;
        almalinux)
            backup_almalinux
            ;;
        rhel|centos)
            backup_rhel_centos
            ;;
        alpine)
            backup_alpine
            ;;
        arch|manjaro)
            backup_arch_manjaro
            ;;
    esac
}

test_repositories() {
    case "$OS_NAME" in
        ubuntu|debian|raspbian)
            test_ubuntu_debian_raspbian
            ;;
        fedora|almalinux|rhel|centos)
            test_fedora_almalinux_rhel_centos
            ;;
        alpine)
            test_alpine
            ;;
        arch|manjaro)
            test_arch_manjaro
            ;;
    esac
}

main() {
    check_sudo
    detect_os
    is_supported_os
    create_backup_dir
    
    echo "Detected OS: $OS_NAME"
    echo "Creating backup..."
    backup_repositories
    
    echo "Configuring mirror repositories..."
    configure_repositories
    
    echo "Testing repository configuration..."
    if ! test_repositories; then
        echo "Repository test failed. Restoring backup..."
        restore_latest_backup
        error_exit "Failed to configure mirror repositories. Configuration has been restored."
    fi
    
    echo "Mirror repositories configured successfully!"
    echo "Backup saved in: $BACKUP_DIR"
}

main
