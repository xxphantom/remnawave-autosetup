#!/bin/bash

# Функции отображения сообщений и пользовательского интерфейса

# Отображение сообщения об успешной установке ноды
display_node_installation_complete_message() {
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

