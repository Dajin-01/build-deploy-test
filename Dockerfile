FROM golang:1-alpine AS build
WORKDIR /src
COPY source/http-echo/ ./
ARG BUILD_REVISION=local-test
RUN go vet ./... \
    && go test ./... \
    && CGO_ENABLED=0 go build -trimpath -buildvcs=false \
       -ldflags="-X github.com/hashicorp/http-echo/version.Version=${BUILD_REVISION}" \
       -o /out/http-echo .

FROM scratch
COPY --from=build /out/http-echo /http-echo
COPY source/http-echo/LICENSE /LICENSE
USER 65532:65532
EXPOSE 5678
ENTRYPOINT ["/http-echo"]
