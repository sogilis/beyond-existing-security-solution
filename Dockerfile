FROM golang:1.19 AS base
RUN groupadd -r bess && useradd --no-log-init -r -g bess bess
USER root
WORKDIR /home/bess
RUN chown bess:bess /home/bess
USER bess

FROM base as local
ADD ./go.mod ./go.sum ./
RUN go mod download

FROM local as build
COPY --chown=bess:bess . /home/bess
RUN mkdir -p /home/bess/.cache
RUN CGO_ENABLED=0 GOOS=linux go build -o /home/bess/bess-go

FROM build as dev
EXPOSE 8080/tcp
ENTRYPOINT ["/home/bess/bess-go"]

FROM alpine:latest as production
WORKDIR /
COPY --from=build /home/bess/bess-go /
EXPOSE 8080/tcp
ENTRYPOINT ["/bess-go"]
