#!/bin/bash

# ===================================================================================
#                              УСТАНОВКА НОДЫ REMNAWAVE
# ===================================================================================

setup_node() {
    clear
    
    # Установка общих зависимостей
    install_dependencies
    
    mkdir -p $REMNANODE_DIR && cd $REMNANODE_DIR
    curl -sS https://raw.githubusercontent.com/remnawave/node/refs/heads/main/docker-compose-prod.yml > docker-compose.yml
    
    # Создание Makefile для ноды
    create_makefile "$REMNANODE_DIR"
    
    echo -ne "${ORANGE}Введите порт для вашей ноды: ${NC}"
    read NODE_PORT
    echo
    
    echo -e "${ORANGE}Введите сертификат сервера (вставьте содержимое и 2 раза нажмите Enter): ${NC}"
    CERTIFICATE=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            if [ -n "$CERTIFICATE" ]; then
                break
            fi
        else
            CERTIFICATE="$CERTIFICATE$line\n"
        fi
    done
    
    echo -ne "${BOLD_RED}Вы уверены, что сертификат правильный? (y/n): ${NC}"
    read confirm
    echo
    
    echo -e "### APP ###\nAPP_PORT=$NODE_PORT\n$CERTIFICATE" > .env
    
    docker compose up -d && docker compose logs -f > /tmp/node_logs 2>&1 & LOGS_PID=$!
    sleep 1
    tail -f /tmp/node_logs & TAIL_PID=$!
    sleep 5
    kill $LOGS_PID $TAIL_PID 2>/dev/null
    wait $LOGS_PID $TAIL_PID 2>/dev/null
    rm -f /tmp/node_logs
    
    # Проверяем, запущена ли нода
    NODE_STATUS=$(docker compose ps --services --filter "status=running" | grep -q "node" && echo "running" || echo "stopped")
    
    unset CERTIFICATE
    
    draw_info_box "Панель Remnawave" "Установка ноды завершена"
    
    display_node_installation_complete_message
}
