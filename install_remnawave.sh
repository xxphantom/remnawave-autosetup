#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Ошибка: Этот скрипт должен быть запущен от имени root (sudo)"
    exit 1
fi

clear

BOLD_BLUE=$(tput setaf 4)
BOLD_GREEN=$(tput setaf 2)
LIGHT_GREEN=$(tput setaf 10)
BOLD_BLUE_MENU=$(tput setaf 6)
ORANGE=$(tput setaf 3)
BOLD_RED=$(tput setaf 1)
PURPLE=$(tput setaf 5)
BLUE=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)

check_internet() {
    echo -ne "${BOLD_BLUE_MENU}Проверка подключения к интернету... ${NC}"
    if ping -c 1 google.com &>/dev/null; then
        echo -e "${BOLD_GREEN}Подключено${NC}"
        return 0
    else
        echo -e "${BOLD_RED}Не подключено${NC}"
        return 1
    fi
}

check_and_install_make() {
    if ! command -v make &> /dev/null; then
        echo -e "${GREEN}Установка утилиты make...${NC}"
        sudo apt update > /dev/null 2>&1
        sudo apt install -y make > /dev/null 2>&1
        if ! command -v make &> /dev/null; then
            echo -e "${BOLD_RED}Ошибка: Не удалось установить make. Пожалуйста, установите его вручную.${NC}"
            return 1
        fi
        echo -e "${GREEN}Утилита make успешно установлена.${NC}"
    fi
    return 0
}

