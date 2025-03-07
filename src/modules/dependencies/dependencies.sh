#!/bin/bash

# Установка общих зависимостей для всех компонентов

install_dependencies() {
    echo -e "${GREEN}Проверка зависимостей...${NC}"

    # Проверка и установка утилиты make
    check_and_install_make() {
        if ! command -v make &>/dev/null; then
            echo -e "${GREEN}Установка утилиты make...${NC}"
            sudo apt update >/dev/null 2>&1
            sudo apt install -y make >/dev/null 2>&1
            if ! command -v make &>/dev/null; then
                echo -e "${BOLD_RED}Ошибка: Не удалось установить make. Пожалуйста, установите его вручную.${NC}"
                return 1
            fi
            echo -e "${GREEN}Утилита make успешно установлена.${NC}"
        fi
        return 0
    }

    check_and_install_make || {
        echo -e "${BOLD_RED}Ошибка: Для настройки сайта заглушки требуется утилита make. Пожалуйста, установите его вручную.${NC}"
        sleep 2
        return 1
    }

    # Проверка, установлен ли Docker
    if command -v docker &>/dev/null && docker --version &>/dev/null; then
        echo -e "${GREEN}Docker уже установлен. Пропускаем установку Docker.${NC}"
    else
        echo ""
        echo -e "${GREEN}Установка Docker и других необходимых пакетов...${NC}"

        sudo apt update -y >/dev/null 2>&1
        # Установка предварительных зависимостей
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common make >/dev/null 2>&1

        # Создание директории для хранения ключей
        sudo mkdir -p /etc/apt/keyrings

        # Добавление официального GPG-ключа Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null || {
            # Если не удалось, пробуем удалить файл и добавить ключ снова
            sudo rm -f /etc/apt/keyrings/docker.gpg
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
        }

        # Настройка прав доступа к ключу
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Определение кодового имени дистрибутива
        CODENAME=$(lsb_release -cs)

        # Добавление репозитория Docker
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

        # Обновление списка пакетов
        sudo apt update -y >/dev/null 2>&1

        # Установка Docker Engine и Docker Compose plugin
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1

        # Добавление текущего пользователя в группу docker (чтобы использовать Docker без sudo)
        sudo usermod -aG docker $USER

        # Проверка успешности установки
        if command -v docker &>/dev/null; then
            echo -e "${GREEN}Docker успешно установлен$(docker --version)${NC}"
        else
            echo -e "${RED}Ошибка установки Docker${NC}"
            exit 1
        fi
    fi
}
