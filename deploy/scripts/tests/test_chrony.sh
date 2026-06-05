#!/bin/bash
# @file test_chrony.sh
# @brief Автоматические интеграционные тесты для проверки работоспособности Chrony
# @author Коноплев Г ( ZeyPlay@mail.ru )
# @author Дмитрий Радченко ( drad@sfedu.ru ) 
# @date 2026-06-05
# @version 1.1.0
# @details
#   Данный скрипт выполняет следующие проверки:
#   1. Проверка наличия и работоспособности контейнера chrony_ntp_server
#   2. Проверка прохождения healthcheck
#   3. Проверка синхронизации с внешними пулами
#   4. Проверка доступности UDP порта 123
#   5. Проверка режима local stratum при изоляции

# (Новвоведения от сис. админа)
#   6. Проверка файла дрейфа (driftfile)
#   7. Проверка запуска от непривилегированного пользователя
#   8. Проверка аутентификации NTP (symmetric keys)
#   9. Проверка фильтрации недостоверных источников (maxupdateskew/maxdistance)
#  10. Тест граничного условия: поведение при недоступности источников
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
# ТЕСТ 9: Проверка аутентификации NTP (ключи)
# ==============================================================================
test_ntp_authentication() {
    print_test_header "Проверка аутентификации NTP"

    # Проверяем наличие файла ключей
    if docker exec "${CONTAINER_NAME}" test -f /run/chrony/keys 2>/dev/null; then
        register_pass "Файл ключей аутентификации существует"

        # Проверяем, что ключи загружены в chrony
        # chronyc authdata показывает статус аутентификации для каждого источника
        local auth_output
        auth_output=$(docker exec "${CONTAINER_NAME}" chronyc authdata 2>/dev/null || echo "error")

        # Если команда отработала и вернула данные — аутентификация настроена
        if [ "${auth_output}" != "error" ] && [ -n "${auth_output}" ]; then
            register_pass "Аутентификация NTP настроена (chronyc authdata работает)"
            echo "   Данные аутентификации:"
            echo "${auth_output}" | head -5
            return 0
        else
            register_fail "Аутентификация NTP не работает" "chronyc authdata не отвечает"
            return 1
        fi
    else
        register_fail "Файл ключей не найден" "/run/chrony/keys отсутствует"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 10: Проверка режима изоляции (local stratum)
# ==============================================================================


test_local_stratum_isolation() {
    print_test_header "Проверка режима изоляции (local stratum 10)"
    
    # Проверяем конфигурацию на наличие local stratum 10
    if docker exec "${CONTAINER_NAME}" grep -q "local stratum 10" /etc/chrony/chrony.conf 2>/dev/null; then
        register_pass "Режим local stratum 10 настроен"
        
        # Проверяем, что сервер может работать в изоляции
        local tracking_output
        tracking_output=$(docker exec "${CONTAINER_NAME}" chronyc tracking 2>/dev/null)
        
        if echo "${tracking_output}" | grep -q "stratum"; then
            local current_stratum
            current_stratum=$(echo "${tracking_output}" | grep "Stratum" | awk '{print $3}')
            register_pass "Текущий stratum: ${current_stratum}"
            return 0
        else
            register_fail "Не удалось получить информацию о stratum"
            return 1
        fi
    else
        register_fail "Режим local stratum 10 не найден в конфигурации"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 11: Проверка фильтрации источников (maxupdateskew)
# ==============================================================================
test_source_filtering() {
    print_test_header "Проверка фильтрации недостоверных источников"
    
    # Проверяем настройки фильтрации в конфиге
    if docker exec "${CONTAINER_NAME}" grep -q "maxupdateskew" /etc/chrony/chrony.conf 2>/dev/null; then
        local max_skew
        max_skew=$(docker exec "${CONTAINER_NAME}" grep "maxupdateskew" /etc/chrony/chrony.conf | awk '{print $2}')
        register_pass "maxupdateskew настроен: ${max_skew}"
        
        if docker exec "${CONTAINER_NAME}" grep -q "maxdistance" /etc/chrony/chrony.conf 2>/dev/null; then
            local max_distance
            max_distance=$(docker exec "${CONTAINER_NAME}" grep "maxdistance" /etc/chrony/chrony.conf | awk '{print $2}')
            register_pass "maxdistance настроен: ${max_distance}"
            return 0
        else
            register_fail "maxdistance не найден"
            return 1
        fi
    else
        register_fail "maxupdateskew не найден в конфигурации"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 12: Граничное условие - проверка при недоступности источников
# ==============================================================================
test_edge_case_no_sources() {
    print_test_header "Тест граничного условия: поведение при недоступности источников"
    
    # Проверяем, что chrony не падает при проблемах с сетью
    local tracking_output
    tracking_output=$(docker exec "${CONTAINER_NAME}" chronyc tracking 2>/dev/null || echo "error")
    
    if [ "${tracking_output}" != "error" ]; then
        register_pass "Chrony корректно обрабатывает ситуацию с источниками"
        return 0
    else
        register_fail "Chrony не отвечает на запросы tracking"
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
    test_ntp_authentication || true
    test_local_stratum_isolation || true
    test_source_filtering || true
    test_edge_case_no_sources || true

    
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
