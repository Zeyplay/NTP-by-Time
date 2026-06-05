# 🕐 NTP-by-Time: Инфраструктура синхронизации времени

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

> Курсовой проект по курсу "Администрирование ОС Linux"

## 👥 Автор

**Коноплев Г**  
Email: ZeyPlay@mail.ru

## 📋 Содержание

- [Описание](#описание)
- [Быстрый старт](#быстрый-старт)
- [Структура](#структура)

---

## 📝 Описание

NTP-сервер на базе Chrony для синхронизации времени в локальной инфраструктуре.

## 🚀 Быстрый старт

\`\`\`bash
cd deploy
docker compose up -d --build
docker compose ps
\`\`\`

## 📁 Структура

\`\`\`
NTP-by-Time/
├── config/chrony/
├── deploy/
│   ├── docker/chrony/Dockerfile
│   ├── scripts/bootstrap.sh
│   └── docker-compose.yml
└── README.md
\`\`\`

## 📄 Лицензия

GNU GPLv3
