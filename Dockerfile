FROM golang:1.22-alpine

WORKDIR /app
COPY .  /app

USER john

RUN go mod download
RUN go build -o main .

CMD ["./main"]
