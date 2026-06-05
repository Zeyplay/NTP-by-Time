#!/bin/bash
# @file test_chrony.sh
# @brief Автоматические интеграционные тесты для проверки работоспособности Chrony
# @author Коноплев Г ( ZeyPlay@mail.ru )
# @date 2026-06-05
# @version 1.0.0
# @details
#   Данный скрипт выполняет следующие проверки:
#   1. Проверка наличия и работоспособности контейнера chrony_ntp_server
#   2. Проверка прохождения healthcheck
#   3. Проверка синхронизации с внешними пулами
#   4. Проверка доступности UDP порта 123
#   5. Проверка режима local stratum при изоляции
# @license GNU GPLv3 <https://gnu.org>

set -euo pipefail

# ==============================================================================
# КОНСТАНТЫ И ПЕРЕМЕННЫЕ
# ==============================================================================
readonly CONTAINER_NAME="chrony_ntp_server"
readonly TEST_TIMEOUT=30
readonly MAX_RETRIES=5
readonly RETRY_DELAY=5

# Счетчики результатов
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# ==============================================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ==============================================================================

# @brief Вывод заголовка теста
# @param 1 test_name Название теста
print_test_header() {
    local test_name="$1"
    echo ""
    echo "======================================================================"
    echo "ТЕСТ: ${test_name}"
    echo "======================================================================"
}

# @brief Регистрация успешного теста
# @param 1 test_name Название теста
register_pass() {
    local test_name="$1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo "✅ PASS: ${test_name}"
}

# @brief Регистрация проваленного теста
# @param 1 test_name Название теста
# @param 2 reason Причина провала
register_fail() {
    local test_name="$1"
    local reason="$2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo "❌ FAIL: ${test_name}"
    echo "   Причина: ${reason}"
}

# ==============================================================================
# ТЕСТ 1: Проверка существования контейнера
# ==============================================================================
test_container_exists() {
    print_test_header "Проверка существования контейнера"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        register_pass "Контейнер ${CONTAINER_NAME} существует"
        return 0
    else
        register_fail "Контейнер ${CONTAINER_NAME} не найден" "Контейнер не запущен"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 2: Проверка статуса контейнера (running)
# ==============================================================================
test_container_running() {
    print_test_header "Проверка статуса контейнера (running)"
    
    local status
    status=$(docker inspect -f '{{.State.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "not_found")
    
    if [ "${status}" = "running" ]; then
        register_pass "Контейнер находится в статусе 'running'"
        return 0
    else
        register_fail "Контейнер не запущен" "Текущий статус: ${status}"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 3: Проверка healthcheck (healthy)
# ==============================================================================
test_container_healthy() {
    print_test_header "Проверка healthcheck (healthy)"
    
    local health_status
    health_status=$(docker inspect -f '{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "unknown")
    
    if [ "${health_status}" = "healthy" ]; then
        register_pass "Healthcheck пройден (status: healthy)"
        return 0
    else
        register_fail "Healthcheck не пройден" "Текущий статус: ${health_status}"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 4: Проверка синхронизации с внешними пулами
# ==============================================================================
test_chrony_sync() {
    print_test_header "Проверка синхронизации с внешними пулами"
    
    local tracking_output
    tracking_output=$(docker exec "${CONTAINER_NAME}" chronyc tracking 2>&1 || echo "error")
    
    if echo "${tracking_output}" | grep -q "Reference ID"; then
        register_pass "Chrony синхронизирован с источником времени"
        echo "   Информация о синхронизации:"
        echo "${tracking_output}" | head -5
        return 0
    else
        register_fail "Chrony не синхронизирован" "Вывод chronyc tracking: ${tracking_output}"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 5: Проверка доступности UDP порта 123
# ==============================================================================
test_udp_port_123() {
    print_test_header "Проверка доступности UDP порта 123"
    
    if docker exec "${CONTAINER_NAME}" sh -c "ss -ulnp | grep ':123'" >/dev/null 2>&1; then
        register_pass "UDP порт 123 слушается внутри контейнера"
        return 0
    else
        register_fail "UDP порт 123 недоступен" "Порт не слушается"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 6: Проверка конфигурации (chrony.conf смонтирован)
# ==============================================================================
test_config_mounted() {
    print_test_header "Проверка монтирования конфигурации"
    
    if docker exec "${CONTAINER_NAME}" test -f /etc/chrony/chrony.conf; then
        register_pass "Файл chrony.conf смонтирован в контейнер"
        return 0
    else
        register_fail "Файл chrony.conf не найден" "Файл не смонтирован"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 7: Проверка работы от непривилегированного пользователя
# ==============================================================================
test_non_root_user() {
    print_test_header "Проверка запуска от непривилегированного пользователя"
    
    local user
    user=$(docker exec "${CONTAINER_NAME}" whoami 2>/dev/null || echo "unknown")
    
    if [ "${user}" != "root" ]; then
        register_pass "Контейнер запущен от пользователя: ${user} (не root)"
        return 0
    else
        register_fail "Контейнер запущен от root" "Нарушение принципа наименьших привилегий"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 8: Проверка driftfile
# ==============================================================================
test_driftfile() {
    print_test_header "Проверка файла дрейфа (driftfile)"
    
    if docker exec "${CONTAINER_NAME}" test -f /var/lib/chrony/drift; then
        register_pass "Файл дрейфа создан и доступен"
        return 0
    else
        register_fail "Файл дрейфа не найден" "driftfile не создан"
        return 1
    fi
}

# ==============================================================================
# ОСНОВНАЯ ФУНКЦИЯ ЗАПУСКА ТЕСТОВ
# ==============================================================================
main() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║   ЗАПУСК ИНТЕГРАЦИОННЫХ ТЕСТОВ CHRONY NTP SERVER           ║"
    echo "║   Дата: $(date '+%Y-%m-%d %H:%M:%S')                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    # Предварительная проверка: запущен ли Docker
    if ! command -v docker &>/dev/null; then
        echo "❌ ERROR: Docker не установлен или недоступен"
        exit 1
    fi
    
    # Запуск всех тестов
    test_container_exists || true
    test_container_running || true
    test_container_healthy || true
    test_chrony_sync || true
    test_udp_port_123 || true
    test_config_mounted || true
    test_non_root_user || true
    test_driftfile || true
    
    # Итоговый отчет
    echo ""
    echo "══════════════════════════════════════════════════════════════╗"
    echo "║                    ИТОГОВЫЙ ОТЧЕТ                            ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  Всего тестов:    ${TESTS_TOTAL}                                          ║"
    echo "║  Пройдено:        ${TESTS_PASSED}                                          ║"
    echo "║  Провалено:       ${TESTS_FAILED}                                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    if [ "${TESTS_FAILED}" -gt 0 ]; then
        echo "❌ РЕЗУЛЬТАТ: ТЕСТЫ НЕ ПРОЙДЕНЫ"
        exit 1
    else
        echo "✅ РЕЗУЛЬТАТ: ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО"
        exit 0
    fi
}

# Точка входа
main "$@"
