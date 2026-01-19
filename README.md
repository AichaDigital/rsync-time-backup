## Rsync time backup

[![Tests](https://github.com/AichaDigital/rsync-time-backup/actions/workflows/tests.yml/badge.svg)](https://github.com/AichaDigital/rsync-time-backup/actions/workflows/tests.yml)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen)](https://github.com/AichaDigital/rsync-time-backup/actions/workflows/tests.yml)
[![Bash](https://img.shields.io/badge/bash-3.2%2B-blue)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**THAT IS A FORK OF [ORIGINAL PACKAGE](https://github.com/laurent22/rsync-time-backup)**

**It works for me and is here for you to use if you want, but you are solely responsible for testing, verifying, and using it.**

A lot of thanks for code.

# CHANGES
- Expiring strategies

## Expiring strategies
Option `-m|--max_backup N`

Specify the maximum number of backups (default: 10). After this number of backups, script prune backups

## Rsync flags configuration

### Default rsync flags

The script uses these default rsync flags for security and efficiency:

```
"-D --numeric-ids --links --hard-links --one-file-system --itemize-changes --times --recursive --perms --owner --group --stats --human-readable"
```

### When to use `--rsync-append-flags` vs `--rsync-set-flags`

**Use `--rsync-append-flags`** when you want to **add** additional flags to the default ones:

```bash
# Example: Add --no-perms --no-owner --no-group to the default flags
rsync_tmbackup.sh --rsync-append-flags "--no-perms --no-owner --no-group" /home /mnt/backup
```

**Use `--rsync-set-flags`** when you need to **replace** the default flags completely. This is necessary when you need to remove specific default flags like `--one-file-system`:

```bash
# Example: Remove --one-file-system to backup across multiple file systems
rsync_tmbackup.sh --rsync-set-flags "-D --numeric-ids --links --hard-links --itemize-changes --times --recursive --stats --human-readable --no-perms --no-group --no-owner" /home /mnt/backup
```

### Use case: Backup across multiple file systems

When backing up from a server with multiple file systems, the default `--one-file-system` flag prevents rsync from crossing file system boundaries. To backup across multiple file systems, you must use `--rsync-set-flags` to replace the default flags and exclude `--one-file-system`:

```bash
/path/rsync-time-backup/rsync_tmbackup.sh -p 2244 -m 60 --rsync-set-flags "-D --numeric-ids --links --hard-links --itemize-changes --times --recursive --stats --human-readable --no-perms --no-group --no-owner" --strategy "1:1 7:7 30:30" root@dfdqn.backup.tld:/ /path/local/rsync /path/local/excludes.txt
```

### Use case: Non-root user backup

For non-root user backups, you typically want to add `--no-perms --no-owner --no-group` to avoid permission issues, but keep all other default flags:

```bash
rsync_tmbackup.sh --rsync-append-flags "--no-perms --no-owner --no-group" /home /mnt/backup
```

> **Note:** My full system backup strategy does not attempt a 100% restore. When I need that, I have another backup strategy where I generate metadata with the data of all the directories and files in the backup along with their original permissions and owners.

## ORIGINAL PACKAGE
This script offers Time Machine-style backup using rsync. It creates incremental backups of files and directories to the destination of your choice. The backups are structured in a way that makes it easy to recover any file at any point in time.

It works on Linux, macOS and Windows (via WSL or Cygwin). The main advantage over Time Machine is the flexibility as it can backup from/to any filesystem and works on any platform. You can also backup, for example, to a Truecrypt drive without any problem.

On macOS, it has a few disadvantages compared to Time Machine - in particular it does not auto-start when the backup drive is plugged (though it can be achieved using a launch agent), it requires some knowledge of the command line, and no specific GUI is provided to restore files. Instead files can be restored by using any file explorer, including Finder, or the command line.

## Installation

### This Fork (with expiration enhancements)
	git clone https://github.com/AichaDigital/rsync-time-backup

### Original Version
	git clone https://github.com/laurent22/rsync-time-backup

## Usage

	Usage: rsync_tmbackup.sh [OPTION]... <[USER@HOST:]SOURCE> <[USER@HOST:]DESTINATION> [exclude-pattern-file]

	Options
	 -p, --port             SSH port.
	 -h, --help             Display this help message.
	 -i, --id_rsa           Specify the private ssh key to use.
	 --rsync-get-flags      Display the default rsync flags that are used for backup. If using remote
	                        drive over SSH, --compress will be added.
	 --rsync-set-flags      Set the rsync flags that are going to be used for backup.
	 --rsync-append-flags   Append the rsync flags that are going to be used for backup.
	 --log-dir              Set the log file directory. If this flag is set, generated files will
	                        not be managed by the script - in particular they will not be
	                        automatically deleted.
	                        Default: /home/backuper/.rsync_tmbackup
	 --log-to-destination   Store logs in the destination folder under .rsync_tmbackup/
	                        This is useful when you want to keep logs with the backups.
	 --strategy             Set the expiration strategy. Default: "1:1 30:7 365:30" means after one
	                        day, keep one backup per day. After 30 days, keep one backup every 7 days.
	                        After 365 days keep one backup every 30 days.
	 --no-auto-expire       Disable automatically deleting backups when out of space. Instead an error
	                        is logged, and the backup is aborted.
	 -m, --max_backups N    Specify the maximum number of backups (default: 10).
	                        After this number of backups, the script prunes older backups.
	 --sudo                 Run rsync with sudo. Useful for backing up system files
	                        that require root permissions.

## Features

* Each backup is on its own folder named after the current timestamp. Files can be copied and restored directly, without any intermediate tool.

* Backup to/from remote destinations over SSH.

* Files that haven't changed from one backup to the next are hard-linked to the previous backup so take very little extra space.

* Safety check - the backup will only happen if the destination has explicitly been marked as a backup destination.

* Resume feature - if a backup has failed or was interrupted, the tool will resume from there on the next backup.

* Exclude file - support for pattern-based exclusion via the `--exclude-from` rsync parameter.

* Automatically purge old backups - within 24 hours, all backups are kept. Within one month, the most recent backup for each day is kept. For all previous backups, the most recent of each month is kept.

* "latest" symlink that points to the latest successful backup.

## Examples

* Simple backup of a directory:

		rsync_tmbackup.sh /path/to/source /path/to/destination

* Backup with automatic rotation (keep only last 20 backups):

		rsync_tmbackup.sh -m 20 /path/to/source /path/to/destination

* Backup with custom expiration strategy (keep daily for 7 days, then weekly for 30 days):

		rsync_tmbackup.sh --strategy "1:1 7:7 30:30" /path/to/source /path/to/destination

* Backup the home folder to backup_drive

		rsync_tmbackup.sh /home /mnt/backup_drive

* Backup with exclusion list:

		rsync_tmbackup.sh /home /mnt/backup_drive excluded_patterns.txt

* Backup to remote drive over SSH, on port 2222:

		rsync_tmbackup.sh -p 2222 /home user@example.com:/mnt/backup_drive

* Backup to remote drive over SSH using a specific private key:

		rsync_tmbackup.sh -i ~/.ssh/my_private_key /home user@example.com:/mnt/backup_drive

* Backup from remote drive over SSH:

		rsync_tmbackup.sh user@example.com:/home /mnt/backup_drive

* To mimic Time Machine's behavior, a cron script can be setup to backup at regular interval. For example, the following cron job checks if the drive "/mnt/backup" is currently connected and, if it is, starts the backup. It does this check every 1 hour.

		0 */1 * * * if grep -qs /mnt/backup /proc/mounts; then rsync_tmbackup.sh /home /mnt/backup; fi

## Backup expiration logic

Backup sets are automatically deleted following a simple expiration strategy defined with the `--strategy` flag. This strategy is a series of time intervals with each item being defined as `x:y`, which means "after x days, keep one backup every y days". The default strategy is `1:1 30:7 365:30`, which means:

- After **1** day, keep one backup every **1** day (**1:1**).
- After **30** days, keep one backup every **7** days (**30:7**).
- After **365** days, keep one backup every **30** days (**365:30**).

Before the first interval (i.e. by default within the first 24h) it is implied that all backup sets are kept. Additionally, if the backup destination directory is full, the oldest backups are deleted until enough space is available.

## Troubleshooting: Paths not being backed up (e.g., /home, /root, /backups_mysql)

If some paths you expect are missing from the backup, check the following common causes:

1) Separate filesystems and the default --one-file-system
- Symptom: Backing up from / (root) but /home is not included.
- Cause: By default, the script includes --one-file-system, which prevents rsync from crossing mount points. On many Linux servers, /home is a separate filesystem.
- Fix: Use --rsync-set-flags to REPLACE the defaults and remove --one-file-system. Example:

```
./rsync_tmbackup.sh --rsync-set-flags "-D --numeric-ids --links --hard-links --itemize-changes --times --recursive --stats --human-readable" \
  user@host:/ /backup/dest /path/to/exclude.txt
```

2) Permissions when not running as root on the SOURCE
- Symptom: /root (and sometimes /home/*) are missing or partially copied.
- Cause: If the backup runs as a non-root user on the source side, it cannot read /root and some directories. Over SSH, this depends on the remote user (user@host:...).
- Fix options:
  - Run the backup as root on the source (e.g., root@host:/ ...).
  - Or accept that some paths cannot be read; avoid including /root.
  - For non-root backups, it’s often convenient to add: --rsync-append-flags "--no-perms --no-owner --no-group".

3) The path simply doesn’t exist on the source
- Symptom: You include + /backups_mysql/*** but nothing gets copied.
- Cause: The directory /backups_mysql doesn’t exist or is mounted elsewhere.
- Fix: Verify on the SOURCE server: test -d /backups_mysql

4) Filter rules order
- Symptom: Specific subpaths under excluded parents aren’t copied.
- Cause: A broad exclusion (e.g., - /usr/***) appears before your specific includes.
- Fix: Ensure parent directories and specific includes appear BEFORE broad excludes. See examples below.

The script now prints warnings for (1) and (2) at the start of each run when applicable.

## Exclusion file

An optional exclude file can be provided as a third parameter. It should be compatible with the `--exclude-from` parameter of rsync. See [this tutorial](https://web.archive.org/web/20230126121643/https://sites.google.com/site/rsync2u/home/rsync-tutorial/the-exclude-from-option) for more information.

### Include/Exclude filter files (automatic detection)

Usage stays the same; pass the file as the third argument:

```bash
./rsync_tmbackup.sh /source/path /destination/path /path/to/excludes.txt
```

### Practical Guide: How to write exclude.txt correctly

The exclude.txt file is critical. With rsync, the order of rules and the prior inclusion of parent directories make the difference between something being included in the backup or not.

Fundamental rules (rsync filter rules):
- Use `+` to INCLUDE and `-` to EXCLUDE.
- Order matters: rsync evaluates from top to bottom, and the first match wins.
- Include parent directories before children. If you exclude `/usr/***` and then try to include `/usr/share/zabbix/***`, rsync won't descend to `/usr/` and won't see your include. Solution: include `/usr/` and `/usr/share/` BEFORE excluding `/usr/***`.
- End with broad exclusions (catch-all) if you want to prevent surprises.

This script automatically detects if your file has lines starting with `+` or `-` and, in that case, uses `--filter 'merge <file>'`. If it doesn't detect `+`/`-`, it uses classic `--exclude-from`.

### Rule order: the golden rule

**The first matching rule wins.** Rsync evaluates rules top-to-bottom and stops at the first match. This means:

1. **Global exclusions FIRST** (patterns without leading `/` that should apply everywhere)
2. **Parent directory inclusions** (when you need to include paths under excluded parents)
3. **System/broad exclusions** (patterns with leading `/`)
4. **Data inclusions LAST** (your actual data directories)

### Excluding patterns everywhere (e.g., node_modules, .git)

To exclude a directory like `node_modules` from ALL locations in the backup, you must place the rule **BEFORE** any inclusion that uses `***`:

```
# WRONG - node_modules will be included because /home/*** matches first
+ /home/***
- node_modules/***

# CORRECT - node_modules is excluded before /home/*** is evaluated
- node_modules/***
+ /home/***
```

Key syntax points:

| Pattern | What it excludes |
|---------|------------------|
| `- /node_modules/***` | Only `/node_modules` at root level |
| `- node_modules/***` | `node_modules` at ANY level (no leading `/`) |
| `- **/node_modules/***` | Same as above, explicit syntax |

Complete example with global exclusions:

```
# ═══════════════════════════════════════════════════════════
# FIRST: Global exclusions (patterns that apply everywhere)
# ═══════════════════════════════════════════════════════════
- node_modules/***
- .git/***
- .cache/***
- __pycache__/***
- *.log
- .DS_Store

# ═══════════════════════════════════════════════════════════
# SECOND: System exclusions (with leading /)
# ═══════════════════════════════════════════════════════════
- /proc/***
- /sys/***
- /dev/***
- /tmp/***
- /run/***
- /mnt/***
- /media/***
- /snap/***

# ═══════════════════════════════════════════════════════════
# THIRD: Data inclusions
# ═══════════════════════════════════════════════════════════
+ /home/***
+ /etc/***
+ /root/***
+ /var/www/***
```

With this order, when rsync evaluates `/home/user/project/node_modules/`, it first matches `- node_modules/***` and excludes it before reaching `+ /home/***`.

Example 1: Include only `/usr/share/zabbix` when generally excluding `/usr`

```
+ /usr/
+ /usr/share/
+ /usr/share/zabbix/***
- /usr/***
```

Example 2: Include `/var/www` but exclude the rest of `/var`

```
+ /var/
+ /var/www/***
- /var/***
```

Example 3: Typical system template (home, etc, root and some specific paths) avoiding temporary mounts

```
# First specific inclusions and their parents
+ /usr/
+ /usr/share/
+ /usr/share/zabbix/***
+ /var/
+ /var/www/***

# Now broad system exclusions
- /usr/***
- /var/***
- /proc/***
- /sys/***
- /dev/***
- /tmp/***
- /run/***
- /mnt/***
- /media/***
- /cdrom/***
- /lost+found/***
- /snap/***
- /opt/***
- /srv/***
- /boot/***
- /bin/***
- /sbin/***
- /lib/***
- /lib64/***
- /lib32/***
- /libx32/***

# Data inclusions
+ /home/***
+ /etc/***
+ /root/***
+ /backups/***
```

Example 4: Variant without specific under-parent includes and using /backups_mysql

```
# First specific inclusions and their parents
# (none; add them if you need to include subpaths under excluded parents)

# Now broad system exclusions
- /usr/***
- /var/***
- /proc/***
- /sys/***
- /dev/***
- /tmp/***
- /run/***
- /mnt/***
- /media/***
- /cdrom/***
- /lost+found/***
- /snap/***
- /opt/***
- /srv/***
- /boot/***
- /bin/***
- /sbin/***
- /lib/***
- /lib64/***
- /lib32/***
- /libx32/***

# Data inclusions
+ /home/***
+ /etc/***
+ /root/***
+ /backups_mysql/***
```

How to test that your rules work (dry-run):
- With rsync directly (replace paths and host according to your case):

```bash
rsync -nrv --delete --numeric-ids --links --hard-links --one-file-system \
  --filter 'merge /path/to/exclude.txt' \
  user@host:/ /local/path/test
```

- With this script, adding test flags:

```bash
./rsync_tmbackup.sh --rsync-append-flags "-n -v" \
  user@host:/ /local/path/destination /path/to/exclude.txt
```

Notes and common errors:
- Don't mix a broad `- /usr/***` above your specific `+ /usr/...`. Inclusions must go FIRST.
- Make sure to include parents: `+ /usr/` and `+ /usr/share/` before `+ /usr/share/zabbix/***`.
- Avoid typos in patterns: for example, `+ /backups/***%` matches nothing; should be `+ /backups/***`.
- There are no syntax differences between Linux and macOS for these rules; what matters is that paths correspond to the source tree (if you backup `/`, paths start with `/`).

## Built-in lock

The script is designed so that only one backup operation can be active for a given directory. If a new backup operation is started while another is still active (i.e. it has not finished yet), the new one will be automaticalled interrupted. Thanks to this the use of `flock` to run the script is not necessary.

## Rsync options

To display the rsync options that are used for backup, run `./rsync_tmbackup.sh --rsync-get-flags`.

You can modify the rsync flags using two different approaches:

* **`--rsync-append-flags`**: Adds flags to the existing defaults (recommended for most cases)
* **`--rsync-set-flags`**: Completely replaces the default flags (use when you need to remove specific defaults)

For example, to exclude backing up permissions and groups while keeping all other defaults:

	rsync_tmbackup --rsync-append-flags "--no-perms --no-group" /src /dest

## No automatic backup expiration

An option to disable the default behavior to purge old backups when out of space. This option is set with the `--no-auto-expire` flag.


## How to restore

The script creates a backup in a regular directory so you can copy the files back to the original directory. You could do that with something like `rsync -aP /path/to/last/backup/ /path/to/restore/to/`. Consider using the `--dry-run` option to check what exactly is going to be copied. Use `--delete` if you also want to delete files that exist in the destination but not in the backup (extra care must be taken when using this option).

## Extensions

* [rtb-wrapper](https://github.com/thomas-mc-work/rtb-wrapper): Allows creating backup profiles in config files. Handles both backup and restore operations.
* [time-travel](https://github.com/joekerna/time-travel): Smooth integration into OSX Notification Center

## TODO

* Check source and destination file-system (`df -T /dest`). If one of them is FAT, use the --modify-window rsync parameter (see `man rsync`) with a value of 1 or 2
* Add `--whole-file` arguments on Windows? See http://superuser.com/a/905415/73619
* Minor changes (see TODO comments in the source).

## LICENSE

The MIT License (MIT)

Copyright (c) 2013-2018 Laurent Cozic

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
