FROM golang:1.24.2-alpine3.21 AS build

WORKDIR /app

COPY go.mod ./

COPY go.sum* ./

RUN go mod download

COPY main.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o helloworld -a -ldflags '-extldflags "-static"' .

FROM alpine:3.21

RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY --from=build /app/helloworld .

EXPOSE 8080

ENV PORT=8080

CMD ["./helloworld"]
