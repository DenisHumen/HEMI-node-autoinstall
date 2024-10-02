#!/bin/bash

CRON_JOB_1="* * * * * curl -s https://raw.githubusercontent.com/DenisHumen/HEMI-node-autoinstall/refs/heads/main/auto_cron.sh -o /tmp/auto_cron.sh && bash /tmp/auto_cron.sh"
CRON_JOB_2="0 3 * * * bash -c '/root/HEMI-node-autoinstall/install.sh'"
CRON_JOB_3="*/5 * * * * bash -c '/root/HEMI-node-autoinstall/restart_popmd.sh'"

NEW_CRON_FILE=$(mktemp)

echo "$CRON_JOB_1" >> "$NEW_CRON_FILE"
echo "$CRON_JOB_2" >> "$NEW_CRON_FILE"
echo "$CRON_JOB_3" >> "$NEW_CRON_FILE"

CURRENT_CRON_FILE=$(mktemp)

crontab -l > "$CURRENT_CRON_FILE" 2>/dev/null

if ! cmp -s "$NEW_CRON_FILE" "$CURRENT_CRON_FILE"; then
    crontab "$NEW_CRON_FILE"
    echo "Обнаружены изменения. Задачи crontab были перезаписаны."
else
    echo "Изменений в crontab нет. Перезапись не требуется."
fi

rm "$NEW_CRON_FILE" "$CURRENT_CRON_FILE"

/usr/bin/git clone https://github.com/DenisHumen/HEMI-node-autoinstall.git
cd /root/HEMI-node-autoinstall/
/usr/bin/git pull

echo "Скрипты обновлены."
