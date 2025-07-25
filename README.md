## Rsync time backup

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

# ORIGINAL PACKAGE
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
	 --strategy             Set the expiration strategy. Default: "1:1 30:7 365:30" means after one
	                        day, keep one backup per day. After 30 days, keep one backup every 7 days.
	                        After 365 days keep one backup every 30 days.
	 --no-auto-expire       Disable automatically deleting backups when out of space. Instead an error
	                        is logged, and the backup is aborted.

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

## Exclusion file

An optional exclude file can be provided as a third parameter. It should be compatible with the `--exclude-from` parameter of rsync. See [this tutorial](https://web.archive.org/web/20230126121643/https://sites.google.com/site/rsync2u/home/rsync-tutorial/the-exclude-from-option) for more information.

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

