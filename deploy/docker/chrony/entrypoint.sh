#!/bin/sh
# ==============================================================================
# Скрипт запуска Chrony
# @file entrypoint.sh
# @brief Инициализация и запуск chronyd с переключением на непривилегированного пользователя
# @author Коноплев Г. (ZeyPlay@mail.ru)
# @date 2026-06-06
# @version 1.0.0
# @license GNU GPLv3 <https://gnu.org>
# ==============================================================================

set -e

# Запуск chronyd в foreground режиме
# -d: debug mode (foreground)
# -n: не переходить в background
# -f: файл конфигурации
# -u chrony: переключиться на пользователя chrony после инициализации
exec chronyd -d -n -f /etc/chrony/chrony.conf -u chrony
