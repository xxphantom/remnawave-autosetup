#!/bin/bash

# ===================================================================================
#                              УСТАНОВКА НОДЫ REMNAWAVE
# ===================================================================================

setup_node() {
    clear
   
       # Проверка наличия предыдущей установки
    if [ -d "$REMNANODE_DIR" ]; then
        echo -e "${BOLD_YELLOW}Обнаружена предыдущая установка RemnaWave Node.${NC}"
        echo -ne "${ORANGE}Хотите удалить предыдущую установку перед продолжением? (y/n): ${NC}"
        read REMOVE_PREVIOUS
        REMOVE_PREVIOUS=$(echo "$REMOVE_PREVIOUS" | tr '[:upper:]' '[:lower:]')
        echo

        if [ "$REMOVE_PREVIOUS" = "y" ] || [ "$REMOVE_PREVIOUS" = "yes" ]; then
            echo -e "${BOLD_YELLOW}Удаление предыдущей установки...${NC}"
            
            cd $REMNANODE_DIR && \
            docker compose -f docker-compose.yml down 2>/dev/null || true
            rm -rf $REMNANODE_DIR
            
            echo -e "${BOLD_GREEN}Предыдущая установка успешно удалена.${NC}"
        else
            echo -e "${BOLD_YELLOW}Продолжаем установку без удаления предыдущей.${NC}"
        fi
    fi

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
    
    if [ "$NODE_STATUS" = "running" ]; then
        echo -e "${BOLD_GREEN}✓ Нода Remnawave успешно установлена и запущена!${NC}"
        echo -e "${LIGHT_GREEN}• Порт ноды: ${BOLD_GREEN}$NODE_PORT${NC}"
        echo -e "${LIGHT_GREEN}• Директория ноды: ${BOLD_GREEN}$REMNANODE_DIR${NC}"
        echo -e "\n${LIGHT_GREEN}Для управления нодой используйте следующие команды:${NC}"
        echo -e "${ORANGE}   cd $REMNANODE_DIR${NC}"
        echo -e "${ORANGE}   make start   ${NC}- Запуск ноды и просмотр логов"
        echo -e "${ORANGE}   make stop    ${NC}- Остановка ноды"
        echo -e "${ORANGE}   make restart ${NC}- Перезапуск ноды"
        echo -e "${ORANGE}   make logs    ${NC}- Просмотр логов ноды"
    else
        echo -e "${BOLD_RED}⚠ Нода Remnawave была установлена, но не запущена автоматически.${NC}"
        echo -e "${LIGHT_RED}Для запуска ноды вручную выполните:${NC}"
        echo -e "${ORANGE}   cd $REMNANODE_DIR${NC}"
        echo -e "${ORANGE}   make start${NC}"
        echo -e "\n${LIGHT_RED}Если ошибка сохраняется, проверьте логи:${NC}"
        echo -e "${ORANGE}   make logs${NC}"
    fi
    
    unset NODE_PORT
    
    echo -e "\n${BOLD_GREEN}Нажмите Enter, чтобы вернуться в главное меню...${NC}"
    read -r

}
