# pi-dean-dev (Ansible)

Locked-down Raspberry Pi dev workstation for a teen:

- No sudo for teen user
- `dialout`/`plugdev` access for Arduino/ESP32 flashing
- UFW inbound deny + LAN-only SSH for admin
- DNS locked to filtering resolver (Pi-hole/AdGuard/router)
- Arduino CLI + PlatformIO + ESP-IDF + VS Code

## Run

1. Edit `inventory/hosts.yml` + `inventory/group_vars/pi.yml`
2. `make check && make bootstrap && make apply`
