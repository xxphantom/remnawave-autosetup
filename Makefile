# Основные переменные
BUILD_DIR = build
SRC_DIR = src
MODULES_DIR = $(SRC_DIR)/modules
SHELL = /bin/bash

# Имя результирующего файла
TARGET = install_remnawave.sh

# Список всех модулей в порядке включения
MODULES = $(MODULES_DIR)/shared/common.sh \
          $(MODULES_DIR)/shared/ui.sh \
          $(MODULES_DIR)/dependencies/dependencies.sh \
          $(MODULES_DIR)/remnawave_json/remnawave_json.sh \
          $(MODULES_DIR)/caddy/caddy.sh \
          $(MODULES_DIR)/panel/panel.sh \
          $(MODULES_DIR)/node/node.sh \
          $(MODULES_DIR)/selfsteal/selfsteal.sh

# Основная цель - собрать скрипт
.PHONY: all
all: clean $(BUILD_DIR) build

# Создание директории сборки
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Сборка скрипта
.PHONY: build
build: $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/$(TARGET): $(MODULES) $(SRC_DIR)/main.sh
	@echo "Сборка установщика Remnawave..."
	@echo '#!/bin/bash' > $@
	@echo '' >> $@
	@echo '# Remnawave Installer (модульная версия)' >> $@
	@echo '# Собрано: $(shell date)' >> $@
	@echo '' >> $@
	
	@# Добавляем содержимое модулей, удаляя шебанг из каждого файла
	@for module in $(MODULES); do \
		echo "# Включение модуля: $$(basename $$module)" >> $@; \
		tail -n +2 $$module >> $@; \
		echo '' >> $@; \
	done
	
	@# Добавляем главную функцию и вызов main
	@tail -n +2 $(SRC_DIR)/main.sh >> $@
	
	@# Делаем скрипт исполняемым
	@chmod +x $@
	@echo "Установщик успешно собран: $(BUILD_DIR)/$(TARGET)"

# Очистка
.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)
	@echo "Директория сборки очищена."

# Установка
.PHONY: install
install: all
	@echo "Копирование скрипта в /usr/local/bin..."
	@sudo cp $(BUILD_DIR)/$(TARGET) /usr/local/bin/$(TARGET)
	@sudo chmod +x /usr/local/bin/$(TARGET)
	@echo "Установка завершена. Запустите '$(TARGET)' для установки Remnawave."

# Тестирование
.PHONY: test
test: all
	@echo "Проверка синтаксиса скрипта..."
	@bash -n $(BUILD_DIR)/$(TARGET)
	@echo "Синтаксис скрипта корректен."

# Отладка
.PHONY: debug
debug: all
	@echo "Запуск в режиме отладки..."
	@bash -x $(BUILD_DIR)/$(TARGET)
