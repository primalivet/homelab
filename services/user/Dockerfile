FROM docker.io/golang:1.24.2-alpine3.21 AS base

RUN apk --no-cache add ca-certificates

WORKDIR /app
COPY go.mod ./
COPY go.sum* ./
RUN go mod download
RUN go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.29.0
RUN go install github.com/air-verse/air@latest

FROM base AS build
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o service -a -ldflags '-extldflags "-static"' ./cmd/api/main.go

FROM base AS development
WORKDIR /app
EXPOSE 8080
ENV PORT=8080
# Files should be available on /app via volume mount
CMD ["air", "-c", ".air.toml"]

FROM alpine:3.21 AS production
WORKDIR /app
EXPOSE 8080
ENV PORT=8080
COPY --from=build /app/service .
CMD ["./service"]
