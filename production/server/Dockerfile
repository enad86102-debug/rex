# syntax=docker/dockerfile:1
FROM golang:1.27.2-bookworm@sha256:5cf287a799e6b94384bad13d16b14904c531f51ba65792237e122ce42b392f61 AS build
WORKDIR /src
COPY go.mod ./
COPY cmd ./cmd
COPY internal ./internal
# Standard library only. No dependency fetch and no session CA baked in layers.
RUN CGO_ENABLED=0 GOPROXY=off go build -trimpath -ldflags="-s -w" -o /out/rexd ./cmd/rexd

FROM scratch
COPY --from=build /out/rexd /rexd
USER 65532:65532
ENV REX_LISTEN=0.0.0.0:8080 REX_STORE=/data/state.json
EXPOSE 8080
ENTRYPOINT ["/rexd"]
