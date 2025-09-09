FROM crystallang/crystal:1.16 AS builder

ARG APP_ENV=production
ENV KEMAL_ENV=${APP_ENV}

WORKDIR /build

COPY shard.yml shard.lock ./
RUN echo "KEMAL_ENV=${APP_ENV}" >> .env && \
    shards install --frozen --production

COPY . .
RUN shards build --production --release --no-debug --static --progress

FROM debian:buster-slim AS production

ARG APP_ENV=production
ARG PORT=7001
ENV KEMAL_ENV=${APP_ENV}
ENV PORT=${PORT}

WORKDIR /app

STOPSIGNAL SIGQUIT

COPY --from=builder /build/bin/mpngin .

RUN useradd -m app-user && \
    chown -R app-user /home/app-user && \
    echo "PORT=${PORT}" >> .env && \
    echo "KEMAL_ENV=${KEMAL_ENV}" >> .env && \
    chown -R app-user /app;

USER app-user

EXPOSE ${PORT}

ENTRYPOINT ["./mpngin"]
CMD ["./mpngin"]
