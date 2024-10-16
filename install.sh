#!/bin/bash

FILE_PATH="$HOME/popm-address.json"
JSON_FILE="$HOME/popm-address.json"
DB_HOST="10.19.245.150"
DB_USER="user"
DB_PASS="FbO2O(xQGlbwYEPr"
DB_NAME="DATA"
TABLE_NAME="HEMI"
MACHINE_NAME=$(cat /etc/hostname)
HEMI_DIR="/root/heminetwork_v0.4.5_linux_amd64"
DOWNLOAD_URL="https://github.com/hemilabs/heminetwork/releases/download/v0.4.5/heminetwork_v0.4.5_linux_amd64.tar.gz"
SERVICE_NAME="popmd.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"
BINARY_PATH="$HEMI_DIR/popmd"

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
        extract_json_data
        find_gray_ip
        exit 0
    fi
}

download_and_extract() {
    if [ -d "$HEMI_DIR" ]; then
        echo "Директория $HEMI_DIR уже существует. Пропускаем загрузку и распаковку."
    else
        echo "Директория $HEMI_DIR не найдена. Скачиваем и распаковываем новую версию..."
        wget "$DOWNLOAD_URL"
        mkdir "$HEMI_DIR"
        tar --strip-components=1 -xzvf $(basename "$DOWNLOAD_URL") -C "$HEMI_DIR"
    fi
}


generate_keys() {
    TMP_JSON_FILE="/tmp/popm-address.json"  # Путь к файлу в /tmp

    if [ -f "$JSON_FILE" ]; then
        echo "Файл $JSON_FILE уже существует. Пропускаем генерацию ключей."
    elif [ -f "$TMP_JSON_FILE" ]; then
        echo "Файл $TMP_JSON_FILE уже существует в /tmp. Пропускаем генерацию ключей."
    else
        echo "Файл $JSON_FILE не найден, создаём новый ключ в /tmp..."
        ./keygen -secp256k1 -json -net="testnet" > "$TMP_JSON_FILE"
        if [ $? -eq 0 ]; then
            echo "Ключ успешно сгенерирован и сохранён в $TMP_JSON_FILE."
        else
            echo "Произошла ошибка при генерации ключа."
        fi
    fi
}



extract_json_data() {
    if [[ ! -f "$JSON_FILE" ]];then
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
    GRAY_IP=$(ip -4 -o addr show scope global | awk '/inet 10\.|inet 172\.[1-3][6-9]\.|inet 192\.168\./ {print $4}' | cut -d/ -f1)
    if [[ -z "$GRAY_IP" ]];then
        echo "Серый IP не найден."
        return 1
    else
        echo "Серый IP-адрес найден: $GRAY_IP"
        EXISTING_RECORD=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM $TABLE_NAME WHERE gray_ip='$GRAY_IP';")
        if [[ "$EXISTING_RECORD" -eq 0 ]];then
            MACHINE_NAME=$(cat /etc/hostname)
            mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
INSERT INTO $TABLE_NAME (name, gray_ip) VALUES ('$MACHINE_NAME', '$GRAY_IP');
EOF
            if [[ $? -eq 0 ]];then
                echo "Новая запись успешно добавлена в базу данных."
            else
                echo "Произошла ошибка при добавлении новой записи в базу данных."
            fi
        else
            echo "Запись с серым IP-адресом уже существует в базе данных."
        fi
        return 0
    fi
}

insert_into_database() {
    EXISTS=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -sse "SELECT COUNT(*) FROM $TABLE_NAME WHERE name='$MACHINE_NAME';")
    if [[ "$EXISTS" -gt 0 ]]; then
        echo "Запись с именем '$MACHINE_NAME' уже существует. Обновление данных."
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE $TABLE_NAME SET ethereum_address='$ETH_ADDRESS', private_key='$PRIVATE_KEY', public_key='$PUBLIC_KEY', pubkey_hash='$PUBKEY_HASH' WHERE name='$MACHINE_NAME';
EOF
        if [[ $? -eq 0 ]];then
            echo "Данные успешно обновлены в базе данных."
        else
            echo "Произошла ошибка при обновлении данных в базе данных."
        fi
    else
        echo "Запись с именем '$MACHINE_NAME' не найдена. Добавление новой записи."
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
INSERT INTO $TABLE_NAME (name, ethereum_address, private_key, public_key, pubkey_hash) VALUES ('$MACHINE_NAME', '$ETH_ADDRESS', '$PRIVATE_KEY', '$PUBLIC_KEY', '$PUBKEY_HASH');
EOF
        if [[ $? -eq 0 ]];then
            echo "Данные успешно добавлены в базу данных."
        else
            echo "Произошла ошибка при добавлении данных в базу данных."
        fi
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

    NEW_SERVICE_CONTENT=$(cat <<EOL
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
    )

    # Проверка существования файла и сравнение его содержимого с новым
    if [ -f "$SERVICE_FILE" ]; then
        EXISTING_CONTENT=$(cat "$SERVICE_FILE")

        if [ "$NEW_SERVICE_CONTENT" == "$EXISTING_CONTENT" ]; then
            echo "Конфигурационный файл уже существует и содержит те же данные. Перезапись не требуется."
        else
            echo "Конфигурационный файл существует, но данные отличаются. Обновление файла..."
            echo "$NEW_SERVICE_CONTENT" | sudo tee "$SERVICE_FILE" > /dev/null
            manage_service
        fi
    else
        echo "Конфигурационный файл не найден. Создание нового файла..."
        echo "$NEW_SERVICE_CONTENT" | sudo tee "$SERVICE_FILE" > /dev/null
        manage_service
    fi
}


manage_service() {
    echo "Перезагрузка systemd..."
    sudo systemctl daemon-reload
    echo "Запуск и включение автозапуска сервиса $SERVICE_NAME..."
    sudo systemctl start "$SERVICE_NAME"
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl restart "$SERVICE_NAME"
}

main() {
    download_and_extract
    extract_json_data
    create_service
    check_internet
    check_json_file
    install_dependencies
    generate_keys
    find_gray_ip
    update_bashrc
    manage_service
    insert_into_database
    echo "Скрипт выполнен успешно."
    echo -e "\033"
}

main
