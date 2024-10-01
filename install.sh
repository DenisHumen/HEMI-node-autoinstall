#!/bin/bash

FILE_PATH="$HOME/popm-address.json"
JSON_FILE="$HOME/popm-address.json"
DB_HOST="ADRESS MYSQL"
DB_USER="USER"
DB_PASS="PASSWORD"
DB_NAME="DATA"
TABLE_NAME="HEMI"
MACHINE_NAME=$(cat /etc/hostname)
HEMI_DIR="/root/heminetwork_"
DOWNLOAD_URL="https://github.com/hemilabs/heminetwork/releases/download/v0.4.3/heminetwork_v0.4.3_linux_amd64.tar.gz"
SERVICE_NAME="popmd.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"
BINARY_PATH="/root/heminetwork_v0.4.3_linux_amd64/popmd"

check_internet() {
    echo "Проверка доступа в интернет..."
    
    if ping -c 1 -W 5 8.8.8.8 > /dev/null 2>&1; then
        echo -e "\033[32mИнтернет доступен. Продолжаем выполнение скрипта.\033[0m"
    else
        echo -e "\033[31mИнтернет недоступен. Скрипт завершает выполнение.\033[0m"
        exit 1
    fi
}

install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install jq mysql-client -y
}

check_json_file() {
    if [ -f "$FILE_PATH" ]; then
        echo "Файл $FILE_PATH уже существует. Скрипт завершает выполнение."
        exit 0
    fi
}

download_and_extract() {
    if [ -d "$HEMI_DIR"* ]; then
        echo "Директория с именем $HEMI_DIR уже существует. Загрузка не требуется."
    else
        echo "Директория не найдена. Загрузка и распаковка файлов..."
        wget "$DOWNLOAD_URL"
        tar -xvf $(basename "$DOWNLOAD_URL") && rm $(basename "$DOWNLOAD_URL")
        cd heminetwork_v0.4.3_linux_amd64 || exit 1
    fi
}

generate_keys() {
    ./keygen -secp256k1 -json -net="testnet" > "$JSON_FILE"
}

extract_json_data() {
    if [[ ! -f "$JSON_FILE" ]]; then
        echo "Файл $JSON_FILE не найден!"
        exit 1
    fi
    ETH_ADDRESS=$(jq -r '.ethereum_address' "$JSON_FILE")
    PRIVATE_KEY=$(jq -r '.private_key' "$JSON_FILE")
    PUBLIC_KEY=$(jq -r '.public_key' "$JSON_FILE")
    PUBKEY_HASH=$(jq -r '.pubkey_hash' "$JSON_FILE")
}

find_gray_ip() {
    echo "Поиск серого IP-адреса..."

    # Ищем IP-адрес в диапазонах частных сетей (серый IP)
    GRAY_IP=$(ip -4 -o addr show scope global | awk '/inet 10\.|inet 172\.[1-3][6-9]\.|inet 192\.168\./ {print $4}' | cut -d/ -f1)

    if [[ -z "$GRAY_IP" ]]; then
        echo "Серый IP не найден."
        return 1
    else
        echo "Серый IP-адрес найден: $GRAY_IP"
        return 0
    fi
}


insert_into_database() {
    EXISTS=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -sse "SELECT COUNT(*) FROM $TABLE_NAME WHERE name='$MACHINE_NAME';")
    if [[ "$EXISTS" -gt 0 ]]; then
        echo "Запись с именем '$MACHINE_NAME' уже существует в базе данных. Данные не будут добавлены."
        exit 0
    fi

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
INSERT INTO $TABLE_NAME (name, ethereum_address, private_key, public_key, pubkey_hash, gray_ip)
VALUES ('$MACHINE_NAME', '$ETH_ADDRESS', '$PRIVATE_KEY', '$PUBLIC_KEY', '$PUBKEY_HASH', '$GRAY_IP');
EOF

    if [[ $? -eq 0 ]]; then
        echo "Данные успешно добавлены в базу данных."
    else
        echo "Произошла ошибка при добавлении данных в базу данных."
    fi
}

update_bashrc() {
    echo "export POPM_BTC_PRIVKEY='$PRIVATE_KEY'" >> ~/.bashrc
    echo 'export POPM_STATIC_FEE=50' >> ~/.bashrc
    echo 'export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public' >> ~/.bashrc
    source ~/.bashrc
}

create_service() {
    echo "Создание конфигурационного файла для сервиса $SERVICE_NAME..."
    cat <<EOL | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=POPM Daemon
After=network.target

[Service]
Environment=POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public
Environment=POPM_BTC_PRIVKEY=$PRIVATE_KEY
Environment=POPM_STATIC_FEE=50
ExecStart=$BINARY_PATH
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
User=root
Environment=POP_ENV=production
LimitCORE=0

[Install]
WantedBy=multi-user.target
EOL
}

manage_service() {
    echo "Перезагрузка systemd..."
    sudo systemctl daemon-reload
    echo "Запуск и включение автозапуска сервиса $SERVICE_NAME..."
    sudo systemctl start "$SERVICE_NAME"
    sudo systemctl enable "$SERVICE_NAME"
    #sudo systemctl status "$SERVICE_NAME"
}

main() {
    check_internet
    find_gray_ip
    check_json_file
    install_dependencies
    download_and_extract
    generate_keys
    extract_json_data
    update_bashrc
    create_service
    manage_service
    insert_into_database

    echo "Скрипт выполнен успешно."
    echo -e "\033[32m    Для проверки статуса сервиса: service popmd status\033[0m"
    echo -e "\033[32m    Для проверки логов journalctl -f\033[0m"
}


main


main