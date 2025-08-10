# Ubuntu Docker Disaster Recovery Backup Script

A comprehensive backup solution for Docker-based home lab environments with intelligent retention policy. This script creates timestamped backups of your Docker configurations, scripts, and system files whilst automatically managing storage through a graduated retention system.

## Features

- **Timestamped backups** - Each backup stored in `YYYYMMDD-HHMMSS` directories
- **Intelligent retention** - Keeps more recent backups, fewer older ones
- **Email notifications** - Detailed reports of what was backed up and cleaned up
- **Secure filtering** - Only backs up configuration files, excludes data/logs/cache
- **Cloud storage** - Uses rclone for reliable cloud backup
- **Recovery ready** - Includes system package lists and network configurations

## Retention Policy

The script automatically manages backup retention to prevent unlimited storage growth:

- **Last 3 backups** - Always retained regardless of age
- **Monthly backups** - One backup per month for backups 30+ days old
- **Quarterly backups** - One backup per quarter for backups 90+ days old
- **Yearly backups** - One backup per year for backups 365+ days old

**Example:** Daily backups over 6 months results in ~9 retained backups instead of 180+

## What Gets Backed Up

1. **Docker Configurations**
   - `docker-compose.yml` files
   - Environment files (`.env`)
   - Shell scripts (`.sh`)
   - Configuration files (`.conf`, `.json`, `.toml`, `.ini`)
   - Documentation (`.md`, `.txt`)
   - Dockerfiles

2. **Scripts Directory**
   - All custom scripts and automation

3. **System Configurations**
   - Email configuration (`msmtprc`)
   - Crontab entries
   - Docker network configurations
   - System package lists

4. **User Configurations**
   - SSH keys
   - Shell configuration files (`.bashrc`, `.profile`)

## Prerequisites

### 1. Rclone Configuration
```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure your cloud storage (Google Drive, Dropbox, etc.)
rclone config
2. Email Notifications (msmtp)
bash# Install msmtp
sudo apt install msmtp msmtp-mta

# Configure /etc/msmtprc for your email provider
sudo vi /etc/msmtprc
3. Directory Structure
Ensure your Docker configs are organised like:
/home/username/
├── git/home-configs/docker/
│   ├── service1/
│   │   ├── docker-compose.yml
│   │   └── configs/
│   └── service2/
│       └── docker-compose.yml
└── scripts/
    ├── backup-script.sh
    └── other-scripts.sh
Installation

Download the script
bashwget https://raw.githubusercontent.com/yourusername/docker-backup-script/main/disaster-backup.sh
chmod +x disaster-backup.sh

Configure the script
Edit the configuration section at the top:
bashvi disaster-backup.sh
Update these variables:
bashBACKUP_REMOTE="your-rclone-remote:Backup/Disaster-Recovery"
NOTIFICATION_EMAIL="your-email+disaster@gmail.com"
FROM_EMAIL="alerts.yourdomain@gmail.com"
USERNAME="your-username"

Test the configuration
bash# Test rclone connectivity
rclone lsd your-rclone-remote:

# Test email
echo "Test" | msmtp your-email@gmail.com

Run a test backup
bash./disaster-backup.sh

Schedule with cron
bashcrontab -e

# Add line for twice-weekly backups at 2 AM
0 2 * * 0,3 /path/to/disaster-backup.sh


Customisation
Backup Frequency
Adjust the cron schedule based on your needs:

Daily: 0 2 * * *
Twice weekly: 0 2 * * 0,3 (Sunday & Wednesday)
Weekly: 0 2 * * 0 (Sunday only)

Retention Policy
Modify the retention logic in the script:
bashif [ $KEEP_COUNT -lt 3 ]; then          # Keep last N backups
elif [ $age_days -ge 365 ]; then        # Yearly threshold
elif [ $age_days -ge 90 ]; then         # Quarterly threshold  
elif [ $age_days -ge 30 ]; then         # Monthly threshold
File Filters
Add or remove file types in the Docker backup section:
bash--filter="+ *.your-extension" \
--filter="- */your-exclude-dir/**" \
Security Considerations

Script runs as root - Required for accessing system configs and rclone
Email contains paths - Ensure your email account is secure
SSH keys backed up - Consider if you want these in cloud storage
Cloud storage encryption - Enable encryption in your rclone remote if required

Excluding Sensitive Data
The script automatically excludes:

*/data/** directories (database files, application data)
*/logs/** directories
*/cache/** directories

Add additional exclusions as needed.
Troubleshooting
Common Issues
Rclone authentication errors:
bash# Re-authenticate your remote
rclone config reconnect your-remote:
Email delivery failures:
bash# Test msmtp configuration
echo "Test message" | msmtp --debug your-email@gmail.com
Permission errors:
bash# Ensure script is executable and paths are correct
chmod +x disaster-backup.sh
ls -la /home/username/git/home-configs/docker/
Dry Run Testing
To test retention without actually deleting:
bash# Comment out the deletion line in the script:
# sudo /usr/bin/rclone purge "$BACKUP_BASE/$dir_clean" --verbose

# Run the script and check the email report
./disaster-backup.sh
Recovery Usage
Listing Available Backups
bashrclone lsd your-remote:Backup/Disaster-Recovery/
Restoring Files
bash# Download specific backup
rclone copy your-remote:Backup/Disaster-Recovery/20250810-020001/ ./restored-backup/

# Restore to original locations  
sudo cp -r ./restored-backup/docker/* /home/username/git/home-configs/docker/
cp -r ./restored-backup/scripts/* /home/username/scripts/
System Rebuild
bash# Restore package list
sudo dpkg --set-selections < restored-backup/system-configs/installed-packages.txt
sudo apt-get dselect-upgrade

# Recreate Docker networks
docker network create -d macvlan --subnet=192.168.3.0/24 --gateway=192.168.3.1 -o parent=eth0 dock_net
Contributing
Contributions welcome! Please:

Fork the repository
Create a feature branch
Test your changes thoroughly
Submit a pull request

License
MIT License - Feel free to modify and distribute
Support

Issues: Please open a GitHub issue
Discussions: Use GitHub Discussions for questions
Security: Email security issues privately to maintainer
