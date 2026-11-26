FROM alpine:3.24

RUN apk add --no-cache chrony

CMD ["chronyd", "-d", "-f", "/etc/chrony/chrony.conf"]
