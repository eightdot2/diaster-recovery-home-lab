#!/bin/bash
#
# Docker Disaster Recovery Backup Script with Retention
# 
# This script creates timestamped backups of Docker configurations,
# scripts, and system configs with automatic retention cleanup.
#
# BEFORE USING:
# 1. Configure rclone with your cloud storage provider
# 2. Set up msmtp for email notifications
# 3. Update all paths and email addresses below
# 4. Test retention policy with dry-run first
#

# =============================================================================
# CONFIGURATION - UPDATE THESE VALUES FOR YOUR ENVIRONMENT
# =============================================================================
BACKUP_REMOTE="your-google-drive:Backup/Disaster-Recovery"
NOTIFICATION_EMAIL="your-email+disaster@gmail.com"
FROM_EMAIL="alerts.yourdomain@gmail.com"
USERNAME="username"
DOCKER_CONFIGS_PATH="/home/$USERNAME/git/home-configs/docker"
SCRIPTS_PATH="/home/$USERNAME/scripts"
# =============================================================================

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_ROOT="$BACKUP_REMOTE/$TIMESTAMP"

{
   echo "To: $NOTIFICATION_EMAIL"
   echo "From: $FROM_EMAIL"
   echo "Subject: 🔧 Disaster Recovery Backup - $(hostname)"
   echo
   echo "Creating timestamped backup: $TIMESTAMP"
   echo "Date: $(date)"
   echo

   # 1. All Docker compose files and related configs
   echo "=== Docker Configurations ==="
   sudo /usr/bin/rclone copy "$DOCKER_CONFIGS_PATH/" "$BACKUP_ROOT/docker/" \
       --verbose \
       --filter="+ *.yml" \
       --filter="+ *.yaml" \
       --filter="+ *.sh" \
       --filter="+ *.env" \
       --filter="+ *.conf" \
       --filter="+ *.json" \
       --filter="+ *.toml" \
       --filter="+ *.ini" \
       --filter="+ Dockerfile*" \
       --filter="+ *.md" \
       --filter="+ *.txt" \
       --filter="- */data/**" \
       --filter="- */logs/**" \
       --filter="- */cache/**" \
       --filter="- *"

   # 2. All scripts directory
   echo "=== Scripts Directory ==="
   sudo /usr/bin/rclone copy "$SCRIPTS_PATH/" "$BACKUP_ROOT/scripts/" --verbose

   # 3. System configs that matter for Docker
   echo "=== System Configs ==="
   sudo /usr/bin/rclone copy /etc/msmtprc "$BACKUP_ROOT/system-configs/" --verbose

   # 4. Cron jobs (as text file)
   echo "=== Cron Jobs ==="
   sudo -u "$USERNAME" crontab -l > /tmp/crontab-backup.txt
   sudo /usr/bin/rclone copy /tmp/crontab-backup.txt "$BACKUP_ROOT/system-configs/" --verbose
   rm /tmp/crontab-backup.txt

   # 5. Docker network info (for macvlan recreation)
   echo "=== Docker Networks ==="
   docker network ls > /tmp/docker-networks.txt
   docker network inspect dock_net > /tmp/docker-macvlan-config.json 2>/dev/null || echo "dock_net not found" > /tmp/docker-macvlan-config.json
   sudo /usr/bin/rclone copy /tmp/docker-networks.txt "$BACKUP_ROOT/system-configs/" --verbose
   sudo /usr/bin/rclone copy /tmp/docker-macvlan-config.json "$BACKUP_ROOT/system-configs/" --verbose
   rm /tmp/docker-networks.txt /tmp/docker-macvlan-config.json

   # 6. SSH keys and home configs
   echo "=== SSH Keys and Home Configs ==="
   sudo /usr/bin/rclone copy "/home/$USERNAME/.ssh/" "$BACKUP_ROOT/ssh/" --verbose
   sudo /usr/bin/rclone copy "/home/$USERNAME/.bashrc" "$BACKUP_ROOT/home-configs/" --verbose
   sudo /usr/bin/rclone copy "/home/$USERNAME/.profile" "$BACKUP_ROOT/home-configs/" --verbose

   # 7. Package list for system rebuild
   echo "=== System Package List ==="
   dpkg --get-selections > /tmp/installed-packages.txt
   sudo /usr/bin/rclone copy /tmp/installed-packages.txt "$BACKUP_ROOT/system-configs/" --verbose
   rm /tmp/installed-packages.txt

   echo
   echo "=== Backup Cleanup (Retention Policy) ==="
   echo "Retention: Last 3 + Monthly (30d+) + Quarterly (90d+) + Yearly (365d+)"
   echo
   
   # Get list of all backup directories (newest first)
   BACKUP_DIRS=$(sudo /usr/bin/rclone lsf "$BACKUP_REMOTE/" --dirs-only | grep -E '^[0-9]{8}-[0-9]{6}/$' | sort -r)
   
   # Convert to array and process retention
   DIRS_ARRAY=($BACKUP_DIRS)
   KEEP_COUNT=0
   declare -a YEARLY_KEPT QUARTERLY_KEPT MONTHLY_KEPT
   
   for dir in "${DIRS_ARRAY[@]}"; do
       dir_clean=${dir%/}  # Remove trailing slash
       dir_date=${dir_clean%-*}  # Extract date part (YYYYMMDD)
       
       # Calculate age in days
       dir_epoch=$(date -d "${dir_date:0:4}-${dir_date:4:2}-${dir_date:6:2}" +%s)
       current_epoch=$(date +%s)
       age_days=$(( (current_epoch - dir_epoch) / 86400 ))
       
       # Retention logic
       KEEP=false
       REASON=""
       
       if [ $KEEP_COUNT -lt 3 ]; then
           # Keep last 3 backups regardless of age
           KEEP=true
           REASON="recent backup ($((KEEP_COUNT + 1))/3)"
           ((KEEP_COUNT++))
       elif [ $age_days -ge 365 ]; then
           # Keep yearly backups (365+ days old)
           year=$(date -d "${dir_date:0:4}-${dir_date:4:2}-${dir_date:6:2}" +%Y)
           if [[ ! " ${YEARLY_KEPT[@]} " =~ " ${year} " ]]; then
               KEEP=true
               REASON="yearly backup ($year)"
               YEARLY_KEPT+=($year)
           fi
       elif [ $age_days -ge 90 ]; then
           # Keep one per quarter (90+ days old)
           quarter_key="${dir_date:0:4}-Q$((10#${dir_date:4:2} / 3 + (10#${dir_date:4:2} % 3 > 0)))"
           if [[ ! " ${QUARTERLY_KEPT[@]} " =~ " ${quarter_key} " ]]; then
               KEEP=true
               REASON="quarterly backup ($quarter_key)"
               QUARTERLY_KEPT+=($quarter_key)
           fi
       elif [ $age_days -ge 30 ]; then
           # Keep one per month (30+ days old)
           month_key="${dir_date:0:6}"
           if [[ ! " ${MONTHLY_KEPT[@]} " =~ " ${month_key} " ]]; then
               KEEP=true
               REASON="monthly backup ($month_key)"
               MONTHLY_KEPT+=($month_key)
           fi
       fi
       
       if [ "$KEEP" = true ]; then
           echo "KEEPING: $dir_clean ($REASON)"
       else
           echo "DELETING: $dir_clean (age: ${age_days} days)"
           sudo /usr/bin/rclone purge "$BACKUP_REMOTE/$dir_clean" --verbose
       fi
   done
   
   echo
   echo "Disaster recovery backup completed: $(date)"
   echo "Current backup: $BACKUP_ROOT"
   echo "Total backups retained: $(echo "${DIRS_ARRAY[@]}" | wc -w) directories processed"
} 2>&1 | msmtp "$NOTIFICATION_EMAIL"
