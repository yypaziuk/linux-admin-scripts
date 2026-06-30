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
| `zabbix-gen-csr.sh` | Generate a 2048-bit RSA private key and CSR for a Zabbix server TLS certificate |

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
| `grafana-update.sh` | Update Grafana OSS to the latest release by downloading the .deb from dl.grafana.com |
| `check-services.sh` | Check the active status of a configurable list of systemd services |
| `zabbix-precheck.sh` | Pre-upgrade checks: Ubuntu/Zabbix/MySQL versions, disk space, repo reachability |
| `zabbix-export-hosts.py` | Export Zabbix hosts, IPs, and tags to Excel via the Zabbix API (env-var credentials) |
| `zabbix-dell-md-runner.sh` | Dell MD Storage: run SMcli to collect storageArray data (feeds get/discovery scripts) |
| `zabbix-dell-md-stat-runner.sh` | Dell MD Storage: run SMcli to collect performance stats (feeds stat-get script) |
| `zabbix-dell-md-stat-get.sh` | Dell MD Storage: return virtual/physical disk and controller performance XML to Zabbix |
| `zabbix-dell-md-discovery.sh` | Dell MD Storage: Zabbix LLD discovery for dp/dg/vd/pd/sfp/battery/fan/psu/controller/… |
| `zabbix-dell-md-get.sh` | Dell MD Storage: return full status and capacity XML (pools, groups, disks, sensors, …) |

> Zabbix scripts work together: `collect` runs the test and saves to cache, `read` returns cached data to Zabbix on demand (avoids timeout). Configure `HOST_LIST` path and iperf3 target IPs.

#### maintenance/

| Script | Description |
|--------|-------------|
| `nextcloud-update.sh` | Enable maintenance mode, update all apps and system packages, run built-in updater |
| `nextcloud-post-upgrade.sh` | Post-upgrade DB repair: missing indices, bigint conversion, mimetype update, service restart |
| `mysql-fix-row-format.sh` | Convert all tables in a MySQL/MariaDB database to ROW_FORMAT=DYNAMIC |
| `zabbix-proxy-update.sh` | Upgrade Zabbix Proxy (MySQL) to a new major version: backup, replace repo, apply DB schema |
| `zabbix-server-update.sh` | Upgrade Zabbix Server + PHP 7.4→8.0: backup, replace repo, upgrade packages, apply schema |

### Requirements

- Bash 4.0+
- Debian / Ubuntu (most scripts)
- Root access
- `iperf3` — for monitoring scripts
- `fail2ban` — for fail2ban scripts
- `curl` — for `grafana-update.sh`, `zabbix-precheck.sh`
- `mysql-client` — for `mysql-fix-row-format.sh`, `zabbix-proxy-update.sh`, `zabbix-server-update.sh`
- `openssl` — for `zabbix-gen-csr.sh`
- `python3`, `requests`, `pandas`, `openpyxl` — for `zabbix-export-hosts.py`
- Dell MD Storage Manager (SMcli) — for `zabbix-dell-md-*.sh` scripts

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
| `zabbix-gen-csr.sh` | Генерація RSA-ключа і CSR для TLS-сертифіката Zabbix-сервера |

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
| `grafana-update.sh` | Оновлення Grafana OSS до останньої версії через завантаження .deb з dl.grafana.com |
| `check-services.sh` | Перевірка активності списку systemd-сервісів |
| `zabbix-precheck.sh` | Перевірки перед оновленням: версії Ubuntu/Zabbix/MySQL, місце на диску, репозиторій |
| `zabbix-export-hosts.py` | Експорт хостів Zabbix, IP і тегів в Excel через Zabbix API |
| `zabbix-dell-md-runner.sh` | Dell MD Storage: запуск SMcli для збору storageArray (підготовка для get/discovery) |
| `zabbix-dell-md-stat-runner.sh` | Dell MD Storage: запуск SMcli для збору performance stats |
| `zabbix-dell-md-stat-get.sh` | Dell MD Storage: повернення XML продуктивності дисків/контролерів для Zabbix |
| `zabbix-dell-md-discovery.sh` | Dell MD Storage: Zabbix LLD discovery (dp/dg/vd/pd/sfp/battery/fan/psu/controller/…) |
| `zabbix-dell-md-get.sh` | Dell MD Storage: повний XML стану і ємності (пули, групи, диски, сенсори, …) |

#### maintenance/

| Скрипт | Призначення |
|--------|-------------|
| `nextcloud-update.sh` | Оновлення Nextcloud: maintenance mode, оновлення додатків і системи, запуск updater |
| `nextcloud-post-upgrade.sh` | Обслуговування після апгрейду: індекси БД, bigint, mimetypes, перезапуск сервісів |
| `mysql-fix-row-format.sh` | Конвертація всіх таблиць MySQL/MariaDB у ROW_FORMAT=DYNAMIC |
| `zabbix-proxy-update.sh` | Апгрейд Zabbix Proxy (MySQL): бекап, новий репо, оновлення пакету, схема БД |
| `zabbix-server-update.sh` | Апгрейд Zabbix Server + PHP 7.4→8.0: бекап, репо, пакети, схема БД |

### Вимоги

- Bash 4.0+
- Debian / Ubuntu (більшість скриптів)
- Root-доступ
- `iperf3` — для скриптів monitoring/
- `fail2ban` — для скриптів fail2ban
- `curl` — для `grafana-update.sh`, `zabbix-precheck.sh`
- `mysql-client` — для `mysql-fix-row-format.sh`, `zabbix-proxy-update.sh`, `zabbix-server-update.sh`
- `openssl` — для `zabbix-gen-csr.sh`
- `python3`, `requests`, `pandas`, `openpyxl` — для `zabbix-export-hosts.py`
- Dell MD Storage Manager (SMcli) — для скриптів `zabbix-dell-md-*.sh`
