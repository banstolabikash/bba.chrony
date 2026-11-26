
FROM alpine:3.24

RUN apk add --no-cache chrony \
    && mkdir -p /var/lib/chrony /var/log/chrony

STOPSIGNAL SIGTERM

CMD ["chronyd", "-d", "-f", "/etc/chrony/chrony.conf"]
