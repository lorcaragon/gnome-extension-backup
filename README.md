# GNOME Extension Backup

A simple Bash-based utility to **back up**, **restore**, and **clean up** GNOME Shell extensions and their configuration settings.

---

## 🚀 Features

- Backup installed GNOME Shell extensions
- Export/import extension settings via `dconf`
- Clean up orphaned settings for uninstalled extensions

---

## 🛠️ Installation

```bash
1. Clone the repository:
   git clone https://github.com/lorcaragon/gnome-extension-backup.git

2. Navigate to the project directory:
   cd gnome-extension-backup

3. Make the script executable:
   chmod +x backup.sh
```

## 📂 Usage

```bash
./backup.sh backup [backup_dir]      # Create a backup (default: current dir)
./backup.sh restore <backup_dir>     # Restore from a backup
./backup.sh delete                   # Delete all installed extensions and their configs
./backup.sh prune                    # Clean up configs for uninstalled extensions
./backup.sh help                     # Show help
```

---