draw_info_box() {
    local title="$1"
    local subtitle="$2"
    
    # Fixed width box with perfect alignment
    local width=54
    
    echo -e "${BOLD_GREEN}"
    # Top border
    printf "┌%s┐\n" "$(printf '─%.0s' $(seq 1 $width))"
    
    # Center title
    local title_padding_left=$(( (width - ${#title}) / 2 ))
    local title_padding_right=$(( width - title_padding_left - ${#title} ))
    printf "│%*s%s%*s│\n" "$title_padding_left" "" "$title" "$title_padding_right" ""
    
    # Center subtitle
    local subtitle_padding_left=$(( (width - ${#subtitle}) / 2 ))
    local subtitle_padding_right=$(( width - subtitle_padding_left - ${#subtitle} ))
    printf "│%*s%s%*s│\n" "$subtitle_padding_left" "" "$subtitle" "$subtitle_padding_right" ""
    
    # Empty line
    printf "│%*s│\n" "$width" ""
    
    # Version line - carefully handle colors
    local version_text="  • Версия: "
    local version_value="V0.2 (Бета)"
    local version_value_colored="${ORANGE}${version_value}${BOLD_GREEN}"
    local version_value_length=${#version_value}
    local remaining_space=$(( width - ${#version_text} - version_value_length ))
    printf "│%s%s%*s│\n" "$version_text" "$version_value_colored" "$remaining_space" ""
    
    # Empty line
    printf "│%*s│\n" "$width" ""
    
    # Bottom border
    printf "└%s┘\n" "$(printf '─%.0s' $(seq 1 $width))"
    echo -e "${NC}"
}

animate_text() {
    local text="$1"
    local speed="${2:-0.01}"
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep $speed
    done
    echo ""
}

exiting_animation() {
    echo -e "Готово."
}

show_installing_animation() {
    local pid=$!
    local messages=(
        "${ORANGE}Установка необходимых пакетов.${NC}"
        "${ORANGE}Установка необходимых пакетов..${NC}"
        "${ORANGE}Установка необходимых пакетов...${NC}"
    )
    local i=0
    while kill -0 $pid 2>/dev/null; do
        echo -ne "\r${messages[$i]}"
        i=$(( (i+1) % 3 ))
        sleep 0.5
    done
    echo -ne "\r\033[K"
}

show_setup_animation() {
    local pid=$!
    local messages=(
        "${BLUE}Скрипт выполняет необходимые задачи.${NC}"
        "${BLUE}Скрипт выполняет необходимые задачи..${NC}"
        "${BLUE}Скрипт выполняет необходимые задачи...${NC}"
    )
    local i=0
    while kill -0 $pid 2>/dev/null; do
        echo -ne "\r${messages[$i]}"
        i=$(( (i+1) % 3 ))
        sleep 0.5
    done
    echo -ne "\r\033[K"
}

validate_numeric_port() {
    local port="$1"
    if [[ "$port" =~ ^[0-9]+$ && "$port" -ge 1 && "$port" -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}

install_dependencies() {
    (
        sudo apt update -y > /dev/null 2>&1
        
        # Check if Docker is already installed
        if command -v docker &> /dev/null && docker --version &> /dev/null; then
            echo ""
            echo -e "${GREEN}Docker уже установлен. Пропускаем установку Docker.${NC}"
        else
            echo ""
            echo -e "${GREEN}Установка Docker и других необходимых пакетов...${NC}"

            # Установка предварительных зависимостей
            sudo apt install -y apt-transport-https ca-certificates curl software-properties-common make > /dev/null 2>&1

            # Создание директории для хранения ключей
            sudo mkdir -p /etc/apt/keyrings

            # Добавление официального GPG-ключа Docker
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null || {
                # If the above fails, try removing the file first and then adding the key
                sudo rm -f /etc/apt/keyrings/docker.gpg
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
            }

            # Настройка прав доступа к ключу
            sudo chmod a+r /etc/apt/keyrings/docker.gpg

            # Определение кодового имени дистрибутива
            CODENAME=$(lsb_release -cs)

            # Добавление репозитория Docker
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # Обновление списка пакетов
            sudo apt update -y > /dev/null 2>&1

            # Установка Docker Engine и Docker Compose plugin
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin > /dev/null 2>&1

            # Добавление текущего пользователя в группу docker (чтобы использовать Docker без sudo)
            sudo usermod -aG docker $USER

            # Проверка успешности установки
            if command -v docker &> /dev/null; then
                echo -e "${GREEN}Docker успешно установлен$(docker --version)${NC}"
            else
                echo -e "${RED}Ошибка установки Docker${NC}"
                exit 1
            fi
        fi
        
        # Verify docker is working
        docker --version > /dev/null 2>&1
    ) & show_installing_animation
    
    wait $!
    
    echo -e "${GREEN}Пакеты успешно установлены.${NC}"
    sleep 2
}

install_panel() {
    clear
    
    check_internet || {
        echo -e "${BOLD_RED}Ошибка: Для установки требуется подключение к интернету.${NC}"
        sleep 2
        return 1
    }
    
    check_and_install_make || {
        echo -e "${BOLD_RED}Ошибка: Для установки требуется утилита make. Пожалуйста, установите его вручную.${NC}"
        sleep 2
        return 1
    }
    
    # Установка общих зависимостей
    install_dependencies
    
    # Создаем базовую директорию для всего проекта
    mkdir -p ~/remnawave && cd ~/remnawave
    
    # Создаем директорию для панели
    mkdir -p panel && mkdir -p caddy
    
    # Переходим в директорию панели
    cd panel
    
    # Генерация JWT секретов с помощью openssl вместо Python
    JWT_AUTH_SECRET=$(openssl rand -hex 32 | tr -d '\n')
    JWT_API_TOKENS_SECRET=$(openssl rand -hex 32 | tr -d '\n')
    
    (
        curl -s -o .env https://raw.githubusercontent.com/remnawave/backend/refs/heads/main/.env.sample
    ) & show_setup_animation
    
    # Ask if Telegram integration should be enabled
    echo -ne "${GREEN}Хотите включить интеграцию с Telegram? (y/n): ${NC}"
    read IS_TELEGRAM_ENABLED
    IS_TELEGRAM_ENABLED=$(echo "$IS_TELEGRAM_ENABLED" | tr '[:upper:]' '[:lower:]')
    echo
    
    # Convert y/n to true/false for the .env file
    if [ "$IS_TELEGRAM_ENABLED" = "y" ] || [ "$IS_TELEGRAM_ENABLED" = "yes" ]; then
        IS_TELEGRAM_ENV_VALUE="true"
        echo -e "${BOLD_GREEN}Включение интеграции с Telegram...${NC}"
        # If Telegram integration is enabled, prompt for Telegram parameters
        while true; do
            echo -ne "${ORANGE}Введите токен вашего Telegram бота: ${NC}"
            read TELEGRAM_BOT_TOKEN
            echo
            if validate_telegram_token "$TELEGRAM_BOT_TOKEN"; then
                break
            else
                echo -e "${BOLD_RED}Ошибка: Неверный формат токена Telegram бота. Он должен выглядеть как '123456789:ABCdef...'.${NC}"
            fi
        done
        
        while true; do
            echo -ne "${ORANGE}Введите ID администратора Telegram: ${NC}"
            read TELEGRAM_ADMIN_ID
            echo
            if validate_numeric_id "$TELEGRAM_ADMIN_ID"; then
                break
            else
                echo -e "${BOLD_RED}Ошибка: ID администратора должен быть числовым значением.${NC}"
            fi
        done
        
        while true; do
            echo -ne "${ORANGE}Введите ID чата для уведомлений: ${NC}"
            read NODES_NOTIFY_CHAT_ID
            echo
            if validate_numeric_id "$NODES_NOTIFY_CHAT_ID"; then
                break
            else
                echo -e "${BOLD_RED}Ошибка: ID чата должен быть числовым значением.${NC}"
            fi
        done
    else
        # If Telegram integration is not enabled, set parameters to "change-me"
        IS_TELEGRAM_ENV_VALUE="false"
        echo -e "${BOLD_YELLOW}Пропуск интеграции с Telegram.${NC}"
        TELEGRAM_BOT_TOKEN="change-me"
        TELEGRAM_ADMIN_ID="change-me"
        NODES_NOTIFY_CHAT_ID="change-me"
    fi
    
    echo -ne "${PURPLE}Введите домен для поддержки (для отображения в клиентском приложении) (например, support.example.com): ${NC}"
    read SUB_SUPPORT_DOMAIN
    echo
    
    echo -ne "${PURPLE}Введите домен для веб-страницы (для отображения в клиентском приложении) (например, webpage.example.com): ${NC}"
    read SUB_WEBPAGE_DOMAIN
    echo
    
    # Запрашиваем основной домен для панели и домен для подписок
    echo -ne "${PURPLE}Введите основной домен для вашей панели (например, panel.example.com): ${NC}"
    read SCRIPT_PANEL_DOMAIN
    echo
    
    echo -ne "${PURPLE}Введите домен для подписок (например, subs.example.com): ${NC}"
    read SCRIPT_SUB_DOMAIN
    echo
    
    # Запрос на установку remnawave-json
    echo -ne "${GREEN}Установить remnawave-json https://github.com/Jolymmiles/remnawave-json ? (y/n): ${NC}"
    read INSTALL_REMNAWAVE_JSON
    INSTALL_REMNAWAVE_JSON=$(echo "$INSTALL_REMNAWAVE_JSON" | tr '[:upper:]' '[:lower:]')
    echo
    
    echo -e "${BOLD_RED}\033[1m┌────────────────────────────────────────────┐\033[0m${NC}"
    echo -e "${BOLD_RED}\033[1m│     Используете только сложный пароль!     │\033[0m${NC}"
    echo -e "${BOLD_RED}\033[1m└────────────────────────────────────────────┘\033[0m${NC}"
    echo
    
    echo -ne "${ORANGE}Пожалуйста, введите имя пользователя SuperAdmin: ${NC}"
    read SUPERADMIN_USERNAME
    echo
    
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
    
    (
        sed -i "s|JWT_AUTH_SECRET=change_me|JWT_AUTH_SECRET=$JWT_AUTH_SECRET|" .env
        sed -i "s|JWT_API_TOKENS_SECRET=change_me|JWT_API_TOKENS_SECRET=$JWT_API_TOKENS_SECRET|" .env
        sed -i "s|IS_TELEGRAM_ENABLED=false|IS_TELEGRAM_ENABLED=$IS_TELEGRAM_ENV_VALUE|" .env
        sed -i "s|TELEGRAM_BOT_TOKEN=change_me|TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN|" .env
        sed -i "s|TELEGRAM_ADMIN_ID=change_me|TELEGRAM_ADMIN_ID=$TELEGRAM_ADMIN_ID|" .env
        sed -i "s|NODES_NOTIFY_CHAT_ID=change_me|NODES_NOTIFY_CHAT_ID=$NODES_NOTIFY_CHAT_ID|" .env
        sed -i "s|SUB_SUPPORT_URL=https://support.example.com|SUB_SUPPORT_URL=https://$SUB_SUPPORT_DOMAIN|" .env
        sed -i "s|SUB_WEBPAGE_URL=https://example.com|SUB_WEBPAGE_URL=https://$SUB_WEBPAGE_DOMAIN|" .env
        sed -i "s|SUB_PUBLIC_DOMAIN=example.com|SUB_PUBLIC_DOMAIN=$SCRIPT_SUB_DOMAIN|" .env
        sed -i "s|SUPERADMIN_USERNAME=change_me|SUPERADMIN_USERNAME=$SUPERADMIN_USERNAME|" .env
        sed -i "s|SUPERADMIN_PASSWORD=change_me|SUPERADMIN_PASSWORD=$SUPERADMIN_PASSWORD|" .env
    ) & show_setup_animation
    
    echo -e "${GREEN}Файл .env успешно настроен.${NC}"
    sleep 3
    
    # Создание docker-compose.yml для панели
    cat > docker-compose.yml << 'EOF'
services:
    remnawave-db:
        image: postgres:17
        container_name: 'remnawave-db'
        hostname: remnawave-db
        restart: always
        env_file:
            - .env
        environment:
            - POSTGRES_USER=${POSTGRES_USER}
            - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
            - POSTGRES_DB=${POSTGRES_DB}
            - TZ=UTC
        ports:
            - '127.0.0.1:6767:5432'
        volumes:
            - remnawave-db-data:/var/lib/postgresql/data
        networks:
            - remnawave-network
        healthcheck:
            test: ['CMD-SHELL', 'pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}']
            interval: 3s
            timeout: 10s
            retries: 3

    remnawave:
        image: remnawave/backend:latest
        container_name: 'remnawave'
        hostname: remnawave
        restart: always
        ports:
            - '127.0.0.1:3000:3000'
        env_file:
            - .env
        networks:
            - remnawave-network

networks:
    remnawave-network:
        name: remnawave-network
        driver: bridge
        external: false

volumes:
    remnawave-db-data:
        driver: local
        external: false
        name: remnawave-db-data
EOF

    # Создание Makefile для панели
    cat > Makefile << 'EOF'
.PHONY: start stop restart logs

start:
	docker compose up -d && docker compose logs -f -t
stop:
	docker compose down
restart:
	docker compose down && docker compose up -d
logs:
	docker compose logs -f -t
EOF
    
    # Установка remnawave-json, если пользователь согласился
    if [ "$INSTALL_REMNAWAVE_JSON" = "y" ] || [ "$INSTALL_REMNAWAVE_JSON" = "yes" ]; then
        echo -e "${BOLD_GREEN}Установка remnawave-json...${NC}"
        
        # Создаем директорию для remnawave-json
        mkdir -p ~/remnawave/remnawave-json/templates/v2ray
        mkdir -p ~/remnawave/remnawave-json/templates/mux
        mkdir -p ~/remnawave/remnawave-json/templates/subscription
        
        # Скачиваем шаблоны
        curl -s -o ~/remnawave/remnawave-json/templates/v2ray/default.json https://raw.githubusercontent.com/Jolymmiles/remnawave-json/refs/heads/main/templates/v2ray/default.json
        curl -s -o ~/remnawave/remnawave-json/templates/mux/default.json https://raw.githubusercontent.com/Jolymmiles/remnawave-json/refs/heads/main/templates/mux/default.json
        curl -s -o ~/remnawave/remnawave-json/templates/subscription/index.html https://raw.githubusercontent.com/Jolymmiles/remnawave-json/refs/heads/main/templates/subscription/index.html
        
        cd ~/remnawave/remnawave-json
        
        # Устанавливаем APP_PORT по умолчанию
        APP_PORT=4000
        APP_HOST="localhost"
        REMNAWAVE_URL="https://$SCRIPT_PANEL_DOMAIN"
        
        # Информация о шаблонах
        echo -e ""
        echo -e "${ORANGE}Все шаблоны будут доступны по следующим путям на хост-системе:${NC}"
        echo -e "${ORANGE}- Шаблон V2Ray: ~/remnawave/remnawave-json/templates/v2ray/default.json${NC}"
        echo -e "${ORANGE}- Шаблон V2Ray Mux: ~/remnawave/remnawave-json/templates/mux/default.json${NC}"
        echo -e "${ORANGE}- Шаблон страницы подписки: ~/remnawave/remnawave-json/templates/subscription/index.html${NC}"
        echo -e ""
        echo -e "${ORANGE}Если вы захотите изменить шаблоны в будущем:${NC}"
        echo -e ""
        echo -e "${ORANGE}1. Перейдите в директорию ~/remnawave/remnawave-json и выполните: make stop${NC}"
        echo -e "${ORANGE}2. Измените нужные файлы шаблонов по указанным выше путям${NC}"
        echo -e "${ORANGE}3. Запустите сервисы снова: make start${NC}"
        echo -e ""
        
        # Устанавливаем стандартные пути к шаблонам
        V2RAY_TEMPLATE_HOST_PATH="~/remnawave/remnawave-json/templates/v2ray/default.json"
        V2RAY_TEMPLATE_PATH_LINE="V2RAY_TEMPLATE_PATH=/app/templates/v2ray/default.json"
        
        # V2RAY_MUX_ENABLED
        echo -ne "${ORANGE}V2RAY_MUX_ENABLED - флаг для включения или отключения функции V2Ray Mux.${NC}\\n"
        echo -ne "${ORANGE}Включить функцию V2Ray Mux? (y/n, по умолчанию y): ${NC}"
        read ENABLE_V2RAY_MUX
        if [ "$ENABLE_V2RAY_MUX" = "n" ] || [ "$ENABLE_V2RAY_MUX" = "N" ]; then
            V2RAY_MUX_ENABLED_LINE="V2RAY_MUX_ENABLED=false"
        else
            V2RAY_MUX_ENABLED_LINE="V2RAY_MUX_ENABLED=true"
        fi
        
        V2RAY_MUX_TEMPLATE_HOST_PATH="~/remnawave/remnawave-json/templates/mux/default.json"
        V2RAY_MUX_TEMPLATE_PATH_LINE="V2RAY_MUX_TEMPLATE_PATH=/app/templates/v2ray/mux_default.json"
        
        WEB_PAGE_TEMPLATE_HOST_PATH="~/remnawave/remnawave-json/templates/subscription/index.html"
        WEB_PAGE_TEMPLATE_PATH_LINE="WEB_PAGE_TEMPLATE_PATH=/app/templates/subscription/index.html"
        
        # HAPP_ANNOUNCEMENTS
        echo -ne "${ORANGE}HAPP_ANNOUNCEMENTS - текст объявления.${NC}\\n"
        echo -e "${ORANGE}По умолчанию: pupa${NC}"
        echo -ne "${ORANGE}Хотите указать текст объявления? (y/n, по умолчанию n): ${NC}"
        read ADD_HAPP_ANNOUNCEMENTS
        if [ "$ADD_HAPP_ANNOUNCEMENTS" = "y" ] || [ "$ADD_HAPP_ANNOUNCEMENTS" = "Y" ]; then
            echo -ne "${ORANGE}Введите текст объявления: ${NC}"
            read HAPP_ANNOUNCEMENTS
            HAPP_ANNOUNCEMENTS_LINE="HAPP_ANNOUNCEMENTS=$HAPP_ANNOUNCEMENTS"
        else
            HAPP_ANNOUNCEMENTS_LINE="HAPP_ANNOUNCEMENTS=pupa"
        fi
        
        # Создание .env файла
        cat > .env << EOF
REMNAWAVE_URL=$REMNAWAVE_URL
APP_PORT=$APP_PORT
APP_HOST=$APP_HOST
$V2RAY_TEMPLATE_PATH_LINE
$V2RAY_MUX_ENABLED_LINE
$V2RAY_MUX_TEMPLATE_PATH_LINE
$WEB_PAGE_TEMPLATE_PATH_LINE
$HAPP_ANNOUNCEMENTS_LINE
EOF
        
        # Создание docker-compose.yml для remnawave-json
        cat > docker-compose.yml << EOF
services:
  remnawave-json:
    image: ghcr.io/jolymmiles/remnawave-json:latest
    network_mode: host
    env_file:
      - .env
    volumes:
      - $V2RAY_TEMPLATE_HOST_PATH:/app/templates/v2ray/default.json
      - $V2RAY_MUX_TEMPLATE_HOST_PATH:/app/templates/v2ray/mux_default.json
      - $WEB_PAGE_TEMPLATE_HOST_PATH:/app/templates/subscription/index.html
EOF
        
        # Создание Makefile для remnawave-json
        cat > Makefile << 'EOF'
.PHONY: start stop restart logs

start:
	docker compose up -d && docker compose logs -f -t
stop:
	docker compose down
restart:
	docker compose down && docker compose up -d
logs:
	docker compose logs -f -t
EOF

        echo -e "${BOLD_GREEN}Конфигурация remnawave-json завершена.${NC}"
    fi
    
    # Настройка Caddy
    cd ~/remnawave/caddy
    
    # Определение SUB_BACKEND_URL в зависимости от установки remnawave-json
    if [ "$INSTALL_REMNAWAVE_JSON" = "y" ] || [ "$INSTALL_REMNAWAVE_JSON" = "yes" ]; then
        SCRIPT_SUB_BACKEND_URL="127.0.0.1:$APP_PORT"
        REWRITE_RULE=""
    else
        SCRIPT_SUB_BACKEND_URL="127.0.0.1:3000"
        REWRITE_RULE="rewrite * /api/sub{uri}"
    fi
    
    # Создание .env файла для Caddy
    cat > .env << EOF
PANEL_DOMAIN=$SCRIPT_PANEL_DOMAIN
PANEL_PORT=443
SUB_DOMAIN=$SCRIPT_SUB_DOMAIN
SUB_PORT=443
BACKEND_URL=127.0.0.1:3000
SUB_BACKEND_URL=$SCRIPT_SUB_BACKEND_URL
EOF
    
    PANEL_DOMAIN='$PANEL_DOMAIN'
    PANEL_PORT='$PANEL_PORT'
    BACKEND_URL='$BACKEND_URL'

    SUB_DOMAIN='$SUB_DOMAIN'
    SUB_PORT='$SUB_PORT'
    SUB_BACKEND_URL='$SUB_BACKEND_URL'

    # Создание Caddyfile
    cat > Caddyfile << EOF
{$PANEL_DOMAIN}:{$PANEL_PORT} {
    reverse_proxy {$BACKEND_URL} {
        header_up X-Real-IP {remote}
        header_up Host {host}
    }
}

{$SUB_DOMAIN}:{$SUB_PORT} {
    handle {
        $REWRITE_RULE
        reverse_proxy {$SUB_BACKEND_URL} {
            header_up X-Real-IP {remote}
            header_up Host {host}

            @error status 400 404 422 500

            handle_response @error {
                error "" 404
            }
        }
    }
}
EOF
    
    # Создание docker-compose.yml для Caddy
    cat > docker-compose.yml << 'EOF'
services:
  caddy:
    image: caddy:2.9.1
    container_name: caddy-remnawave
    restart: unless-stopped
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./logs:/var/log/caddy
      - caddy_data_panel:/data
      - caddy_config_panel:/config
    env_file:
      - .env
    network_mode: "host"
volumes:
  caddy_data_panel:
  caddy_config_panel:
EOF
    
    # Создание Makefile для Caddy
    cat > Makefile << 'EOF'
.PHONY: start stop restart logs

start:
	docker compose up -d && docker compose logs -f -t
stop:
	docker compose down
restart:
	docker compose down && docker compose up -d
logs:
	docker compose logs -f -t
EOF
    
    # Создание директории для логов
    mkdir -p logs
    
    # Запуск всех контейнеров
    echo -e "${BOLD_GREEN}Запуск контейнеров...${NC}"
    
    # Запуск панели RemnaWave
    cd ~/remnawave/panel
    docker compose up -d
    
    # Ждем инициализации панели
    sleep 5
    echo -e "${BOLD_GREEN}Контейнеры панели RemnaWave запущены.${NC}"
    
    # Запуск Caddy
    cd ~/remnawave/caddy
    docker compose up -d
    
    # Ждем инициализации Caddy
    sleep 5
    if ! docker ps | grep -q "caddy-remnawave"; then
        echo -e "${BOLD_RED}Caddy контейнер не запустился. Проверьте вашу конфигурацию домена.${NC}"
        echo -e "${ORANGE}Вы можете проверить логи позже с помощью 'make logs' в директории ~/remnawave/caddy.${NC}"
    else
        echo -e "${BOLD_GREEN}Caddy reverse proxy успешно запущен.${NC}"
    fi
    
    # Запуск remnawave-json (если был выбран)
    if [ "$INSTALL_REMNAWAVE_JSON" = "y" ] || [ "$INSTALL_REMNAWAVE_JSON" = "yes" ]; then
        cd ~/remnawave/remnawave-json
        docker compose up -d
        
        # Ждем инициализации контейнера
        sleep 5
        if ! docker ps | grep -q "remnawave-json"; then
            echo -e "${BOLD_RED}Контейнер remnawave-json не запустился. Проверьте конфигурацию.${NC}"
            echo -e "${ORANGE}Вы можете проверить логи позже с помощью 'make logs' в директории ~/remnawave/remnawave-json.${NC}"
        else
            echo -e "${BOLD_GREEN}remnawave-json успешно запущен.${NC}"
        fi
    fi
    
    echo -e "${GREEN}Панель Remnawave успешно установлена и настроена с Caddy${NC}"
    echo
    echo -e "\033[1m┌──────────────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1m│     Ваш домен для панели:                            │\033[0m"
    
    # Calculate padding for PANEL_DOMAIN
    local panel_domain_text="https://$SCRIPT_PANEL_DOMAIN"
    local panel_padding_right=$((54 - 2 - ${#panel_domain_text}))
    echo -e "\033[1m│ $panel_domain_text$(printf '%*s' $panel_padding_right) │\033[0m"
    
    echo -e "\033[1m│                                                      │\033[0m"
    echo -e "\033[1m│ Ваш домен для подписок:                              │\033[0m"
    
    # Calculate padding for SUB_DOMAIN
    local sub_domain_text="https://$SCRIPT_SUB_DOMAIN"
    local sub_padding_right=$((54 - 2 - ${#sub_domain_text}))
    echo -e "\033[1m│ $sub_domain_text$(printf '%*s' $sub_padding_right) │\033[0m"
    
    echo -e "\033[1m└──────────────────────────────────────────────────────┘\033[0m"
    echo
    echo -e "${BOLD_BLUE}Директория панели: ${NC}~/remnawave/panel"
    echo -e "${BOLD_BLUE}Директория Caddy: ${NC}~/remnawave/caddy"
    echo
    echo -e "${BOLD_GREEN}Вы можете управлять обеими службами с помощью команды 'make' в соответствующих директориях:${NC}"
    echo -e "  ${ORANGE}make start   ${NC}- Запуск службы и просмотр логов"
    echo -e "  ${ORANGE}make stop    ${NC}- Остановка службы"
    echo -e "  ${ORANGE}make restart ${NC}- Перезапуск службы"
    echo -e "  ${ORANGE}make logs    ${NC}- Просмотр логов"
    echo
    
    cd ~
    draw_info_box "Панель Remnawave" "Расширенная настройка v0.2"
    
    echo -e "${BOLD_GREEN}Установка завершена. Нажмите Enter, чтобы продолжить...${NC}"
    read -r
}

setup_node() {
    clear
    
    check_internet || {
        echo -e "${BOLD_RED}Ошибка: Для настройки ноды требуется подключение к интернету.${NC}"
        sleep 2
        return 1
    }
    
    check_and_install_make || {
        echo -e "${BOLD_RED}Ошибка: Для настройки ноды требуется утилита make. Пожалуйста, установите его вручную.${NC}"
        sleep 2
        return 1
    }
    
    # Установка общих зависимостей
    install_dependencies
    
    mkdir -p ~/remnanode && cd ~/remnanode
    curl -sS https://raw.githubusercontent.com/remnawave/node/refs/heads/main/docker-compose-prod.yml > docker-compose.yml
    
    # Создание Makefile для ноды
    cat > Makefile << 'EOF'
.PHONY: start stop restart logs

start:
	docker compose up -d && docker compose logs -f -t
stop:
	docker compose down
restart:
	docker compose down && docker compose up -d
logs:
	docker compose logs -f -t
EOF
    
    while true; do
        echo -ne "${ORANGE}Введите порт для вашей ноды (предпочтительно между 50000-60000): ${NC}"
        read NODE_PORT
        echo
        
        if [ -z "$NODE_PORT" ]; then
            echo -e "${BOLD_RED}Ошибка: Порт не может быть пустым. Пожалуйста, введите допустимое число.${NC}"
        elif validate_numeric_port "$NODE_PORT"; then
            break
        else
            echo -e "${BOLD_RED}Ошибка: Пожалуйста, введите допустимый номер порта (1-65535).${NC}"
        fi
    done
    
    echo -e "${ORANGE}Введите сертификат сервера (вставьте содержимое и 2 раза нажмите Enter): ${NC}"
    CERTIFICATE=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            if [ -n "$CERTIFICATE" ]; then
                break
            else
                echo -e "${BOLD_RED}Ошибка: Сертификат не может быть пустым. Пожалуйста, введите содержимое сертификата.${NC}"
            fi
        else
            CERTIFICATE="$CERTIFICATE$line\n"
        fi
    done
    
    while true; do
        echo -ne "${BOLD_RED}Вы уверены, что сертификат правильный? (y/n): ${NC}"
        read confirm
        echo
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            break
        elif [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
            echo -e "${ORANGE}Введите сертификат сервера (вставьте содержимое и нажмите Enter на пустой строке для завершения): ${NC}"
            CERTIFICATE=""
            while IFS= read -r line; do
                if [ -z "$line" ]; then
                    if [ -n "$CERTIFICATE" ]; then
                        break
                    else
                        echo -e "${BOLD_RED}Ошибка: Сертификат не может быть пустым. Пожалуйста, введите содержимое сертификата.${NC}"
                    fi
                else
                    CERTIFICATE="$CERTIFICATE$line\n"
                fi
            done
        else
            echo -e "${BOLD_RED}Пожалуйста, введите 'y' или 'n'.${NC}"
        fi
    done
    
    (
        echo -e "### APP ###\nAPP_PORT=$NODE_PORT\n$CERTIFICATE" > .env
    ) & show_setup_animation
    
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
        echo -e "${LIGHT_GREEN}• Директория ноды: ${BOLD_GREEN}~/remnanode${NC}"
        echo -e "\n${LIGHT_GREEN}Для управления нодой используйте следующие команды:${NC}"
        echo -e "${ORANGE}   cd ~/remnanode${NC}"
        echo -e "${ORANGE}   make start   ${NC}- Запуск ноды и просмотр логов"
        echo -e "${ORANGE}   make stop    ${NC}- Остановка ноды"
        echo -e "${ORANGE}   make restart ${NC}- Перезапуск ноды"
        echo -e "${ORANGE}   make logs    ${NC}- Просмотр логов ноды"
    else
        echo -e "${BOLD_RED}⚠ Нода Remnawave была установлена, но не запущена автоматически.${NC}"
        echo -e "${LIGHT_RED}Для запуска ноды вручную выполните:${NC}"
        echo -e "${ORANGE}   cd ~/remnawave${NC}"
        echo -e "${ORANGE}   make start${NC}"
        echo -e "\n${LIGHT_RED}Если ошибка сохраняется, проверьте логи:${NC}"
        echo -e "${ORANGE}   make logs${NC}"
    fi
    
    unset NODE_PORT
    
    echo -e "\n${BOLD_GREEN}Нажмите Enter, чтобы вернуться в главное меню...${NC}"
    read -r
}

setup_selfsteal() {
    clear
    
    check_internet || {
        echo -e "${BOLD_RED}Ошибка: Для настройки сайта заглушки требуется подключение к интернету.${NC}"
        sleep 2
        return 1
    }
    
    check_and_install_make || {
        echo -e "${BOLD_RED}Ошибка: Для настройки сайта заглушки требуется утилита make. Пожалуйста, установите его вручную.${NC}"
        sleep 2
        return 1
    }
    
    # Установка общих зависимостей
    install_dependencies
    
    mkdir -p ~/selfsteal/html && cd ~/selfsteal
    
    # Запрос информации о домене и порте
    while true; do
        echo -ne "${ORANGE}Введите домен для сайта-заглушки (совпадает с XRAY конфигом - realitySettings.serverNames): ${NC}"
        read SELF_STEAL_DOMAIN
        echo
        
        if [ -z "$SELF_STEAL_DOMAIN" ]; then
            echo -e "${BOLD_RED}Ошибка: Домен не может быть пустым. Пожалуйста, введите имя домена.${NC}"
        else
            break
        fi
    done
    
    while true; do
        echo -ne "${ORANGE}Введите порт для сайта-заглушки (совпадает с XRAY конфигом - realitySettings.dest): ${NC}"
        read SELF_STEAL_PORT
        echo
        
        if [ -z "$SELF_STEAL_PORT" ]; then
            echo -e "${BOLD_RED}Ошибка: Порт не может быть пустым. Пожалуйста, введите номер порта.${NC}"
        elif validate_numeric_port "$SELF_STEAL_PORT"; then
            break
        else
            echo -e "${BOLD_RED}Ошибка: Пожалуйста, введите допустимый номер порта (1-65535).${NC}"
        fi
    done
    
    # Создаем .env файл
    cat > .env << EOF
# Домены
SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
SELF_STEAL_PORT=$SELF_STEAL_PORT
EOF
    
    # Создаем Caddyfile
    cat > Caddyfile << 'EOF'
{
    https_port {$SELF_STEAL_PORT}
    default_bind 127.0.0.1
    servers {
        listener_wrappers {
            proxy_protocol {
                allow 127.0.0.1/32
            }
            tls
        }
    }
    auto_https disable_redirects
}

http://{$SELF_STEAL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$SELF_STEAL_DOMAIN}{uri} permanent
}

https://{$SELF_STEAL_DOMAIN} {
    root * /var/www/html
    try_files {path} /index.html
    file_server
}

:{$SELF_STEAL_PORT} {
    tls internal
    respond 204
}

:80 {
    bind 0.0.0.0
    respond 204
}
EOF
    
    # Создаем docker-compose.yml
    cat > docker-compose.yml << EOF
services:
  caddy:
    image: caddy:2.9.1
    container_name: caddy-remnawave
    restart: unless-stopped
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./html:/var/www/html
      - ./logs:/var/log/caddy
      - caddy_data_selfsteal:/data
      - caddy_config_selfsteal:/config
    env_file:
      - .env
    network_mode: "host"

volumes:
  caddy_data_selfsteal:
  caddy_config_selfsteal:
EOF
    
    # Создание Makefile для управления
    cat > Makefile << 'EOF'
.PHONY: start stop restart logs

start:
	docker compose up -d && docker compose logs -f -t
stop:
	docker compose down
restart:
	docker compose down && docker compose up -d
logs:
	docker compose logs -f -t
EOF
    
    # Создание директорий и скачивание файлов с GitHub
    echo -e "${GREEN}Скачивание файлов для сайта-заглушки...${NC}"
    
    mkdir -p ./html/assets
    
    # Скачивание index.html
    curl -s -o ./html/index.html https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/index.html
    
    # Скачивание файлов assets
    curl -s -o ./html/assets/index-BilmB03J.css https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/index-BilmB03J.css
    curl -s -o ./html/assets/index-CRT2NuFx.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/index-CRT2NuFx.js
    curl -s -o ./html/assets/index-legacy-D44yECni.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/index-legacy-D44yECni.js
    curl -s -o ./html/assets/polyfills-legacy-B97CwC2N.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/polyfills-legacy-B97CwC2N.js
    curl -s -o ./html/assets/vendor-DHVSyNSs.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/vendor-DHVSyNSs.js
    curl -s -o ./html/assets/vendor-legacy-Cq-AagHX.js https://raw.githubusercontent.com/xxphantom/caddy-for-remnawave/refs/heads/main/html/assets/vendor-legacy-Cq-AagHX.js
    
    # Запуск сервиса
    (
        mkdir -p logs
        docker compose up -d
    ) & show_setup_animation
    
    wait $!
    
    # Проверяем, запущен ли сервис
    CADDY_STATUS=$(docker compose ps --services --filter "status=running" | grep -q "caddy" && echo "running" || echo "stopped")
    
    draw_info_box "Сайт-заглушка" "Установка Caddy завершена"
    
    if [ "$CADDY_STATUS" = "running" ]; then
        echo -e "${BOLD_GREEN}✓ Caddy для сайта-заглушки успешно установлен и запущен!${NC}"
        echo -e "${LIGHT_GREEN}• Домен: ${BOLD_GREEN}$SELF_STEAL_DOMAIN${NC}"
        echo -e "${LIGHT_GREEN}• Порт: ${BOLD_GREEN}$SELF_STEAL_PORT${NC}"
        echo -e "${LIGHT_GREEN}• Директория: ${BOLD_GREEN}~/selfsteal${NC}"
        echo -e "\n${LIGHT_GREEN}Для управления сервисом используйте следующие команды:${NC}"
        echo -e "${ORANGE}   cd ~/selfsteal${NC}"
        echo -e "${ORANGE}   make start   ${NC}- Запуск сервиса и просмотр логов"
        echo -e "${ORANGE}   make stop    ${NC}- Остановка сервиса"
        echo -e "${ORANGE}   make restart ${NC}- Перезапуск сервиса"
        echo -e "${ORANGE}   make logs    ${NC}- Просмотр логов сервиса"
    else
        echo -e "${BOLD_RED}⚠ Caddy для сайта-заглушки был установлен, но не запущен автоматически.${NC}"
        echo -e "${LIGHT_RED}Для запуска сервиса вручную выполните:${NC}"
        echo -e "${ORANGE}   cd ~/selfsteal${NC}"
        echo -e "${ORANGE}   make start${NC}"
        echo -e "\n${LIGHT_RED}Если ошибка сохраняется, проверьте логи:${NC}"
        echo -e "${ORANGE}   make logs${NC}"
    fi
    
    unset SELF_STEAL_DOMAIN
    unset SELF_STEAL_PORT
    
    echo -e "\n${BOLD_GREEN}Нажмите Enter, чтобы вернуться в главное меню...${NC}"
    read -r
}

main() {
    draw_info_box "Панель Remnawave" "Расширенная настройка v0.2"
    
    while true; do
        echo ""
        echo -e " ${BOLD_GREEN}1) Установка панели Remnawave с Caddy${NC}"
        echo ""
        echo -e " ${LIGHT_GREEN}2) Установка ноды Remnawave${NC}"
        echo ""
        echo -e " ${BLUE}3) Настройка сайта-заглушки Steal oneself с Caddy${NC}"
        echo ""
        echo -e " ${BOLD_RED}4) Выход${NC}"
        
        echo -e "\n${BOLD_BLUE}───────────────────────────────────────────────${NC}"
        echo -en "${BOLD_RED}Пожалуйста, введите ваш выбор [1-4]: ${NC}"
        read choice
        
        case $choice in
            1)
                install_panel
                ;;
            2)
                setup_node
                ;;
            3)
                setup_selfsteal
                ;;
            4)
                exiting_animation
                break
                ;;
            *)
                clear
                draw_info_box "Панель Remnawave" "Расширенная настройка v0.2"
                echo -e "${BOLD_RED}Неверный выбор, пожалуйста, попробуйте снова.${NC}"
                sleep 1
                ;;
        esac
    done
}

validate_telegram_token() {
    local token="$1"
    if [[ "$token" =~ ^[0-9]{8,10}:[A-Za-z0-9_-]{35}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_numeric_id() {
    local id="$1"
    if [[ "$id" =~ ^[0-9]+$ || "$id" =~ ^-[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

main
