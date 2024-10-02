#!/bin/bash

CRON_JOB_1="*/15 * * * * bash -c 'bash <(curl -s https://raw.githubusercontent.com/DenisHumen/HEMI-node-autoinstall/refs/heads/main/auto_cron.sh)'"

CRON_JOB_2="0 3 * * * bash -c '/root/HEMI-node-autoinstall/install.sh'"

CRON_JOB_3="*/5 * * * * bash -c '/root/HEMI-node-autoinstall/restart_popmd.sh'"

(crontab -l | grep -q "$CRON_JOB_1") || (crontab -l; echo "$CRON_JOB_1") | crontab -
(crontab -l | grep -q "$CRON_JOB_2") || (crontab -l; echo "$CRON_JOB_2") | crontab -
(crontab -l | grep -q "$CRON_JOB_3") || (crontab -l; echo "$CRON_JOB_3") | crontab -

cd /root/HEMI-node-autoinstall/
git pull

echo "Задачи успешно добавлены в crontab и выполнено обновление скриптов."
