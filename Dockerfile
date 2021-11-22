FROM crystallang/crystal:1.2.2 AS builder

WORKDIR /app

COPY . .

ARG APP_ENV=production

RUN shards install --production && \
    echo "KEMAL_ENV=${APP_ENV}" >> .env && \
    KEMAL_ENV=${APP_ENV} crystal build --release src/mpngin.cr;

FROM debian:stable-slim

ARG PORT=7001
ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

EXPOSE ${PORT}

WORKDIR /app

COPY --from=builder /app/mpngin .
COPY --from=builder /app/.env .

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y libssl1.1 libevent-2.1-7 && \
    apt-get auto-remove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    useradd -m app-user && \
    chown -R app-user /home/app-user && \
    echo "PORT=${PORT}" >> .env && \
    chown -R app-user .;

USER app-user

STOPSIGNAL SIGQUIT

ENTRYPOINT [ "./mpngin" ]
CMD [ "./mpngin" ]