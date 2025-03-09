#!/bin/bash

# Определение цветов для вывода
BOLD_BLUE=$(tput setaf 4)
BOLD_GREEN=$(tput setaf 2)
LIGHT_GREEN=$(tput setaf 10)
BOLD_BLUE_MENU=$(tput setaf 6)
ORANGE=$(tput setaf 3)
BOLD_RED=$(tput setaf 1)
BLUE=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)

# Версия скрипта
VERSION="V1.0"

# Основные директории
REMNAWAVE_DIR="$HOME/remnawave"
REMNANODE_DIR="$HOME/remnanode"
SELFSTEAL_DIR="$HOME/selfsteal"

# Отрисовка информационного блока
draw_info_box() {
    local title="$1"
    local subtitle="$2"
    
    # Фиксированная ширина блока для идеального выравнивания
    local width=54
    
    echo -e "${BOLD_GREEN}"
    # Верхняя граница
    printf "┌%s┐\n" "$(printf '─%.0s' $(seq 1 $width))"
    
    # Центрирование заголовка
    local title_padding_left=$(( (width - ${#title}) / 2 ))
    local title_padding_right=$(( width - title_padding_left - ${#title} ))
    printf "│%*s%s%*s│\n" "$title_padding_left" "" "$title" "$title_padding_right" ""
    
    # Центрирование подзаголовка
    local subtitle_padding_left=$(( (width - ${#subtitle}) / 2 ))
    local subtitle_padding_right=$(( width - subtitle_padding_left - ${#subtitle} ))
    printf "│%*s%s%*s│\n" "$subtitle_padding_left" "" "$subtitle" "$subtitle_padding_right" ""
    
    # Пустая строка
    printf "│%*s│\n" "$width" ""
    
    # Строка версии - аккуратная обработка цветов
    local version_text="  • Версия: "
    local version_value="$VERSION (Бета)"
    local version_value_colored="${ORANGE}${version_value}${BOLD_GREEN}"
    local version_value_length=${#version_value}
    local remaining_space=$(( width - ${#version_text} - version_value_length ))
    printf "│%s%s%*s│\n" "$version_text" "$version_value_colored" "$remaining_space" ""
    
    # Пустая строка
    printf "│%*s│\n" "$width" ""
    
    # Нижняя граница
    printf "└%s┘\n" "$(printf '─%.0s' $(seq 1 $width))"
    echo -e "${NC}"
}

generate_secure_password() {
    local length="${1:-16}"
    # Пул символов: буквы, цифры и только перечисленные спецсимволы
    local chars='a-zA-Z0-9!$%^&*_+.,'
    local password=""

    # Проверяем, есть ли openssl
    if command -v openssl &>/dev/null; then
        password="$(openssl rand -base64 48 \
            | tr -dc "$chars" \
            | head -c "$length")"
    else
        # Если openssl недоступен, fallback на /dev/urandom
        password="$(head -c 100 /dev/urandom \
            | tr -dc "$chars" \
            | head -c "$length")"
    fi

    # Проверка наличия символов каждого типа
    local special_chars='!$%^&*_+.,'
    local uppercase_chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local lowercase_chars='abcdefghijklmnopqrstuvwxyz'
    local number_chars='0123456789'
    
    # Если нет специального символа, добавляем его
    if ! [[ "$password" =~ [$special_chars] ]]; then
        local position=$((RANDOM % length))
        local one_special="$(echo "$special_chars" | fold -w1 | shuf | head -n1)"
        # Заменяем символ в случайной позиции
        password="${password:0:$position}${one_special}${password:$((position+1))}"
    fi
    
    # Если нет символа верхнего регистра, добавляем его
    if ! [[ "$password" =~ [$uppercase_chars] ]]; then
        local position=$((RANDOM % length))
        local one_uppercase="$(echo "$uppercase_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_uppercase}${password:$((position+1))}"
    fi
    
    # Если нет символа нижнего регистра, добавляем его
    if ! [[ "$password" =~ [$lowercase_chars] ]]; then
        local position=$((RANDOM % length))
        local one_lowercase="$(echo "$lowercase_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_lowercase}${password:$((position+1))}"
    fi
    
    # Если нет цифры, добавляем её
    if ! [[ "$password" =~ [$number_chars] ]]; then
        local position=$((RANDOM % length))
        local one_number="$(echo "$number_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_number}${password:$((position+1))}"
    fi

    echo "$password"
}

# Создание общего Makefile для управления сервисами
create_makefile() {
    local directory="$1"
    cat > "$directory/Makefile" << 'EOF'
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
}

register_user() {
    local panel_url="$1"
    local panel_domain="$2"
    local username="$3"
    local password="$4"
    local api_url="http://${panel_url}/api/auth/register"
    
    local response=$(curl -s "$api_url" \
    -H "Host: $panel_domain" \
    -H "X-Forwarded-For: $panel_url" \
    -H "X-Forwarded-Proto: https" \
    -H "Content-Type: application/json" \
    --data-raw '{"username":"'"$username"'","password":"'"$password"'"}')
    
	if [ -z "$response" ]; then
		echo "Ошибка при регистрации - пустой ответ сервера"
        return 1
	fi

    if [[ "$response" == *"accessToken"* ]]; then
    	local token=$(echo "$response" | jq -r '.response.accessToken')
        
        echo "$token"
        return 0
    else
        echo "$response"
        return 1
    fi
}
