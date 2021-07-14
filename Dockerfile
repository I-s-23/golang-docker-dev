FROM golang:latest as dev

ENV APP_HOME /workspace
# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
ENV LESSCHARSET=utf-8
# TimeZone
ENV TZ Asia/Tokyo

ENV CGO_ENABLED 0
WORKDIR ${APP_HOME}

RUN apt-get update && apt-get install git
COPY go.mod go.sum ./
RUN go mod download
EXPOSE 8080

CMD ["go", "run", "server.go"]


FROM golang:1.15.7-alpine as builder

ENV ROOT=/go/src/app
WORKDIR ${ROOT}

RUN apk update && apk add git && apk --no-cache add ca-certificates
COPY go.mod go.sum config.yml ./
RUN go mod download

COPY . ${ROOT}
RUN CGO_ENABLED=0 GOOS=linux go build -o $ROOT/binary


FROM scratch as prod

ENV ROOT=/go/src/app
WORKDIR ${ROOT}
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder ${ROOT}/config.yml ${ROOT}
COPY --from=builder ${ROOT}/binary ${ROOT}

EXPOSE 8080
CMD ["/go/src/app/binary"]
