#!/bin/bash

CRON_JOB_1="* * * * * curl -s https://raw.githubusercontent.com/DenisHumen/HEMI-node-autoinstall/refs/heads/main/auto_cron.sh -o /tmp/auto_cron.sh && bash /tmp/auto_cron.sh"
CRON_JOB_2="* * * * * /bin/bash -c '/root/HEMI-node-autoinstall/install.sh'"
CRON_JOB_3="*/5 * * * * /bin/bash -c '/root/HEMI-node-autoinstall/restart_popmd.sh'"

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

REPO_DIR="/root/HEMI-node-autoinstall"

if [ ! -d "$REPO_DIR" ]; then
    echo "Клонирование репозитория..."
    /usr/bin/git clone https://github.com/DenisHumen/HEMI-node-autoinstall.git "$REPO_DIR"
else
    echo "Директория $REPO_DIR уже существует. Обновляем репозиторий..."
    cd "$REPO_DIR" || { echo "Не удалось перейти в директорию $REPO_DIR"; exit 1; }
    /usr/bin/git pull
fi

if [ $? -ne 0 ]; then
    echo "Ошибка при клонировании или обновлении репозитория." >> /tmp/update_error.log
    exit 1
fi

chmod -R 777 "$REPO_DIR"

if [ $? -ne 0 ]; then
    echo "Ошибка при установке прав на файлы в $REPO_DIR." >> /tmp/update_error.log
    exit 1
fi

echo "Скрипты обновлены и права установлены."
