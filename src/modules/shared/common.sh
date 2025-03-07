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

# Генерация надежного пароля
generate_secure_password() {
    local length=${1:-16}
    local chars='a-zA-Z0-9!@#$%^&*()_+{}[]|:;<>,.?/~'
    
    # Принудительно добавляем минимум один спецсимвол
    local special_chars='!@#$%^&*()_+{}[]|:;<>,.?/~'
    local special_char=$(echo "$special_chars" | fold -w1 | shuf | head -n1)
    
    if command -v openssl &> /dev/null; then
        password=$(openssl rand -base64 $((length * 3/4)) | tr -dc "$chars" | head -c $((length-1)))
    elif command -v tr &> /dev/null && command -v head &> /dev/null; then
        password=$(head -c100 /dev/urandom | tr -dc "$chars" | head -c $((length-1)))
    else
        password=$(cat /dev/urandom | tr -dc "$chars" | head -c $((length-1)))
    fi
    
    # Добавляем спецсимвол в случайную позицию
    position=$((RANDOM % length))
    password="${password:0:$position}${special_char}${password:$position}"
    
    echo "${password:0:$length}"
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
