#!/bin/bash

SERVICE="popmd.service"

check_service_status() {
    STATUS=$(systemctl is-active "$SERVICE")

    if [ "$STATUS" != "active" ]; then
        echo "Сервис $SERVICE не активен. Выполняется перезапуск..."
        systemctl restart "$SERVICE"
        
        if [ "$(systemctl is-active "$SERVICE")" == "active" ]; then
            echo "Сервис $SERVICE успешно перезапущен."
        else
            echo "Не удалось перезапустить сервис $SERVICE."
        fi
    else
        echo "Сервис $SERVICE работает корректно."
    fi
}

check_service_status
