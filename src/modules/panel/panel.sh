#!/bin/bash

# ===================================================================================
#                              УСТАНОВКА ПАНЕЛИ REMNAWAVE
# ===================================================================================

install_panel() {
    clear

    # Установка общих зависимостей
    install_dependencies

    # Создаем базовую директорию для всего проекта
    mkdir -p $REMNAWAVE_DIR/{panel,caddy}

    # Переходим в директорию панели
    cd $REMNAWAVE_DIR/panel

    # Генерация JWT секретов с помощью openssl
    JWT_AUTH_SECRET=$(openssl rand -hex 32 | tr -d '\n')
    JWT_API_TOKENS_SECRET=$(openssl rand -hex 32 | tr -d '\n')

    # Генерация безопасных учетных данных
    DB_USER="remnawave_$(openssl rand -hex 4 | tr -d '\n')"
    DB_PASSWORD=$(generate_secure_password 16)
    DB_NAME="remnawave_db"
    METRICS_PASS=$(generate_secure_password 16)

    curl -s -o .env https://raw.githubusercontent.com/remnawave/backend/refs/heads/dev/.env.sample

    # Спрашиваем, нужна ли интеграция с Telegram
    echo -ne "${GREEN}Хотите включить интеграцию с Telegram? (y/n): ${NC}"
    read IS_TELEGRAM_ENABLED
    IS_TELEGRAM_ENABLED=$(echo "$IS_TELEGRAM_ENABLED" | tr '[:upper:]' '[:lower:]')
    echo

    # Преобразование y/n в true/false для файла .env
    if [ "$IS_TELEGRAM_ENABLED" = "y" ] || [ "$IS_TELEGRAM_ENABLED" = "yes" ]; then
        IS_TELEGRAM_ENV_VALUE="true"
        # Если интеграция с Telegram включена, запрашиваем параметры
        echo -ne "${ORANGE}Введите токен вашего Telegram бота: ${NC}"
        read TELEGRAM_BOT_TOKEN
        echo

        echo -ne "${ORANGE}Введите ID администратора Telegram: ${NC}"
        read TELEGRAM_ADMIN_ID
        echo

        echo -ne "${ORANGE}Введите ID чата для уведомлений: ${NC}"
        read NODES_NOTIFY_CHAT_ID
        echo
    else
        # Если интеграция с Telegram не включена, устанавливаем параметры в "change-me"
        IS_TELEGRAM_ENV_VALUE="false"
        echo -e "${BOLD_YELLOW}Пропуск интеграции с Telegram.${NC}"
        TELEGRAM_BOT_TOKEN="change-me"
        TELEGRAM_ADMIN_ID="change-me"
        NODES_NOTIFY_CHAT_ID="change-me"
    fi

    echo -ne "${ORANGE}Введите домен для поддержки (для отображения в клиентском приложении) (например, support.example.com): ${NC}"
    read SUB_SUPPORT_DOMAIN
    echo

    echo -ne "${ORANGE}Введите домен для веб-страницы (для отображения в клиентском приложении) (например, webpage.example.com): ${NC}"
    read SUB_WEBPAGE_DOMAIN
    echo

    # Запрашиваем основной домен для панели и домен для подписок
    echo -ne "${ORANGE}Введите основной домен для вашей панели (например, panel.example.com): ${NC}"
    read SCRIPT_PANEL_DOMAIN
    echo

    echo -ne "${ORANGE}Введите домен для подписок (например, subs.example.com): ${NC}"
    read SCRIPT_SUB_DOMAIN
    echo

    # Запрос на установку remnawave-json
    echo -ne "${GREEN}Установить remnawave-json https://github.com/Jolymmiles/remnawave-json ? (y/n): ${NC}"
    read INSTALL_REMNAWAVE_JSON
    INSTALL_REMNAWAVE_JSON=$(echo "$INSTALL_REMNAWAVE_JSON" | tr '[:upper:]' '[:lower:]')
    echo

    echo -e "${BOLD_RED}\033[1m┌────────────────────────────────────────────┐\033[0m${NC}"
    echo -e "${BOLD_RED}\033[1m│     Выберите способ создания пароля:       │\033[0m${NC}"
    echo -e "${BOLD_RED}\033[1m└────────────────────────────────────────────┘\033[0m${NC}"
    echo
    echo -e "${ORANGE}1. Ввести пароль вручную${NC}"
    echo -e "${ORANGE}2. Автоматически сгенерировать надежный пароль${NC}"
    echo
    echo -ne "${GREEN}Выберите опцию (1-2): ${NC}"
    read password_option
    echo

    echo -ne "${ORANGE}Пожалуйста, введите имя пользователя SuperAdmin: ${NC}"
    read SUPERADMIN_USERNAME
    echo

    if [ "$password_option" = "1" ]; then
        # Ручной ввод пароля
        while true; do
            echo -ne "${ORANGE}Введите пароль SuperAdmin: ${NC}"
            stty -echo
            read PASSWORD1
            stty echo
            echo

            echo -ne "${BOLD_RED}Повторно введите пароль SuperAdmin для подтверждения: ${NC}"
            stty -echo
            read PASSWORD2
            stty echo
            echo

            if [ "$PASSWORD1" = "$PASSWORD2" ]; then
                SUPERADMIN_PASSWORD=$PASSWORD1
                break
            else
                echo -e "${BOLD_RED}Пароли не совпадают. Пожалуйста, попробуйте снова.${NC}"
            fi
        done
    else
        # Автоматическая генерация пароля
        SUPERADMIN_PASSWORD=$(generate_secure_password 16)
        echo -e "${BOLD_GREEN}Сгенерирован надежный пароль: ${BOLD_RED}$SUPERADMIN_PASSWORD${NC}"
        echo -e "${ORANGE}Обязательно сохраните этот пароль в надежном месте!${NC}"
        echo
    fi

    sed -i "s|JWT_AUTH_SECRET=change_me|JWT_AUTH_SECRET=$JWT_AUTH_SECRET|" .env
    sed -i "s|JWT_API_TOKENS_SECRET=change_me|JWT_API_TOKENS_SECRET=$JWT_API_TOKENS_SECRET|" .env
    sed -i "s|IS_TELEGRAM_ENABLED=false|IS_TELEGRAM_ENABLED=$IS_TELEGRAM_ENV_VALUE|" .env
    sed -i "s|TELEGRAM_BOT_TOKEN=change_me|TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN|" .env
    sed -i "s|TELEGRAM_ADMIN_ID=change_me|TELEGRAM_ADMIN_ID=$TELEGRAM_ADMIN_ID|" .env
    sed -i "s|NODES_NOTIFY_CHAT_ID=change_me|NODES_NOTIFY_CHAT_ID=$NODES_NOTIFY_CHAT_ID|" .env
    sed -i "s|SUB_SUPPORT_URL=https://support.example.com|SUB_SUPPORT_URL=https://$SUB_SUPPORT_DOMAIN|" .env
    sed -i "s|SUB_WEBPAGE_URL=https://example.com|SUB_WEBPAGE_URL=https://$SUB_WEBPAGE_DOMAIN|" .env
    sed -i "s|SUB_PUBLIC_DOMAIN=example.com|SUB_PUBLIC_DOMAIN=$SCRIPT_SUB_DOMAIN|" .env
    # sed -i "s|SUPERADMIN_USERNAME=change_me|SUPERADMIN_USERNAME=$SUPERADMIN_USERNAME|" .env
    # sed -i "s|SUPERADMIN_PASSWORD=change_me|SUPERADMIN_PASSWORD=$SUPERADMIN_PASSWORD|" .env
    sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@remnawave-db:5432/$DB_NAME|" .env
    sed -i "s|POSTGRES_USER=.*|POSTGRES_USER=$DB_USER|" .env
    sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$DB_PASSWORD|" .env
    sed -i "s|POSTGRES_DB=.*|POSTGRES_DB=$DB_NAME|" .env
    sed -i "s|METRICS_PASS=.*|METRICS_PASS=$METRICS_PASS|" .env

    echo -e "${GREEN}Файл .env успешно настроен.${NC}"
    sleep 3

    # Создаем docker-compose.yml для панели
    curl -s -o docker-compose.yml https://raw.githubusercontent.com/remnawave/backend/refs/heads/dev/docker-compose-prod.yml

    # Создаем Makefile
    create_makefile "$REMNAWAVE_DIR/panel"

    # ===================================================================================
    # Установка и настройка remnawave-json
    # ===================================================================================

    setup_remnawave_json

    # ===================================================================================
    # Установка и настройка Caddy для панели и подписок
    # ===================================================================================

    setup_caddy_for_panel

    # Запуск всех контейнеров
    echo -e "${BOLD_GREEN}Запуск контейнеров...${NC}"

    # Запуск панели RemnaWave
    cd $REMNAWAVE_DIR/panel
    docker compose up -d

    # Ждем инициализации панели
    sleep 5
    if ! docker ps | grep -q "remnawave/backend"; then
        echo -e "${BOLD_RED}RemaWave контейнер не запустился.${NC}"
        echo -e "${ORANGE}Вы можете проверить логи позже с помощью 'make logs' в директории $REMNAWAVE_DIR/panel.${NC}"
    else
        echo -e "${BOLD_GREEN}Контейнеры панели RemnaWave запущены.${NC}"
    fi

    # Запуск Caddy
    cd $REMNAWAVE_DIR/caddy
    docker compose up -d

    # Ждем инициализации Caddy
    sleep 5
    if ! docker ps | grep -q "caddy-remnawave"; then
        echo -e "${BOLD_RED}Caddy контейнер не запустился. Проверьте вашу конфигурацию домена.${NC}"
        echo -e "${ORANGE}Вы можете проверить логи позже с помощью 'make logs' в директории $REMNAWAVE_DIR/caddy.${NC}"
    else
        echo -e "${BOLD_GREEN}Caddy reverse proxy успешно запущен.${NC}"
    fi

    # Запуск remnawave-json (если был выбран)
    if [ "$INSTALL_REMNAWAVE_JSON" = "y" ] || [ "$INSTALL_REMNAWAVE_JSON" = "yes" ]; then
        cd $REMNAWAVE_DIR/remnawave-json
        docker compose up -d

        # Ждем инициализации контейнера
        sleep 5
        if ! docker ps | grep -q "remnawave-json"; then
            echo -e "${BOLD_RED}Контейнер remnawave-json не запустился. Проверьте конфигурацию.${NC}"
            echo -e "${ORANGE}Вы можете проверить логи позже с помощью 'make logs' в директории $REMNAWAVE_DIR/remnawave-json.${NC}"
        else
            echo -e "${BOLD_GREEN}remnawave-json успешно запущен.${NC}"
        fi
    fi


    # Регистрация пользователя и получение токена
    ACCESS_TOKEN=$(register_panel_user $PANEL_DOMAIN $SUPERADMIN_USERNAME $SUPERADMIN_PASSWORD)

    if [ -z "$ACCESS_TOKEN" ]; then
        echo -e "${BOLD_RED}Ошибка при регистрации пользователя. Проверьте введенные данные.${NC}"
        exit 1
    else
        echo -e "${BOLD_GREEN}Пользователь успешно зарегистрирован!${NC}"
        echo -e "${BOLD_YELLOW}Токен доступа по API:${NC} $ACCESS_TOKEN"
    fi

    display_panel_installation_complete_message
}
