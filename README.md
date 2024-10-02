# HEMI-node-autoinstall
Автоматическая установка ноды HEMI network 
Перед Установкой нужно установить **curl** и **git**

```bash
git clone https://github.com/DenisHumen/HEMI-node-autoinstall.git 
```
Скачивайте MySQL server и настраивайте такую структура
```bash
DB_NAME="DATA"
TABLE_NAME="HEMI"
```
Создайте в таблице такие колонки
```bash
id - тип int # Автоинкремент 
# Остальные должны иметь тип text
name
gray_ip 
white_ip 
ethereum_address 
private_key
public_key 
pubkey_hash 
```
Настройте пользователя для доступа к таблице, чтение и запись
Измените в базе параметры под свою базу
```bash
DB_HOST="IP адрес базы mysql"
DB_USER="Пользователь"
DB_PASS="Пароль"
```
Дальше запуск
```bash
bash HEMI-node-autoinstall/install.sh
```
Для проверки состояния ноды
```bash
service popmd status
journalctl -f
```

Для автоматического обновления и связи с репозиторием, установите коману в крон
```bash
* * * * * curl -s https://raw.githubusercontent.com/DenisHumen/HEMI-node-autoinstall/refs/heads/main/auto_cron.sh -o /tmp/auto_cron.sh && bash /tmp/auto_cron.sh
```