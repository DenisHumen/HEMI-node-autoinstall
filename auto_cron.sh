#!/bin/bash

CRON_JOB_1="* * * * * curl -s https://raw.githubusercontent.com/DenisHumen/HEMI-node-autoinstall/refs/heads/main/auto_cron.sh -o /tmp/auto_cron.sh && bash /tmp/auto_cron.sh"

CRON_JOB_2="0 3 * * * bash -c '/root/HEMI-node-autoinstall/install.sh'"

CRON_JOB_3="*/5 * * * * bash -c '/root/HEMI-node-autoinstall/restart_popmd.sh'"

CRON_FILE=$(mktemp)

echo "$CRON_JOB_1" >> "$CRON_FILE"
echo "$CRON_JOB_2" >> "$CRON_FILE"
echo "$CRON_JOB_3" >> "$CRON_FILE"

crontab "$CRON_FILE"

rm "$CRON_FILE"

cd /root/HEMI-node-autoinstall/
git pull

echo "Все задачи crontab были перезаписаны, и скрипты обновлены."
