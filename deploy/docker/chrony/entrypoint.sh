#!/bin/sh
# ==============================================================================
# Скрипт запуска Chrony
# @file entrypoint.sh
# @brief Инициализация и запуск chronyd
# @author Коноплев Г. (ZeyPlay@mail.ru)
# @date 2026-06-06
# @version 1.0.1
# @license GNU GPLv3 <https://gnu.org>
# ==============================================================================

set -e

# Убедимся что директории существуют и имеют правильные права
mkdir -p /run/chrony
chown chrony:chrony /run/chrony 2>/dev/null || true

# Запуск chronyd
# -d: foreground режим
# -n: не демонизировать
# -f: файл конфигурации
# -u chrony: переключиться на пользователя chrony
exec chronyd -d -n -f /etc/chrony/chrony.conf -u chrony
