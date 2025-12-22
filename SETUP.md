# SETUP.md — Raspberry Pi Teen Dev Box (Locked-Down) Setup Guide

This guide assumes you’re setting up a **Raspberry Pi 5** as a
**teen-friendly development machine** with **reasonable guardrails**
(not “NSA-proof”, just “hard to casually wreck”), using **Ansible** as
the source of truth.

---

## ✅ What you’ll end up with

- A **non-admin teen user** for daily work
- **SSH enabled** (for you), with **keys-only auth**
- Automatic **security updates**
- A **safe dev toolchain** (Git, Python, Node, optional Docker)
- Optional **microcontroller tooling** (Arduino CLI / PlatformIO / ESP32)
- Basic **guardrails**:
  - firewall on
  - no password SSH
  - reduced “oops I bricked it” risk
  - optional web/DNS filtering hooks

---

## 0) Assumptions + Naming

- Pi hostname: `pi-dean-dev`
- Admin user (for you): `admin`
- Teen user: `dev`
- You will manage the system from another machine via SSH.

> If you prefer **one user only** (no separate admin), you _can_, but it
> increases risk. Two users is cleaner.

---

## 1) Flash OS + Enable SSH (first boot)

### Recommended OS

- **Raspberry Pi OS Desktop (64-bit)**.

### In Raspberry Pi Imager (advanced settings)

- Set hostname: `pi-dean-dev`
- Enable SSH: **ON**
  - Auth: **password initially** (we’ll switch to keys-only later)
- Configure Wi-Fi (if needed)
- Set locale/timezone
- Create initial user: `admin` (your admin account)

### ⚠️ Note on Raspberry Pi OS Desktop

When using **Raspberry Pi OS Desktop**, the first‑boot setup wizard may
**ignore or override**
some Raspberry Pi Imager “Advanced Settings”, including:

- initial username/password
- SSH enablement
- auto‑login configuration

This behavior is inconsistent and is a known quirk of the Desktop image.

**Mitigations:**

- If using Desktop, be prepared to:
  - manually enable SSH after first boot
  - confirm the `admin` user exists and can SSH

Boot the Pi.

---

## 2) First boot: update + basics

### Enable mDNS (.local hostname resolution)

Raspberry Pi OS does **not always enable mDNS by default**, which is required for
`hostname.local` SSH access.

To enable it, login to `admin` on the Pi either via `ssh admin@<ip>` or using
display, keyboard and mouse:

```bash
sudo apt update
sudo apt install -y avahi-daemon
sudo systemctl enable --now avahi-daemon
sudo systemctl enable --now ssh

# Set hostname to `pi-dean-dev`
sudo nano /etc/hostname
sudo hostnamectl hostname pi-dean-dev
sudo reboot
```

SSH in:

```bash
ssh admin@pi-dean-dev.local

# Update
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

After reboot, re-SSH.

---

## 3) Prep SSH keys (keys-only is the goal)

On your control machine:

```bash
ssh-keygen -t ed25519 -C "pi-dean-dev-admin"
ssh-copy-id admin@pi-dean-dev.local
```

Verify:

```bash
ssh admin@pi-dean-dev.local
```

---

## 4) Install Ansible on your control machine

On Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y ansible
```

Confirm:

```bash
ansible --version
```

---

## 5) Clone the repo + configure inventory

```bash
git clone <YOUR_REPO_URL> pi-dean-dev
cd pi-dean-dev
```

Update `inventory/group_vars/pi.yml` with correct values.

---

## 6) Run the playbook

Dry run first:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check
```

Then apply:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

---

## 7) Post-install verification checklist

### Accounts + privilege boundaries

```bash
ssh dev@pi-dean-dev.local
sudo -n true
```

Teen sudo should fail.

### Firewall

```bash
sudo ufw status verbose
```

### Updates

```bash
systemctl status unattended-upgrades
```

### Dev tools

```bash
git --version
python3 --version
node --version || true
```

---

## 8) Microcontroller setup (Arduino + ESP32)

### Groups

```bash
groups dev
```

Expected groups: `dialout`, `plugdev`.

### Arduino CLI

```bash
arduino-cli version
arduino-cli core update-index
arduino-cli core install esp32:esp32
```

### PlatformIO

```bash
pio --version
```

---

## 9) Recovery strategies

- **Disk image backups** (rpi-clone or SD imaging)
- **Golden image reflash**
- **Read-only root + writable home** (advanced)

---

## 10) Common gotchas

- Cheap USB power causes serial disconnects.
- Serial permissions are the #1 Arduino issue.
- Docker group == root access.

---

## 11) Useful commands

```bash
ansible-playbook -i inventory/hosts.ini site.yml --tags "ssh,hardening"
ansible-playbook -i inventory/hosts.ini site.yml --diff
```

---

## ✅ Done

The Pi is now safe, boring to recover, and fun to build on.
