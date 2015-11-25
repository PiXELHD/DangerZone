#!/bin/bash
# Backup and Sync Script
# This script equires you to create an SSH Key.
# ssh-keygen -t rsa
# ssh-copy-id -i ~/.ssh/id_rsa.pub user@host

# Common Variables
DATE=`date +%m.%d.%y`

# Variables
SITE=""                      # Name of Site
SITEDB=""                    # Database Name
DBUSER=""                    # Database User Name
DBPASS=""                    # Database User Password
DAYS="30"                    # Length of Time to Keep Backups
LOG="/var/backup/backup.log" # Location of Backup Log
HOST=""                      # Remote server location. (Domain or IP).
USER=""                      # User you connect to remote server as.
BACKUPDIR="/var/backup/"     # Location of files you want backed up.
BACKUPDEST="/home/backup/"   # Destination of Backup.


####### DO NOT EDIT BELOW THIS LINE #######


# Create Directories If They Don't Exist.
mkdir -p /var/backup/$SITE/database
mkdir -p /var/backup/$SITE/site

# Main Site MySQL Dump.
mysqldump -u $DBUSER -p${DBPASS} $SITEDB | gzip > /var/backup/$SITE/database/${SITE}.db.backup.${DATE}.bak.gz

# Verify Backup of Database and Write to Log.
if [ -e /var/backup/$SITE/database/${SITE}.db.backup.${DATE}.bak.gz ];
then
  echo Backup of $SITE Database Created on $DATE >> $LOG
else
  echo WARNING: Backup of $SITE Database FAILED on $DATE >> $LOG
fi

# Site Code Backup.
tar czf /var/backup/$SITE/site/${SITE}.backup.${DATE}.tar -C / var/www/${SITE}/
gzip /var/backup/$SITE/site/${SITE}.backup.${DATE}.tar

# Verify Backup of Site and Write to Log.
if [ -e /var/backup/$SITE/site/${SITE}.backup.${DATE}.tar.gz ];
then
  echo Backup of $SITE Code Base Created on $DATE >> $LOG
else
  echo WARNING: Backup of $SITE Code Base FAILED on $DATE >> $LOG
fi

# Clean Up Old Backups - Remove Anything Older than Specified Number of Days.
find /var/backup/$SITE/database* -mtime +${DAYS} -exec rm {} \;
find /var/backup/$SITE/site* -mtime +${DAYS} -exec rm {} \;

# RSYNC Command
rsync -e ssh -a --delete $BACKUPDIR$SITE $USER@$HOST:$BACKUPDEST

# Write to Log
echo RSYNC of $SITE Completed on $DATE >> $LOG

# EOF
