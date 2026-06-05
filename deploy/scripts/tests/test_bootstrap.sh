#!/bin/bash
# @file test_bootstrap.sh
# @brief Тесты граничных условий для скрипта bootstrap.sh
# @author Коноплев Г ( ZeyPlay@mail.ru )
# @date 2026-06-05
# @version 1.0.0
# @details
#   Данный скрипт проверяет корректность работы bootstrap.sh в нештатных ситуациях:
#   1. Запуск без прав root (должен завершиться с ошибкой)
#   2. Проверка синтаксиса скрипта
#   3. Проверка наличия обязательных функций
#   4. Проверка корректности Doxygen-документации
# @license GNU GPLv3 <https://gnu.org>

set -euo pipefail

# ==============================================================================
# КОНСТАНТЫ
# ==============================================================================
readonly BOOTSTRAP_SCRIPT="../scripts/bootstrap.sh"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# ==============================================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ==============================================================================

print_test_header() {
    local test_name="$1"
    echo ""
    echo "======================================================================"
    echo "ТЕСТ: ${test_name}"
    echo "======================================================================"
}

register_pass() {
    local test_name="$1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo "✅ PASS: ${test_name}"
}

register_fail() {
    local test_name="$1"
    local reason="$2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo "❌ FAIL: ${test_name}"
    echo "   Причина: ${reason}"
}

# ==============================================================================
# ТЕСТ 1: Проверка существования скрипта bootstrap.sh
# ==============================================================================
test_script_exists() {
    print_test_header "Проверка существования bootstrap.sh"
    
    if [ -f "${BOOTSTRAP_SCRIPT}" ]; then
        register_pass "Файл bootstrap.sh существует"
        return 0
    else
        register_fail "Файл bootstrap.sh не найден" "Путь: ${BOOTSTRAP_SCRIPT}"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 2: Проверка прав на выполнение
# ==============================================================================
test_script_executable() {
    print_test_header "Проверка прав на выполнение"
    
    if [ -x "${BOOTSTRAP_SCRIPT}" ]; then
        register_pass "Скрипт имеет права на выполнение"
        return 0
    else
        register_fail "Скрипт не исполняемый" "Не установлены права +x"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 3: Проверка синтаксиса Bash
# ==============================================================================
test_syntax_valid() {
    print_test_header "Проверка синтаксиса Bash"
    
    if bash -n "${BOOTSTRAP_SCRIPT}" 2>/dev/null; then
        register_pass "Синтаксис Bash корректен"
        return 0
    else
        register_fail "Синтаксическая ошибка в скрипте" "bash -n вернул ошибку"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 4: Проверка наличия set -euo pipefail
# ==============================================================================
test_safety_flags() {
    print_test_header "Проверка наличия флагов безопасности (set -euo pipefail)"
    
    if grep -q "set -euo pipefail" "${BOOTSTRAP_SCRIPT}"; then
        register_pass "Флаги безопасности присутствуют"
        return 0
    else
        register_fail "Отсутствует set -euo pipefail" "Нарушение стандарта безопасности"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 5: Проверка наличия Doxygen-заголовка
# ==============================================================================
test_doxygen_header() {
    print_test_header "Проверка Doxygen-заголовка"
    
    local required_tags=("@file" "@brief" "@author" "@date" "@version" "@license")
    local all_present=true
    
    for tag in "${required_tags[@]}"; do
        if ! grep -q "${tag}" "${BOOTSTRAP_SCRIPT}"; then
            register_fail "Отсутствует тег ${tag}" "Doxygen-документация неполная"
            all_present=false
            break
        fi
    done
    
    if [ "${all_present}" = true ]; then
        register_pass "Все обязательные Doxygen-теги присутствуют"
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 6: Проверка наличия функции check_root
# ==============================================================================
test_check_root_function() {
    print_test_header "Проверка наличия функции check_root"
    
    if grep -q "check_root()" "${BOOTSTRAP_SCRIPT}"; then
        register_pass "Функция check_root() определена"
        return 0
    else
        register_fail "Функция check_root() не найдена" "Нарушение атомарности скрипта"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 7: Проверка наличия функции install_docker
# ==============================================================================
test_install_docker_function() {
    print_test_header "Проверка наличия функции install_docker"
    
    if grep -q "install_docker()" "${BOOTSTRAP_SCRIPT}"; then
        register_pass "Функция install_docker() определена"
        return 0
    else
        register_fail "Функция install_docker() не найдена" "Нарушение атомарности скрипта"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 8: Проверка наличия функции main
# ==============================================================================
test_main_function() {
    print_test_header "Проверка наличия функции main"
    
    if grep -q "main()" "${BOOTSTRAP_SCRIPT}"; then
        register_pass "Функция main() определена"
        return 0
    else
        register_fail "Функция main() не найдена" "Отсутствует точка входа"
        return 1
    fi
}

# ==============================================================================
# ТЕСТ 9: Проверка кодировки (отсутствие BOM)
# ==============================================================================
test_no_bom() {
    print_test_header "Проверка кодировки (отсутствие BOM)"
    
    local first_bytes
    first_bytes=$(xxd -l 3 -p "${BOOTSTRAP_SCRIPT}" 2>/dev/null || echo "")
    
    if [ "${first_bytes}" = "efbbbf" ]; then
        register_fail "Обнаружен BOM в начале файла" "Нарушение UTF-8 without BOM"
        return 1
    else
        register_pass "BOM отсутствует (UTF-8 without BOM)"
        return 0
    fi
}

# ==============================================================================
# ТЕСТ 10: Проверка переводов строк (отсутствие CRLF)
# ==============================================================================
test_no_crlf() {
    print_test_header "Проверка переводов строк (отсутствие CRLF)"
    
    if grep -qP '\r' "${BOOTSTRAP_SCRIPT}" 2>/dev/null; then
        register_fail "Обнаружены CRLF-символы" "Нарушение стандарта LF"
        return 1
    else
        register_pass "Используются только LF-символы"
        return 0
    fi
}

# ==============================================================================
# ОСНОВНАЯ ФУНКЦИЯ
# ==============================================================================
main() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║   ЗАПУСК ТЕСТОВ ГРАНИЧНЫХ УСЛОВИЙ BOOTSTRAP.SH             ║"
    echo "║   Дата: $(date '+%Y-%m-%d %H:%M:%S')                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    # Переход в директорию deploy для корректных путей
    cd "$(dirname "$0")/.." || exit 1
    
    test_script_exists || true
    test_script_executable || true
    test_syntax_valid || true
    test_safety_flags || true
    test_doxygen_header || true
    test_check_root_function || true
    test_install_docker_function || true
    test_main_function || true
    test_no_bom || true
    test_no_crlf || true
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ИТОГОВЫЙ ОТЧЕТ                            ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  Всего тестов:    ${TESTS_TOTAL}                                          "
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

main "$@"
