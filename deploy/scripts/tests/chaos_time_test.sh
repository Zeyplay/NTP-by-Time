#!/bin/bash
# @file chaos_time_test.sh
# @brief Скрипт для проверки восстановления синхронизации времени (Chaos Engineering).
# @description
#   1. Намеренно сбивает время в контейнере.
#   2. Запускает форсированную синхронизацию.
#   3. Замеряет время восстановления.
# @author Дмитрий Радченко
# @date 2026-06-06
# @version 1.0.0
# @license GNU GPLv3

set -euo pipefail

CONTAINER_NAME="ntp-by-time_chrony_1"
TIME_OFFSET=3600

echo "=== CHAOS ENGINEERING TEST FOR CHRONY ==="

# Проверка Docker
if ! command -v docker &> /dev/null; then
    echo "Ошибка: Docker не найден!"
    exit 1
fi

# Проверка контейнера
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Ошибка: Контейнер '${CONTAINER_NAME}' не найден!"
    exit 1
fi

echo "Контейнер найден: ${CONTAINER_NAME}"

# Функция получения статуса синхронизации
get_sync_status() {
    docker exec "$CONTAINER_NAME" chronyc tracking 2>/dev/null | grep "Leap status" | awk '{print $4}'
}

# 1. Сбиваем время
echo "Этап 1: Сбиваем время на ${TIME_OFFSET} секунд..."

CURRENT_TIME=$(docker exec "$CONTAINER_NAME" date +%s)
NEW_TIME=$((CURRENT_TIME + TIME_OFFSET))

if docker exec "$CONTAINER_NAME" date -s "@$NEW_TIME" 2>/dev/null; then
    echo "Время успешно сдвинуто."
else
    echo "Ошибка: Не удалось изменить время. Возможно, не хватает прав CAP_SYS_TIME."
    exit 1
fi

# 2. Запускаем синхронизацию
echo "Этап 2: Запускаем форсированную синхронизацию (makestep)..."
START_TIME=$(date +%s)
docker exec "$CONTAINER_NAME" chronyc makestep 2>/dev/null || true

# 3. Ждем восстановления
echo "Этап 3: Ожидаем восстановления синхронизации..."

TIMEOUT=60
ELAPSED=0
INTERVAL=5

while [ $ELAPSED -lt $TIMEOUT ]; do
    STATUS=$(get_sync_status)
    
    if [ "$STATUS" = "Normal" ]; then
        END_TIME=$(date +%s)
        RECOVERY_TIME=$((END_TIME - START_TIME))
        
        echo "=== РЕЗУЛЬТАТЫ ==="
        echo "Начальное смещение: ${TIME_OFFSET} секунд"
        echo "Время восстановления: ${RECOVERY_TIME} секунд"
        echo "Тест пройден успешно!"
        exit 0
    fi
    
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
    echo "Прошло ${ELAPSED} секунд. Статус: ${STATUS}"
done

echo "Ошибка: Таймаут. Синхронизация не восстановлена за ${TIMEOUT} секунд."
exit 1
