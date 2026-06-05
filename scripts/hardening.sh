#!/bin/bash
# ==============================================================================
# @file hardening.sh
# @brief Скрипт настройки межсетевого экрана (UFW) для защиты NTP-сервера.
# @author Участник 3
# @date 2026-06-06
# @details Реализует принцип "запрещено всё, что не разрешено явно".
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Ошибка: Пожалуйста, запустите скрипт от имени root (используйте sudo)"
  exit 1
fi

echo ">>> Начало настройки безопасности (Hardening)..."

if ! command -v ufw &> /dev/null; then
    echo "Установка UFW..."
    apt-get update -qq && apt-get install -y -qq ufw
fi

echo ">>> Сброс правил UFW..."
ufw --force reset

echo ">>> Установка политик по умолчанию..."
ufw default deny incoming
ufw default allow outgoing

echo ">>> Разрешение NTP трафика (UDP 123)..."
ufw allow 123/udp comment "NTP synchronization"

echo ">>> Разрешение SSH (порт 22)..."
ufw allow 22/tcp comment "SSH access"

echo ">>> Включение UFW..."
ufw --force enable

echo ">>> Настройка безопасности завершена!"
ufw status verbose
