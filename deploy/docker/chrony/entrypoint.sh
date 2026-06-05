#!/bin/sh
# @file entrypoint.sh
# @brief Скрипт запуска Chrony с переключением на непривилегированного пользователя
# @author Коноплев Г ( ZeyPlay@mail.ru )
# @date 2026-06-05
# @version 1.0.0

set -e

# Запуск chronyd от root (нужно для capability SYS_TIME)
# Флаг -u chrony переключает на непривилегированного пользователя после инициализации
exec chronyd -d -f /etc/chrony/chrony.conf -u chrony
