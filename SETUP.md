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

### Generate the admin SSH key first

On your control machine (Imager needs the public key in the next step):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/pi-dean-dev-admin -C "pi-dean-dev-admin"
```

### Recommended OS

- **Raspberry Pi OS Desktop (64-bit)**.

### In Raspberry Pi Imager (advanced settings)

- Set hostname: `pi-dean-dev`
- Enable SSH: **ON**
  - Auth: **public-key only** — paste the contents of
    `~/.ssh/pi-dean-dev-admin.pub`
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

## 3) SSH keys (keys-only is the goal)

Imager already deployed your public key (step 1), so key auth should
work from the first boot:

```bash
ssh -i ~/.ssh/pi-dean-dev-admin admin@pi-dean-dev.local
```

Point `ansible_ssh_private_key_file` in `inventory/hosts.yml` at
`~/.ssh/pi-dean-dev-admin`. Ansible **keeps enforcing** the matching
`.pub` in the admin user's `authorized_keys` on every run (see the
`admin_authorized_keys` var), so the key survives even if something
wipes it on the Pi — no `ssh-copy-id` needed.

**Fallback:** if the Desktop first-boot wizard ignored the Imager
settings (see the warning in step 1) and you only have password SSH,
install `sshpass` on the control machine and add `-k -K` to the first
`ansible-playbook` run — Ansible will deploy the key, and key auth
works from then on:

```bash
sudo apt install -y sshpass
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
ansible-galaxy collection install -r requirements.yml
```

Update `inventory/group_vars/pi.yml` with correct values.

---

## 6) Run the playbook

Bootstrap first, then dry run and apply the full playbook:

```bash
ansible-playbook playbooks/bootstrap.yml
ansible-playbook playbooks/site.yml --check
ansible-playbook playbooks/site.yml
```

> If key auth isn't working yet (Desktop wizard quirk), run the
> bootstrap with `-k -K` once — see the fallback in step 3.

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

## 9) Weekly drift control (optional)

The `drift_control` role installs a root cron job that re-applies
`playbooks/site.yml` locally every week. It assumes the repo lives at
`/opt/pi-dean-dev` **on the Pi**:

```bash
sudo git clone <YOUR_REPO_URL> /opt/pi-dean-dev
```

Keep that copy updated (`git -C /opt/pi-dean-dev pull`) or set
`drift_apply_weekly: false` in `inventory/group_vars/pi.yml`.
Apply output lands in `/var/log/pi-dean-dev-apply.log`; failures are
logged to syslog with tag `pi-dean-dev`.

---

## 10) Recovery strategies

- **Disk image backups** (rpi-clone or SD imaging)
- **Golden image reflash**
- **Read-only root + writable home** (advanced)

---

## 11) Common gotchas

- Cheap USB power causes serial disconnects.
- Serial permissions are the #1 Arduino issue.
- Docker group == root access.

---

## 12) Useful commands

```bash
ansible-playbook playbooks/lockdown.yml --diff
ansible-playbook playbooks/site.yml --diff --check
```

---

## Storage Layout (Final)

- Primary disk: NVMe
- Root filesystem: `/dev/nvme0n1p*`
- SD card: recovery / installer only
- Ansible enforces:
  - NVMe-only root
  - periodic TRIM
  - NVMe health checks
  - SD auto-mount suppression

## ✅ Done

The Pi is now safe, boring to recover, and fun to build on.
