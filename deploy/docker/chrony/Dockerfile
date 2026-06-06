FROM alpine:3.20

RUN apk add --no-cache chrony tzdata

# Создание директорий с правильными правами
RUN mkdir -p /var/lib/chrony /run/chrony /var/log/chrony && \
    chown -R chrony:chrony /var/lib/chrony /run/chrony /var/log/chrony && \
    chmod 755 /var/lib/chrony /run/chrony /var/log/chrony

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /etc/chrony

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
