#!/bin/bash

CRON_JOB_1="*/15 * * * * bash <(curl -s https://github.com/ЗДЕСЬ_ССЫЛКУ_Я_УКАЖУ_САМ)"

CRON_JOB_2="0 3 * * * /root/HEMI-node-autoinstall/install.sh"

CRON_JOB_3="*/5 * * * * /root/HEMI-node-autoinstall/restart_popmd.sh"

(crontab -l | grep -q "$CRON_JOB_1") || (crontab -l; echo "$CRON_JOB_1") | crontab -
(crontab -l | grep -q "$CRON_JOB_2") || (crontab -l; echo "$CRON_JOB_2") | crontab -
(crontab -l | grep -q "$CRON_JOB_3") || (crontab -l; echo "$CRON_JOB_3") | crontab -

echo "Задачи успешно добавлены в crontab."
