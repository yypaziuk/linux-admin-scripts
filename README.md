# linux-admin-scripts

A collection of Bash scripts for Linux system administration and maintenance.

---

[English](#english) · [Українська](#ukrainian)

---

## English

### About

Reusable shell scripts for common Linux administration tasks, organized by category. Tested on Debian/Ubuntu unless noted otherwise.

### Usage

```bash
chmod +x script-name.sh
sudo ./script-name.sh
```

Most scripts require root. Scripts with configurable parameters have variables at the top — edit them before running.

### Scripts

#### firewall/

| Script | Description |
|--------|-------------|
| `ufw-basic.sh` | Basic UFW setup: deny all incoming, allow SSH, enable firewall |
| `ufw-ftps.sh` | UFW rules for an FTPS server (SSH + FTP control + passive port range) |

#### security/

| Script | Description |
|--------|-------------|
| `ssh-hardening.sh` | Disable password auth and root login, enforce key-only SSH access |
| `fail2ban-ssh.sh` | fail2ban jail for SSH: ban IPs after repeated failed login attempts |
| `fail2ban-vsftpd.sh` | fail2ban jail for vsftpd FTP server |

#### vpn/

| Script | Description |
|--------|-------------|
| `wg-watchdog.sh` | WireGuard watchdog: auto-restart `wg0` if VPN peer becomes unreachable |

#### storage/

| Script | Description |
|--------|-------------|
| `ftp-rotate.sh` | Delete FTP files older than N days, remove empty directories — run via cron |
| `vsftpd-add-user.sh` | Add a virtual user to vsftpd with an auto-generated password |

#### monitoring/

| Script | Description |
|--------|-------------|
| `zabbix-speedtest-discovery.sh` | Zabbix LLD discovery: outputs JSON list of iperf3 hosts from host_list |
| `zabbix-speedtest-collect.sh` | Collects ping/download/upload via iperf3, writes XML result to /tmp |
| `zabbix-speedtest-read.sh` | Returns cached speedtest XML to Zabbix; safe to call while collect is running |
| `speedtest-lan.sh` | Standalone LAN speedtest (iperf3): configurable targets, CLI flags, Zabbix LLD support |

> Zabbix scripts work together: `collect` runs the test and saves to cache, `read` returns cached data to Zabbix on demand (avoids timeout). Configure `HOST_LIST` path and iperf3 target IPs.

### Requirements

- Bash 4.0+
- Debian / Ubuntu (most scripts)
- Root access
- `iperf3` — for monitoring scripts
- `fail2ban` — for fail2ban scripts

---

## Ukrainian

### Про проєкт

Збірник bash-скриптів для адміністрування та обслуговування Linux-систем, організований за категоріями. Перевірено на Debian/Ubuntu якщо не зазначено інше.

### Використання

```bash
chmod +x script-name.sh
sudo ./script-name.sh
```

Більшість скриптів потребують root. Скрипти з параметрами мають змінні на початку файлу — відредагуйте їх перед запуском.

### Скрипти

#### firewall/

| Скрипт | Призначення |
|--------|-------------|
| `ufw-basic.sh` | Базовий UFW: заборонити весь вхідний трафік, дозволити SSH, увімкнути |
| `ufw-ftps.sh` | UFW для FTPS-сервера (SSH + FTP контрольний канал + пасивний діапазон портів) |

#### security/

| Скрипт | Призначення |
|--------|-------------|
| `ssh-hardening.sh` | Вимкнути авторизацію за паролем і вхід root, тільки ключ |
| `fail2ban-ssh.sh` | fail2ban для SSH: бан IP після невдалих спроб входу |
| `fail2ban-vsftpd.sh` | fail2ban для FTP-сервера vsftpd |

#### vpn/

| Скрипт | Призначення |
|--------|-------------|
| `wg-watchdog.sh` | Watchdog WireGuard: автоматичний перезапуск `wg0` якщо VPN недоступний |

#### storage/

| Скрипт | Призначення |
|--------|-------------|
| `ftp-rotate.sh` | Видалення FTP-файлів старших за N днів і порожніх директорій — запуск через cron |
| `vsftpd-add-user.sh` | Додавання virtual-користувача у vsftpd з автогенерацією пароля |

#### monitoring/

| Скрипт | Призначення |
|--------|-------------|
| `zabbix-speedtest-discovery.sh` | Zabbix LLD discovery: JSON-список iperf3-хостів із файлу host_list |
| `zabbix-speedtest-collect.sh` | Збирає ping/download/upload через iperf3, зберігає XML у /tmp |
| `zabbix-speedtest-read.sh` | Повертає кешований результат Zabbix; безпечний під час роботи collect |
| `speedtest-lan.sh` | Standalone LAN speedtest (iperf3): CLI-прапорці, підтримка Zabbix LLD |

### Вимоги

- Bash 4.0+
- Debian / Ubuntu (більшість скриптів)
- Root-доступ
- `iperf3` — для скриптів monitoring/
- `fail2ban` — для скриптів fail2ban
