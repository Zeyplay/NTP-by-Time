#!/bin/bash
# @file bootstrap.sh
# @brief Скрипт первичной подготовки чистой ОС Linux перед развертыванием инфраструктуры Chrony.
# @author ZeyPlay ( zeyplay@university.com )
# @date 2026-06-05
# @version 1.0.0
# @details
#   Данный сценарий автоматизирует выполнение следующих этапов:
#   1. Валидация прав суперпользователя (root).
#   2. Обновление системных пакетов.
#   3. Установка Docker и Docker Compose Plugin.
#   4. Добавление текущего пользователя в группу docker.
# @license GNU GPLv3 <https://gnu.org>

set -euo pipefail

# @brief Проверка наличия прав root.
# @return 0 Если пользователь root, 1 в противном случае.
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Скрипт должен быть запущен от имени root (используйте sudo)." >&2
        return 1
    fi
    return 0
}

# @brief Установка Docker и необходимых зависимостей для Debian/Ubuntu.
# @param 1 os_type Тип операционной системы.
install_docker() {
    local os_type="$1"
    echo "LOG: Инициализация установки Docker для ${os_type}..."
    
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    echo "LOG: Docker успешно установлен."
}

# @brief Основная точка входа скрипта.
main() {
    check_root
    install_docker "ubuntu"
    
    # Добавление пользователя в группу docker (если запущено не в CI)
    if [ -n "${SUDO_USER:-}" ]; then
        usermod -aG docker "$SUDO_USER"
        echo "LOG: Пользователь $SUDO_USER добавлен в группу docker. Требуется перелогиниться."
    fi
    
    echo "SUCCESS: Хост успешно подготовлен."
}

main "$@"
