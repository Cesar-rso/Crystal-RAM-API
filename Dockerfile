FROM crystallang/crystal:1.8-alpine
ENV KEMAL_ENV "development"

WORKDIR /travels_app
COPY . .
RUN apk add sqlite
RUN apk add sqlite-dev
RUN shards install
RUN make sam db:create
RUN make sam db:setup

EXPOSE 3000

CMD ["crystal", "run", "app.cr"]
