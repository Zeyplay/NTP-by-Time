#  Инструкция по развертыванию

> **Автор**: Коноплев Г  
> **Дата**: 2026-06-05  
> **Версия**: 1.0.0

---

## 1. Предварительные требования

### 1.1 Системные требования

- **ОС**: Ubuntu 24.04 LTS / Debian 12 (LTS-версии)
- **Docker**: 24.0+
- **Docker Compose**: Plugin v2
- **Права**: sudo для выполнения bootstrap.sh

### 1.2 Проверка окружения

```bash
# Проверка версии Docker
docker --version

# Проверка версии Docker Compose
docker compose version

# Проверка наличия git
git --version
