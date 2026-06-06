# ==============================================================================
# Dockerfile для Chrony NTP-сервера
# @file Dockerfile
# @brief Оптимизированный образ Chrony с минимальной поверхностью атаки
# @author Коноплев Г. (ZeyPlay@mail.ru)
# @date 2026-06-06
# @version 1.0.0
# @license GNU GPLv3 <https://gnu.org>
# ==============================================================================

# Базовый образ (конкретная версия, не latest!)
FROM alpine:3.20

# Метаданные
LABEL maintainer="ZeyPlay@mail.ru"
LABEL description="Optimized Chrony NTP server"
LABEL version="1.0.0"

# Установка chrony одним слоем с очисткой кэша
RUN apk add --no-cache chrony tzdata

# Создание директории для driftfile с правильными правами
RUN mkdir -p /var/lib/chrony && \
    chown -R chrony:chrony /var/lib/chrony && \
    chmod 755 /var/lib/chrony

# Создание директории для ключей
RUN mkdir -p /run/chrony && \
    chown -R chrony:chrony /run/chrony

# Копирование entrypoint скрипта
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Рабочая директория
WORKDIR /etc/chrony

# Точка входа
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
